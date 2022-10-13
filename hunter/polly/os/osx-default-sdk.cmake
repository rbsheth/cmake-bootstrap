# This script sets the following variables :
# OSX_SDK_VERSION : will contain the version number of the default macOS SDK (example : 11.0)
# OSX_DEPLOYMENT_SDK_VERSION: minimum suggestd Deployment SDK version
# MACOS_SDK_ROOT : full path to the SDK
# MACOS_ROOT
# XCODE_DEVELOPER_ROOT

if(DEFINED POLLY_OSX_DEFAULT_SDK_CMAKE)
  return()
else()
  set(POLLY_OSX_DEFAULT_SDK_CMAKE 1)
endif()

include(polly_status_debug)

# polly_find_xcode_macos_defaults : 
# fills 
# * XCODE_DEVELOPER_ROOT
# * MACOS_ROOT 
# * MACOS_SDK_ROOT
macro (polly_find_xcode_macos_defaults)
  find_program(XCODE_SELECT_EXECUTABLE xcode-select)
  if(NOT XCODE_SELECT_EXECUTABLE)
    polly_fatal_error("xcode-select not found")
  endif()
  execute_process(
    COMMAND
    ${XCODE_SELECT_EXECUTABLE}
    "-print-path"
    OUTPUT_VARIABLE 
      XCODE_DEVELOPER_ROOT # /.../Xcode.app/Contents/Developer
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE
      _XCODE_DEVELOPER_ROOT_STATUS
  )
  if(NOT "${_XCODE_DEVELOPER_ROOT_STATUS}" EQUAL "0")
    polly_fatal_error("Could not find XCODE_DEVELOPER_ROOT.
      The command
      ${XCODE_SELECT_EXECUTABLE} -print-path
      failed with the following status : ${_XCODE_DEVELOPER_ROOT_STATUS}
      ")
  endif()

  set(MACOS_ROOT "${XCODE_DEVELOPER_ROOT}/Platforms/MacOSX.platform/Developer")
  # The defautl SDK is at ${MACOS_ROOT}/SDKs/MacOSX.sdk
  set(MACOS_SDK_ROOT "${MACOS_ROOT}/SDKs/MacOSX.sdk")
  polly_status_debug("XCODE_DEVELOPER_ROOT=${XCODE_DEVELOPER_ROOT}")
  polly_status_debug("MACOS_ROOT=${MACOS_ROOT}")
  polly_status_debug("MACOS_SDK_ROOT=${MACOS_SDK_ROOT}")
endmacro()

polly_find_xcode_macos_defaults()

# The version number of the SDK can be accessed by reading the SDKSettings.plist file with the command :
#   defaults read ${MACOS_SDK_ROOT}/SDKSettings.plist DefaultDeploymentTarget
execute_process(
  COMMAND
  "defaults"
  read
  ${MACOS_SDK_ROOT}/SDKSettings.plist
  DefaultDeploymentTarget
  RESULT_VARIABLE _POLLY_PROCESS_RESULT
  OUTPUT_VARIABLE OSX_SDK_VERSION
  OUTPUT_STRIP_TRAILING_WHITESPACE
  ERROR_STRIP_TRAILING_WHITESPACE
)
if(NOT "${_POLLY_PROCESS_RESULT}" EQUAL "0")
  polly_fatal_error("Could not read the macOS SDK version ().
    The command
    defaults read ${MACOS_SDK_ROOT}/SDKSettings.plist DefaultDeploymentTarget
    failed with the following status : ${_POLLY_PROCESS_RESULT}
    ")
endif()
polly_status_debug("OSX_SDK_VERSION=${OSX_SDK_VERSION}")

# Get minimum suggested Deployment SDK version
execute_process(
  COMMAND
  "/usr/libexec/PlistBuddy"
  -c "print 'DefaultProperties':DEPLOYMENT_TARGET_SUGGESTED_VALUES:0"
  ${MACOS_SDK_ROOT}/SDKSettings.plist
  RESULT_VARIABLE _POLLY_PROCESS_RESULT2
  OUTPUT_VARIABLE OSX_DEPLOYMENT_SDK_VERSION
  OUTPUT_STRIP_TRAILING_WHITESPACE
  ERROR_STRIP_TRAILING_WHITESPACE
)
if(NOT "${_POLLY_PROCESS_RESULT2}" EQUAL "0")
  polly_fatal_error("Could not read the minimum suggested Deployment macOS SDK version ().
    The command
    /usr/libexec/PlistBuddy -c \"print 'DefaultProperties':DEPLOYMENT_TARGET_SUGGESTED_VALUES:0\" ${MACOS_SDK_ROOT}/SDKSettings.plist
    failed with the following status : ${_POLLY_PROCESS_RESULT2}
    ")
endif()
polly_status_debug("OSX_DEPLOYMENT_SDK_VERSION=${OSX_DEPLOYMENT_SDK_VERSION}")
