# Copyright (c) 2018, Ruslan Baratov
# All rights reserved.

if(DEFINED POLLY_OSX_11_0_CMAKE_)
  return()
else()
  set(POLLY_OSX_11_0_CMAKE_ 1)
endif()

include("${CMAKE_CURRENT_LIST_DIR}/utilities/polly_init.cmake")

set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64" CACHE STRING "OS X Target Architectures" FORCE)
string(REPLACE ";" "+" CMAKE_OSX_ARCHITECTURES_STR "${CMAKE_OSX_ARCHITECTURES}")

set(OSX_SDK_VERSION "11.0")
set(POLLY_XCODE_COMPILER "clang")
polly_init(
    "Xcode (OS X ${OSX_SDK_VERSION}) / \
${POLLY_XCODE_COMPILER} / ${CMAKE_OSX_ARCHITECTURES_STR} / \
LLVM Standard C++ Library (libc++) / c++11 support"
    "Xcode"
)

include("${CMAKE_CURRENT_LIST_DIR}/utilities/polly_common.cmake")

include("${CMAKE_CURRENT_LIST_DIR}/compiler/xcode.cmake")

set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0" CACHE STRING "OS X Deployment target" FORCE)

include("${CMAKE_CURRENT_LIST_DIR}/library/std/libcxx.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/flags/cxx11.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/os/osx.cmake")
