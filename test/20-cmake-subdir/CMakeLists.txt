cmake_minimum_required(VERSION 3.24)
project(test_external_consumer)

# Simulate external consumer using add_subdirectory, like a git submodule
# consumer would. The dependency is added as its own subdirectory and must
# come before mulle-core-all-load, which inherits its headers, definitions
# and link targets.
#
# mulle-core is a dependency of this test project. mulle-sde keeps the
# checkout of a dependency in the sourcetree stash (see `mulle-sde howto
# testing`). Use MULLE_SOURCETREE_STASH_DIR when it is exported, and fall back
# to the default "stash" directory of the test project otherwise.
set(MULLE_SOURCETREE_STASH_DIR "$ENV{MULLE_SOURCETREE_STASH_DIR}")
if(NOT MULLE_SOURCETREE_STASH_DIR)
   set(MULLE_SOURCETREE_STASH_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../stash")
endif()

add_subdirectory("${MULLE_SOURCETREE_STASH_DIR}/mulle-core" ${CMAKE_CURRENT_BINARY_DIR}/mulle-core_build)
add_subdirectory( ../.. mulle-core-all-load_build)

if(NOT TARGET mulle-core-all-load)
    message(FATAL_ERROR "Target mulle-core-all-load not found after add_subdirectory")
endif()
if(NOT TARGET mulle-core-all-load-force)
    message(FATAL_ERROR "Force-link wrapper mulle-core-all-load-force not found")
endif()

get_target_property(INTERFACE_LIBS mulle-core-all-load INTERFACE_LINK_LIBRARIES)
if(NOT INTERFACE_LIBS MATCHES "mulle-core-all-load-force")
    message(FATAL_ERROR "mulle-core-all-load does not reference its force-link wrapper: ${INTERFACE_LIBS}")
endif()

get_target_property(FORCE_LIBS mulle-core-all-load-force INTERFACE_LINK_LIBRARIES)
if(NOT FORCE_LIBS MATCHES "LINK_LIBRARY:WHOLE_ARCHIVE")
    message(FATAL_ERROR "Force-link wrapper does not whole-archive the library: ${FORCE_LIBS}")
endif()

message(STATUS "Force-link flags: ${FORCE_LIBS}")
file(WRITE "${CMAKE_BINARY_DIR}/force_link_detected.txt" "SUCCESS: ${FORCE_LIBS}")

# Create a simple test executable
add_executable(test_consumer test_consumer.c)
target_link_libraries(test_consumer mulle-core-all-load)

# Copy executable to expected location for mulle-test
add_custom_command(TARGET test_consumer POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:test_consumer> ${CMAKE_BINARY_DIR}/cmake-subdir.exe
)
