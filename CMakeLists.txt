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
set(CMAKE_INSTALL_PREFIX .. CACHE PATH "Install path prefix, prepended onto install directories.")

project(daap_log VERSION 0.1)

# make syslog the default transport layer and provide help text
set(TRANSPORT_LAYER syslog CACHE STRING "Choose transport layer (syslog, LDMS Streams, RabbitMQ, Point-to-point)")
set_property(CACHE TRANSPORT_LAYER PROPERTY STRINGS syslog LDMS RabbitMQ P2P)

set(LIBRARY_TYPE Shared CACHE STRING "Choose type of library built (Shared, Static)")
set_property(CACHE LIBRARY_TYPE PROPERTY STRINGS Shared Static)

option(BUILD_TEST "Build test/example to demonstrate usage of daap_log library" ON)

#Add source files directory
add_subdirectory(src)

set(PROJECT_LINK_LIBS daap_log)
link_directories(build) 

# add the binary tree to the search path for include files
# so that we will find daap_logConfig.h
target_include_directories(daap_log PUBLIC
                           "${PROJECT_BINARY_DIR}"
                           )

