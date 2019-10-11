cmake_minimum_required(VERSION 3.8)

# Why? Because the macro will be invoked in the caller's CMake scope.
set(INITIALIZE_HUNTER_DIR ${CMAKE_CURRENT_LIST_DIR} CACHE INTERNAL "")

# This function must be called BEFORE project()
# Uses the variables: HUNTER_URL, HUNTER_SHA1, HUNTER_CONFIG_PATH, HUNTER_CACHE_SERVERS, HUNTER_PASSWORDS_PATH, 
#                     HUNTER_RUN_UPLOAD, HUNTER_PREFER_RELEASE_DEPENDENCIES, HUNTER_STATUS_DEBUG
macro(InitializeHunter)
  # Set relevant policies.
  if(POLICY CMP0074)
    cmake_policy(SET CMP0074 NEW)
  endif(POLICY CMP0074)
  
  if(POLICY CMP0083)
    cmake_policy(SET CMP0083 NEW)
  endif(POLICY CMP0083)

  set(HUNTER_GATE_PATH "${INITIALIZE_HUNTER_DIR}/gate/cmake/HunterGate.cmake")
  if(NOT EXISTS "${HUNTER_GATE_PATH}")
    message(FATAL_ERROR "HunterGate does not exist at ${HUNTER_GATE_PATH}")
  endif()

  if(HUNTER_PREFER_RELEASE_DEPENDENCIES)
    # MSVC is very particular about not linking to release libraries for debug builds.
    # Can't be more specific about the platform (ex. MSVC) because project() hasn't run yet.
    if(WIN32 AND NOT ANDROID)
      set(HUNTER_CONFIGURATION_TYPES "Release;Debug" CACHE STRING "Hunter dependency build variants" FORCE)
      message("MSVC needs Debug libraries, ignoring HUNTER_PREFER_RELEASE_DEPENDENCIES")
    else()
      set(HUNTER_CONFIGURATION_TYPES "Release" CACHE STRING "Hunter dependency build variants" FORCE)
    endif()
  endif()

  string(COMPARE EQUAL "${HUNTER_CONFIG_PATH}" "" HUNTER_CONFIG_PATH_EMPTY)
  if(NOT HUNTER_CONFIG_PATH_EMPTY AND NOT EXISTS "${HUNTER_CONFIG_PATH}")
    message(FATAL_ERROR "Hunter config file ${HUNTER_CONFIG_PATH} does not exist!")
  else()
    message("Using HunterConfig at ${HUNTER_CONFIG_PATH}")
  endif()  

  string(COMPARE EQUAL "${HUNTER_PASSWORDS_PATH}" "" HUNTER_PASSWORDS_PATH_EMPTY)
  if(NOT HUNTER_PASSWORDS_PATH_EMPTY AND NOT EXISTS "${HUNTER_PASSWORDS_PATH}")
    message(FATAL_ERROR "Hunter passwords file ${HUNTER_PASSWORDS_PATH} does not exist!")
  else()
    message("Using HunterPasswords at ${HUNTER_PASSWORDS_PATH}")
  endif()
  
  include(${HUNTER_GATE_PATH})

  HunterGate(
    URL "${HUNTER_URL}"
    SHA1 "${HUNTER_SHA1}"
    FILEPATH "${HUNTER_CONFIG_PATH}"
  )
endmacro()
