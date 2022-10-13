# Copyright (c) 2016, 2018 Ruslan Baratov
# All rights reserved.

if(DEFINED POLLY_OSX_MAKE_CXX17_CMAKE_)
  return()
else()
  set(POLLY_OSX_MAKE_CXX17_CMAKE_ 1)
endif()

include("${CMAKE_CURRENT_LIST_DIR}/utilities/polly_module_path.cmake")
include(polly_clear_environment_variables)
include(polly_init)
include("${CMAKE_CURRENT_LIST_DIR}/os/osx-default-sdk.cmake") # -> OSX_SDK_VERSION, OSX_DEPLOYMENT_SDK_VERSION

set(POLLY_XCODE_COMPILER "clang")
polly_init(
    "Makefile (OS X ${OSX_SDK_VERSION} | Deployment ${OSX_DEPLOYMENT_SDK_VERSION}) / \
${POLLY_XCODE_COMPILER} / \
LLVM Standard C++ Library (libc++) / c++17 support"
    "Unix Makefiles"
)

include(polly_common)

set(CMAKE_OSX_DEPLOYMENT_TARGET ${OSX_DEPLOYMENT_SDK_VERSION} CACHE STRING "OS X Deployment target" FORCE)

include("${CMAKE_CURRENT_LIST_DIR}/library/std/libcxx.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/flags/cxx17.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/os/osx.cmake")
