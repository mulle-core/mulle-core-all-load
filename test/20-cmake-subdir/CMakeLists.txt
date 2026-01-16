cmake_minimum_required(VERSION 3.19)
project(test_external_consumer)

# Simulate external consumer using add_subdirectory
add_subdirectory( ../.. mulle-core-all-load_build)

# Check if the target exists after add_subdirectory
if(TARGET mulle-core-all-load)
    message(STATUS "Found target: mulle-core-all-load")
    get_target_property(LINK_OPTIONS mulle-core-all-load INTERFACE_LINK_OPTIONS)
    if(LINK_OPTIONS)
        message(STATUS "Force-link flags: ${LINK_OPTIONS}")
        file(WRITE "${CMAKE_BINARY_DIR}/force_link_detected.txt" "SUCCESS: ${LINK_OPTIONS}")
    else()
        message(STATUS "No force-link flags found")
        file(WRITE "${CMAKE_BINARY_DIR}/force_link_detected.txt" "FAILED: No force-link flags")
    endif()
else()
    message(STATUS "Target mulle-core-all-load not found")
    file(WRITE "${CMAKE_BINARY_DIR}/force_link_detected.txt" "FAILED: Target not found")
endif()

# Create a simple test executable
add_executable(test_consumer test_consumer.c)
target_link_libraries(test_consumer mulle-core-all-load)

# Copy executable to expected location for mulle-test
add_custom_command(TARGET test_consumer POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:test_consumer> ${CMAKE_BINARY_DIR}/cmake-subdir.exe
)
