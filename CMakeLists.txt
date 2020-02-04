#Top-level CMakeLists.txt for daap_log project
cmake_minimum_required(VERSION 3.16.3)

# set options for Build types
if (NOT CMAKE_CONFIGURATION_TYPES )
   set( CMAKE_CONFIGURATION_TYPES Debug Release )
endif()

# make 'Release' the default build type and provide help text for ccmake
set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build (Debug or Release)"  )
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS ${CMAKE_CONFIGURATION_TYPES} )

# make ../ the default install prefix and provide help text for ccmake
set(CMAKE_INSTALL_PREFIX .. CACHE STRING "Install path prefix, prepended onto install directories.")

project(daap_log VERSION 0.1)

option(BUILD_SHARED_LIB "Build daap_log library as a shared object (if OFF, library will be static)" ON)
option(BUILD_TEST "Build test/example to demonstrate usage of daap_log library" ON)
option(USE_SYSLOG "Use Syslog as transport layer" ON)
option(USE_LDMS "Use LDMS Streams as transport layer" OFF)
option(USE_RABBIT "Use RabbitMQ as transport layer" OFF)
option(USE_P2P "Use point-to-point user processes as transport layer (launched with user job)" OFF)

if ((USE_SYSLOG AND (USE_LDMS OR USE_RABBIT OR USE_P2P)) 
    OR (USE_LDMS AND (USE_RABBIT OR USE_P2P)) 
    OR (USE_RABBIT AND USE_P2P) ) 
   message(FATAL_ERROR "The daap_log library can only be built for one transport layer at a time")
endif()

#Add source files directory
add_subdirectory(src)

set(PROJECT_LINK_LIBS daap_log)
link_directories(build) 

# add the binary tree to the search path for include files
# so that we will find daap_logConfig.h
target_include_directories(daap_log PUBLIC
                           "${PROJECT_BINARY_DIR}"
                           )

