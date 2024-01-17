cmake_minimum_required(VERSION 3.21)

if(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})
  message(FATAL_ERROR "In-source builds not allowed. Please make a new directory (called a build directory) and run CMake from there. You may need to remove CMakeCache.txt. ")
endif()

project(autd3-firmware-test LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(COVERAGE "Take coverage" OFF)

if(COVERAGE)
  set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} --coverage -fno-inline")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
endif()

set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)

if(POLICY CMP0135)
  cmake_policy(SET CMP0135 NEW)
endif()
include(${PROJECT_SOURCE_DIR}/gtest.cmake)

enable_testing()

add_executable(test_autd3-firmware main.cpp ${PROJECT_SOURCE_DIR}/../src/app.c ${PROJECT_SOURCE_DIR}/../src/buf.c app.cpp)
set_target_properties(test_autd3-firmware PROPERTIES LINKER_LANGUAGE CXX)
set_source_files_properties(${PROJECT_SOURCE_DIR}/../src/app.c PROPERTIES LANGUAGE CXX)
add_subdirectory(op)

target_include_directories(test_autd3-firmware PRIVATE ${PROJECT_SOURCE_DIR}/inc)
target_include_directories(test_autd3-firmware PRIVATE ${PROJECT_SOURCE_DIR}/../inc)
target_link_libraries(test_autd3-firmware PRIVATE gtest_main)

include(GoogleTest)
gtest_discover_tests(test_autd3-firmware)
