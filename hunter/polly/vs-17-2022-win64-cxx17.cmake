# Copyright (c) 2015-2022, Ruslan Baratov, Rahul Sheth
# All rights reserved.

if(DEFINED POLLY_VS_17_2022_WIN64_CXX17_CMAKE_)
  return()
else()
  set(POLLY_VS_17_2022_WIN64_CXX17_CMAKE_ 1)
endif()

include("${CMAKE_CURRENT_LIST_DIR}/utilities/polly_init.cmake")

polly_init(
    "Visual Studio 17 2022 Win64 / C++17"
    "Visual Studio 17 2022"
)

include("${CMAKE_CURRENT_LIST_DIR}/utilities/polly_common.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/flags/vs-cxx17.cmake")

include("${CMAKE_CURRENT_LIST_DIR}/flags/vs-platform-x64.cmake")
