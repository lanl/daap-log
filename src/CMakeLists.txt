#CMakeLists.txt file specific to the src directory

if ("${LIBRARY_TYPE}" STREQUAL "Shared")
   add_library(daap_log SHARED)
else()
   add_library(daap_log STATIC)
endif()

set_target_properties(daap_log PROPERTIES 
				SOVERSION ${VERSION_MAJOR}
   				VERSION   ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}
)

### START SETTINGS FOR RPATH ###
# use RPATH, i.e. don't skip the full RPATH for the build tree
SET(CMAKE_SKIP_BUILD_RPATH  FALSE)

# don't use the install RPATH when building
# (only later on when installing)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)

# add the automatically determined parts of the RPATH
# that point to directories outside the build tree to the install RPATH
SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# set the RPATH to be used when installing, but only if it's a directory 
# not automatically searched.
# (a directory in CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES)
LIST(FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES "${CMAKE_INSTALL_PREFIX}/lib" isSystemDir)
if("${isSystemDir}" STREQUAL "-1")
   SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
endif("${isSystemDir}" STREQUAL "-1")
### END SETTINGS FOR RPATH ###

if (BUILD_TEST)
#  list(APPEND EXTRA_LIBS test)
#  list(APPEND EXTRA_INCLUDES "${PROJECT_SOURCE_DIR}/test")
   # add the executable
   add_executable(test_logger test_logger.c)
   target_link_libraries(test_logger daap_log)
   install(TARGETS test_logger DESTINATION test)
endif()


configure_file(daap_logConfig.h.in daap_logConfig.h)
target_sources(daap_log
	PRIVATE
	    daap_log.c
	    daap_init.c
	    daap_metric.c
	    daap_timestr.c
	    daap_log.h
)


if ("${TRANSPORT_LAYER}" STREQUAL "syslog")
	target_compile_definitions(daap_log PRIVATE -DUSE_SYSLOG)
elseif ("${TRANSPORT_LAYER}" STREQUAL "LDMS")
	target_compile_definitions(daap_log PRIVATE -DUSE_LDMS)
elseif ("${TRANSPORT_LAYER}" STREQUAL "RabbitMQ")
	target_compile_definitions(daap_log PRIVATE -DUSE_RABBIT)
elseif ("${TRANSPORT_LAYER}" STREQUAL "TCP")
	target_compile_definitions(daap_log PRIVATE -DUSE_TCP)
endif()

target_include_directories(daap_log 
			INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}
			)

install(TARGETS daap_log DESTINATION lib)
install(FILES daap_log.h DESTINATION include)

