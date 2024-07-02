# This is for building Souffle (NOT Formulog) programs

cmake_minimum_required(VERSION 3.21)
project(codegen)

set(CMAKE_CXX_STANDARD 17)

set(CMAKE_CXX_FLAGS "-DRAM_DOMAIN_SIZE=32 -Wall -Wno-unused-variable -Wno-unused-but-set-variable -Wno-c++11-narrowing")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -march=native")

add_executable(bench "bench.cpp")

set(SIPS "all-bound" CACHE STRING "Set sideways information passing strategy")
set(SOUFFLE_FLAGS -w -j 2 -PRamSIPS:${SIPS})

option(EAGER_EVAL "Generate code performing eager evaluation (requires custom Soufflé)" OFF)
if (EAGER_EVAL)
    set(SOUFFLE_FLAGS ${SOUFFLE_FLAGS} --eager-eval)
endif ()

option(RECORD_WORK "Report amount of work performed during evaluation (requires custom Soufflé)" OFF)
if (RECORD_WORK)
    set(SOUFFLE_FLAGS ${SOUFFLE_FLAGS} --record-work)
endif ()

add_custom_command(OUTPUT bench.cpp
        COMMAND souffle ${CMAKE_CURRENT_SOURCE_DIR}/src/bench.dl ${SOUFFLE_FLAGS} -g bench.cpp
        DEPENDS src/bench.dl)

find_package(OpenMP)
if (OpenMP_CXX_FOUND)
    target_link_libraries(bench PRIVATE OpenMP::OpenMP_CXX)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fopenmp")
endif ()

find_package(TBB REQUIRED)
target_link_libraries(bench PRIVATE TBB::tbb)
