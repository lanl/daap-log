#CMakeLists.txt file specific to the src directory

#Bring the headers into the project
#include_directories(include)

add_library(daap_log SHARED)

### START SETTINGS FOR RPATH ###
# use, i.e. don't skip the full RPATH for the build tree
SET(CMAKE_SKIP_BUILD_RPATH  FALSE)

# when building, don't use the install RPATH already
# (but later on when installing)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)

SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")

# add the automatically determined parts of the RPATH
# which point to directories outside the build tree to the install RPATH
SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# the RPATH to be used when installing, but only if it's not a system directory
LIST(FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES "${CMAKE_INSTALL_PREFIX}/lib" isSystemDir)
IF("${isSystemDir}" STREQUAL "-1")
   SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
ENDIF("${isSystemDir}" STREQUAL "-1")
### END SETTINGS FOR RPATH ###

if (BUILD_TEST)
#  list(APPEND EXTRA_LIBS test)
#  list(APPEND EXTRA_INCLUDES "${PROJECT_SOURCE_DIR}/test")
  # add the executable
  add_executable(test_logger test_logger.c)
  target_link_libraries(test_logger daap_log)
endif()


configure_file(daap_logConfig.h.in daap_logConfig.h)
target_sources(daap_log
	PRIVATE
	    daap_log.c
	    daap_init.c
	    daap_metric.c
	    daap_log.h
)

if (USE_SYSLOG)
	target_compile_definitions(daap_log PRIVATE -DUSE_SYSLOG)
elseif (USE_LDMS)
	target_compile_definitions(daap_log PRIVATE -DUSE_LDMS)
elseif (USE_RABBIT)
	target_compile_definitions(daap_log PRIVATE -DUSE_RABBIT)
elseif (USE_P2P)
	target_compile_definitions(daap_log PRIVATE -DUSE_P2P)
endif()

target_include_directories(daap_log 
			INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}
			)


install(TARGETS daap_log DESTINATION lib)
install(FILES daap_log.h DESTINATION include)
install(TARGETS test_logger DESTINATION test)

