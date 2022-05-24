# Copyright (c) 2015-2021, Ruslan Baratov, Rahul Sheth
# All rights reserved.

if(DEFINED POLLY_VS_16_2019_WIN64_SDK_10_0_18362_0_CXX17_CMAKE_)
  return()
else()
  set(POLLY_VS_16_2019_WIN64_SDK_10_0_18362_0_CXX17_CMAKE_ 1)
endif()

include("${CMAKE_CURRENT_LIST_DIR}/utilities/polly_init.cmake")

polly_init(
    "Visual Studio 16 2019 Win64 / C++17 | Windows SDK 10.0.18362.0"
    "Visual Studio 16 2019"
)

include("${CMAKE_CURRENT_LIST_DIR}/utilities/polly_common.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/flags/vs-cxx17.cmake")

include("${CMAKE_CURRENT_LIST_DIR}/flags/vs-platform-x64.cmake")

set(CMAKE_SYSTEM_VERSION 10.0.18362.0)
