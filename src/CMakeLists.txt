#CMakeLists.txt file specific to the src directory

#Bring the headers into the project
include_directories(include)

if (BUILD_TEST)
#  list(APPEND EXTRA_LIBS test)
#  list(APPEND EXTRA_INCLUDES "${PROJECT_SOURCE_DIR}/test")
  # add the executable
  add_executable(test_logger test_logger.c)
  target_link_libraries(test_logger PUBLIC ${PROJECT_LINK_LIBS})
endif()

add_library(daap_log SHARED)

configure_file(daap_logConfig.h.in daap_logConfig.h)
target_sources(daap_log
	PRIVATE
	    daap_log.c
	    daap_init.c
	    daap_metric.c
	PUBLIC
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

