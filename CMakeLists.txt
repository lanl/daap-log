#Top-level CMakeLists.txt for daap_log project
cmake_minimum_required(VERSION 3.10.2)
project(daap_log VERSION 0.1)
set(CMAKE_BUILD_TYPE Release)
set(CMAKE_INSTALL_PREFIX ..)

option(BUILD_TEST "Build test/example to demonstrate usage of DAAP library" ON)
option(USE_SYSLOG "Use Syslog as transport layer" ON)
option(USE_LDMS "Use LDMS Streams as transport layer" OFF)
option(USE_RABBIT "Use RabbitMQ as transport layer" OFF)
option(USE_P2P "Use point-to-point user processes as transport layer (launched with job)" OFF)

if ((USE_SYSLOG AND (USE_LDMS OR USE_RABBIT OR USE_P2P)) OR (USE_LDMS AND (USE_RABBIT OR USE_P2P)) OR (USE_RABBIT AND USE_P2P) ) 
  message(FATAL_ERROR "The daap_log library can only be built for one transport layer at a time")
endif()

#Add source files directory
add_subdirectory(src)

set(PROJECT_LINK_LIBS libdaap_log.so)
link_directories( build )

#set(LIB lib/libdaap_log.so)

# add the binary tree to the search path for include files
# so that we will find daap_logConfig.h
target_include_directories(daap_log PUBLIC
                           "${PROJECT_BINARY_DIR}"
                           )
