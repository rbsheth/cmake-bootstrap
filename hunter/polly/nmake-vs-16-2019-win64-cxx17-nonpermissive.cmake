# Copyright (c) 2014, 2018, Ruslan Baratov
# All rights reserved.

if(DEFINED POLLY_NMAKE_VS_16_2019_WIN64_CXX17_NONPERMISSIVE_CMAKE_)
  return()
else()
  set(POLLY_NMAKE_VS_16_2019_WIN64_CXX17_NONPERMISSIVE_CMAKE_ 1)
endif()

include("${CMAKE_CURRENT_LIST_DIR}/utilities/polly_init.cmake")

polly_init(
    "NMake / Visual Studio 2019 / x64 / C++17"
    "NMake Makefiles"
)

include("${CMAKE_CURRENT_LIST_DIR}/utilities/polly_common.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/flags/vs-cxx17.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/flags/vs-nonpermissive.cmake")
