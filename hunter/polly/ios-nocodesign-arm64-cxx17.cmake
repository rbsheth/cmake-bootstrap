# Copyright (c) 2016, Ruslan Baratov
# All rights reserved.

if(DEFINED POLLY_IOS_NOCODESIGN_ARM64_CXX17_CMAKE_)
  return()
else()
  set(POLLY_IOS_NOCODESIGN_ARM64_CXX17_CMAKE_ 1)
endif()

include("${CMAKE_CURRENT_LIST_DIR}/utilities/polly_module_path.cmake")
include(polly_clear_environment_variables)
include(polly_init)

include("${CMAKE_CURRENT_LIST_DIR}/os/iphone-default-sdk.cmake") # -> IOS_SDK_VERSION, IOS_DEPLOYMENT_SDK_VERSION

set(POLLY_XCODE_COMPILER "clang")
polly_init(
    "iOS ${IOS_SDK_VERSION} / Deployment ${IOS_DEPLOYMENT_SDK_VERSION} / arm64 / \
${POLLY_XCODE_COMPILER} / \
No code sign / \
c++17 support"
    "Xcode"
)

include(polly_common)

# Fix try_compile
include(polly_ios_bundle_identifier)
set(CMAKE_MACOSX_BUNDLE YES)

include("${CMAKE_CURRENT_LIST_DIR}/flags/ios_nocodesign.cmake")

set(IPHONEOS_ARCHS arm64)
set(IPHONESIMULATOR_ARCHS "")

include("${CMAKE_CURRENT_LIST_DIR}/compiler/xcode.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/os/iphone.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/flags/cxx17.cmake")
