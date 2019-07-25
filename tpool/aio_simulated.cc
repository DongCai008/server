/* Copyright(C) 2019 MariaDB Corporation.

This program is free software; you can redistribute itand /or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 - 1301 USA*/

#ifndef _WIN32
#include <unistd.h> /* pread(), pwrite() */
#endif
#include "tpool.h"
#include "tpool_structs.h"
#include <stdlib.h>
#include <string.h>

namespace tpool
{
#ifdef _WIN32

/*
  In order to be able to execute synchronous IO even on file opened
  with FILE_FLAG_OVERLAPPED, and to bypass  to completion port, 
  we use valid event handle for the hEvent member of the OVERLAPPED structure, 
  with its low-order bit set.

  �See MSDN docs for GetQueuedCompletionStatus() for description of this trick.
*/
struct sync_io_event
{
  HANDLE m_event;
  sync_io_event()
  {
    m_event= CreateEvent(0, FALSE, FALSE, 0);
    m_event= (HANDLE)(((uintptr_t) m_event) | 1);
  }
  ~sync_io_event()
  {
    m_event= (HANDLE)(((uintptr_t) m_event) & ~1);
    CloseHandle(m_event);
  }
};
static thread_local sync_io_event sync_event;

static int pread(const native_file_handle &h, void *buf, size_t count,
                 unsigned long long offset)
{
  OVERLAPPED ov{};
  ULARGE_INTEGER uli;
  uli.QuadPart= offset;
  ov.Offset= uli.LowPart;
  ov.OffsetHigh= uli.HighPart;
  ov.hEvent= sync_event.m_event;

  if (ReadFile(h, buf, (DWORD) count, 0, &ov) ||
      (GetLastError() == ERROR_IO_PENDING))
  {
    DWORD n_bytes;
    if (GetOverlappedResult(h, &ov, &n_bytes, TRUE))
      return n_bytes;
  }

  return -1;
}

static int pwrite(const native_file_handle &h, void *buf, size_t count,
                  unsigned long long offset)
{
  OVERLAPPED ov{};
  ULARGE_INTEGER uli;
  uli.QuadPart= offset;
  ov.Offset= uli.LowPart;
  ov.OffsetHigh= uli.HighPart;
  ov.hEvent= sync_event.m_event;

  if (WriteFile(h, buf, (DWORD) count, 0, &ov) ||
      (GetLastError() == ERROR_IO_PENDING))
  {
    DWORD n_bytes;
    if (GetOverlappedResult(h, &ov, &n_bytes, TRUE))
      return n_bytes;
  }
  return -1;
}
#endif

/**
  Simulated AIO.

  Executes IO synchronously in worker pool
  and then calls the completion routine.
*/
class simulated_aio : public aio
{
  thread_pool *m_pool;
  cache<aiocb> m_cache;

public:
  simulated_aio(thread_pool *tp, int max_io_size)
      : m_pool(tp), m_cache(max_io_size, NOTIFY_ONE)
  {
  }

  static void simulated_aio_callback(void *param)
  {
    aiocb *cb= (aiocb *) param;
    int ret_len;
    int err= 0;
    switch (cb->m_opcode)
    {
    case AIO_PREAD:
      ret_len= pread(cb->m_fh, cb->m_buffer, cb->m_len, cb->m_offset);
      break;
    case AIO_PWRITE:
      ret_len= pwrite(cb->m_fh, cb->m_buffer, cb->m_len, cb->m_offset);
      break;
    default:
      abort();
    }
    if (ret_len < 0)
    {
#ifdef _WIN32
      err= GetLastError();
#else
      err= errno;
#endif
    }

    cb->m_callback(cb, ret_len, err);
    ((simulated_aio *) cb->m_internal)->m_cache.put(cb);
  }

  virtual int submit_aio(const aiocb *aiocb) override
  {
    auto cb= m_cache.get();
    *cb= *aiocb;
    cb->m_internal= this;
    m_pool->submit_task({simulated_aio_callback, cb});
    return 0;
  }
  virtual int bind(native_file_handle &fd) override { return 0; }
  virtual int unbind(const native_file_handle &fd) override { return 0; }
};

aio *create_simulated_aio(thread_pool *tp, int max_aio)
{
  return new simulated_aio(tp, max_aio);
}

} // namespace tpool