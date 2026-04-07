cmake_minimum_required(VERSION 3.22.1)
project(appmodules)

# Keep React Native default appmodules setup so core TurboModules
# (e.g. PlatformConstants) are properly registered in New Architecture.
include(${REACT_ANDROID_DIR}/cmake-utils/ReactNative-application.cmake)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)

set(WHISPER_DIR ${CMAKE_CURRENT_SOURCE_DIR}/whisper)

# Keep whisper build focused on mobile runtime only.
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(WHISPER_CURL OFF CACHE BOOL "" FORCE)
set(WHISPER_SDL2 OFF CACHE BOOL "" FORCE)
set(WHISPER_OPENVINO OFF CACHE BOOL "" FORCE)
set(WHISPER_COREML OFF CACHE BOOL "" FORCE)
set(WHISPER_ALL_WARNINGS OFF CACHE BOOL "" FORCE)

set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
set(GGML_BLAS OFF CACHE BOOL "" FORCE)
set(GGML_ACCELERATE OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
set(GGML_CPU ON CACHE BOOL "" FORCE)
set(GGML_ALL_WARNINGS OFF CACHE BOOL "" FORCE)

add_subdirectory(${WHISPER_DIR} whisper-build)

add_library(
        voicescribe-whisper
        SHARED
        whisper-jni.cxx
)

target_include_directories(
        voicescribe-whisper
        PRIVATE
        ${WHISPER_DIR}/include
)

target_compile_options(
        voicescribe-whisper
        PRIVATE
        -O3
        -DNDEBUG
)

find_library(log-lib log)
target_link_libraries(
        voicescribe-whisper
        PRIVATE
        whisper
        ${log-lib}
)
