#CMakeLists.txt file specific to the src directory

if ("${LIBRARY_TYPE}" STREQUAL "Shared")
   add_library(daap_log SHARED)
   add_library(daap_log_empty SHARED)
else()
   add_library(daap_log STATIC)
   add_library(daap_log_empty STATIC)
endif()

set_target_properties(daap_log PROPERTIES 
				SOVERSION ${VERSION_MAJOR}
   				VERSION   ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}
)

set_target_properties(daap_log_empty PROPERTIES 
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

find_package(OpenSSL REQUIRED)
message("OpenSSL include dir: ${OPENSSL_INCLUDE_DIR}")
message("OpenSSL libraries: ${OPENSSL_LIBRARIES}")
include_directories(${OPENSSL_INCLUDE_DIR})
target_link_libraries(daap_log OpenSSL::Crypto)
target_link_libraries(daap_log OpenSSL::SSL)

install(TARGETS daap_log DESTINATION lib)
install(TARGETS daap_log_empty DESTINATION lib)
install(FILES daap_log.h DESTINATION include)

if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    target_compile_definitions(daap_log PRIVATE -DDEBUG)
endif()

if (BUILD_TEST)
   # add the executable
   add_executable(test_logger test_logger.c)
   target_link_libraries(test_logger daap_log)
   install(TARGETS test_logger DESTINATION bin)
endif()

add_executable(stdout_parser stdout_parser.c)
target_link_libraries(stdout_parser daap_log)
install(TARGETS stdout_parser DESTINATION bin)

configure_file(daap_logConfig.h.in daap_logConfig.h)
target_sources(daap_log
	PRIVATE
            daap_log.c
            daap_init.c
            daap_tcp.c
            daap_metric.c
            daap_timestr.c
            daap_log.h
            cJSON.c
            cJSON.h
)

target_include_directories(daap_log 
			INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}
			)

target_sources(daap_log_empty
	PRIVATE
            daap_log_empty.c
            daap_init_empty.c
)

target_include_directories(daap_log_empty
			INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}
			)
