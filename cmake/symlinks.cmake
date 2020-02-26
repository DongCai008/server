# Create lists
if(COMMAND REGISTER_SYMLINK)
  return()
endif()

macro(REGISTER_SYMLINK from to)
  list(APPEND MARIADB_SYMLINK_FROMS ${from})
  list(APPEND MARIADB_SYMLINK_TOS ${to})
endmacro()

# MariaDB names for executables
REGISTER_SYMLINK("mariadb" "mysql")
REGISTER_SYMLINK("mariadb-access" "mysqlaccess")
REGISTER_SYMLINK("mariadb-admin" "mysqladmin")
REGISTER_SYMLINK("mariadb-backup" "mariabackup")
REGISTER_SYMLINK("mariadb-binlog" "mysqlbinlog")
REGISTER_SYMLINK("mariadb-check" "mysqlcheck")
REGISTER_SYMLINK("mariadb-client-test-embedded" "mysql_client_test_embedded")
REGISTER_SYMLINK("mariadb-client-test" "mysql_client_test")
REGISTER_SYMLINK("mariadb-config" "mariadb_config")
REGISTER_SYMLINK("mariadb-convert-table-format" "mysql_convert_table_format")
REGISTER_SYMLINK("mariadb-dump" "mysqldump")
REGISTER_SYMLINK("mariadb-dumpslow" "mysqldumpslow")
REGISTER_SYMLINK("mariadb-embedded" "mysql_embedded")
REGISTER_SYMLINK("mariadb-find-rows" "mysql_find_rows")
REGISTER_SYMLINK("mariadb-fix-extensions" "mysql_fix_extensions")
REGISTER_SYMLINK("mariadb-hotcopy" "mysqlhotcopy")
REGISTER_SYMLINK("mariadb-import" "mysqlimport")
REGISTER_SYMLINK("mariadb-install-db" "mysql_install_db")
REGISTER_SYMLINK("mariadb-ldb" "mysql_ldb")
REGISTER_SYMLINK("mariadb-plugin" "mysql_plugin")
REGISTER_SYMLINK("mariadb-secure-installation" "mysql_secure_installation")
REGISTER_SYMLINK("mariadb-setpermission" "mysql_setpermission")
REGISTER_SYMLINK("mariadb-show" "mysqlshow")
REGISTER_SYMLINK("mariadb-slap" "mysqlslap")
REGISTER_SYMLINK("mariadb-test" "mysqltest")
REGISTER_SYMLINK("mariadb-test-embedded" "mysqltest_embedded")
REGISTER_SYMLINK("mariadb-tzinfo-to-sql" "mysql_tzinfo_to_sql")
REGISTER_SYMLINK("mariadb-upgrade" "mysql_upgrade")
REGISTER_SYMLINK("mariadb-upgrade-service" "mysql_upgrade_service")
REGISTER_SYMLINK("mariadb-upgrade-wizard" "mysql_upgrade_wizard")
REGISTER_SYMLINK("mariadb-waitpid" "mysql_waitpid")
REGISTER_SYMLINK("mariadbd" "mysqld")
REGISTER_SYMLINK("mariadbd-multi" "mysqld_multi")
REGISTER_SYMLINK("mariadbd-safe" "mysqld_safe")
REGISTER_SYMLINK("mariadbd-safe-helper" "mysqld_safe_helper")

# Add MariaDB symlinks
macro(CREATE_MARIADB_SYMLINK src dir comp)
  # Find the MariaDB name for executable
  list(FIND MARIADB_SYMLINK_FROMS ${src} _index)

  if (${_index} GREATER -1)
    list(GET MARIADB_SYMLINK_TOS ${_index} mariadbname)
  endif()

  if (mariadbname)
    CREATE_MARIADB_SYMLINK_IN_DIR(${src} ${mariadbname} ${dir} ${comp})
  endif()
endmacro(CREATE_MARIADB_SYMLINK)

# Add MariaDB symlinks in directory
macro(CREATE_MARIADB_SYMLINK_IN_DIR dest src dir comp)
  CREATE_MARIADB_SYMLINK_IN_DIR_PREFIX(${dest} ${src} ${dir} ${comp} "SYM" ${dest})
endmacro(CREATE_MARIADB_SYMLINK_IN_DIR)

macro(CREATE_MARIADB_SYMLINK_IN_DIR_PREFIX dest src dir comp target_prefix depends)
  if(UNIX)
    add_custom_target(${target_prefix}_${src} ALL ${CMAKE_COMMAND} -E create_symlink ${dest} ${src}
      DEPENDS ${depends}
      COMMENT "Creating ${src} symlink")

    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${src} DESTINATION ${dir} COMPONENT ${comp})
  elseif(CMAKE_HOST_WIN32)
    add_custom_target(${target_prefix}_${src} ALL ${CMAKE_COMMAND} -E create_symlink ${dest}.exe ${CMAKE_CFG_INTDIR}/${src}.exe
      DEPENDS ${depends}.exe
      COMMENT "Creating ${src}.exe symlink")
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CFG_INTDIR}/${src}.exe" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CFG_INTDIR}" COMPONENT ${comp})
  endif()
endmacro(CREATE_MARIADB_SYMLINK_IN_DIR_PREFIX)
