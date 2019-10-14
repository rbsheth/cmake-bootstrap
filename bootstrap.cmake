set(CMAKE_DEBUG_POSTFIX "-debug")
set(CMAKE_RELWITHDEBINFO_POSTFIX "-relwithdebinfo")

if(CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
  set(_is_emscripten TRUE)
elseif(CMAKE_OSX_SYSROOT STREQUAL "iphoneos")
  set(_is_ios TRUE)
elseif(CMAKE_OSX_SYSROOT STREQUAL "iphonesimulator")
  set(_is_ios_sim TRUE)
elseif(ANDROID)
  set(_is_android TRUE)
elseif(CMAKE_OSX_SYSROOT MATCHES ".*MacOSX.*")
  set(_is_osx TRUE)
endif()

if(_is_osx)
  #For other libraries installed on the system (i.e. via homebrew)
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_CXX_LINKER_FLAGS} -L/usr/local/lib")
  set(ENV{PATH} "$ENV{PATH}:/usr/local/bin")
endif()

if(_is_emscripten)
  if(NOT CMAKE_C_ABI_COMPILED)
    set(CMAKE_C_ABI_COMPILED ON)
  endif()
  if(NOT CMAKE_CXX_ABI_COMPILED)
    set(CMAKE_CXX_ABI_COMPILED ON)
  endif()
endif()

# Setup ccache, if available
# From https://stackoverflow.com/a/34317588
#-----------------------------------------------------------------------------
# Enable ccache if not already enabled by symlink masquerading and if no other
# CMake compiler launchers are already defined
#-----------------------------------------------------------------------------
find_program(CCACHE_EXECUTABLE ccache)
mark_as_advanced(CCACHE_EXECUTABLE)
if(CCACHE_EXECUTABLE)
  foreach(LANG C CXX)
    if(NOT DEFINED CMAKE_${LANG}_COMPILER_LAUNCHER AND NOT CMAKE_${LANG}_COMPILER MATCHES ".*/ccache$" AND NOT _is_emscripten)
      message(STATUS "Enabling ccache for ${LANG}")
      set(CMAKE_${LANG}_COMPILER_LAUNCHER ${CCACHE_EXECUTABLE} CACHE STRING "")
    endif()
  endforeach()
endif()

set(${PROJ_NAME}_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR})
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake/modules/Find)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake/modules/OptimizeForArchitecture)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake/cmrc)
include(CMakeToolsHelpers OPTIONAL) #For VS Code's CMakeTools
include(BuildSourceGroup)
include(OptimizeForArchitecture)
include(CMakeRC)
include(AddSources)

option(${PROJ_NAME}_BUILD_PROJECTS "Build the executables that depend on the ${PROJ_NAME} library." ON)
option(${PROJ_NAME}_BUILD_TESTS "Build the executables that test the ${PROJ_NAME} library." ON)
option(${PROJ_NAME}_BUILD_SHARED_LIBS "Build ${PROJ_NAME} libraries as shared (.so/.dylib/.dll) instead of static (.a)" OFF)
option(${PROJ_NAME}_ENABLE_CLANG_FORMAT "Enable automatic formatting of source files." OFF)
option(${PROJ_NAME}_ENABLE_CLANG_TIDY "Enable static analysis of code through clang-tidy." OFF)
option(${PROJ_NAME}_ENABLE_IWYU "Enable running include-what-you-use/iwyu for source files." OFF)
option(${PROJ_NAME}_ENABLE_CUDA "Enable GPU compute using CUDA." OFF)
option(${PROJ_NAME}_DISABLE_ARCHITECTURE_OPTIMIZATION "Add compiler flags to tune for your machine's architecture. Will default to core/sse2 if ON and on a supported platform." OFF)
option(${PROJ_NAME}_BUILD_JAVA_BINDINGS "Build ${PROJ_NAME} Java bindings (requires swig installed and in path)" OFF)
option(${PROJ_NAME}_BUILD_PYTHON_BINDINGS "Build ${PROJ_NAME} Python bindings (requires swig installed and in path)" OFF)
option(${PROJ_NAME}_DEV "Enable development features like debug logging, regardless of build type" OFF)

IF(${PROJ_NAME}_ENABLE_CLANG_FORMAT)
  find_program(CLANG_FORMAT_EXE "clang-format")
  if(NOT CLANG_FORMAT_EXE)
    message(FATAL_ERROR "Could not locate clang-format on this system. Please install before running cmake.")
  endif()
  set(GCF_GIT_PATH "git")
  set(GCF_PYTHON_PATH "python")
  set(GCF_CLANGFORMAT_PATH "clang-format")
  set(GCF_CLANGFORMAT_STYLE "Google")
  add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/cmake/git-cmake-format)
ENDIF()

IF(${PROJ_NAME}_ENABLE_CLANG_TIDY)
  find_program(CLANG_TIDY_EXE "clang-tidy")
  if(NOT CLANG_TIDY_EXE)
    message(FATAL_ERROR "Could not locate clang-tidy on this system. Please install before running cmake.")
  else()
    set(DO_CLANG_TIDY "${CLANG_TIDY_EXE}" "-checks=*")
    set(CMAKE_CXX_CLANG_TIDY ${DO_CLANG_TIDY})
    set(CMAKE_C_CLANG_TIDY ${DO_CLANG_TIDY})
  endif()
ENDIF()

IF(${PROJ_NAME}_ENABLE_IWYU)
  find_program(IWYU_EXE NAMES "include-what-you-use" "iwyu")
  if(NOT IWYU_EXE)
    message(FATAL_ERROR "Could not locate include-what-you-use or iwyu on this system. Please install before running cmake.")
  else()
    set(CMAKE_CXX_INCLUDE_WHAT_YOU_USE ${IWYU_EXE})
    set(CMAKE_C_INCLUDE_WHAT_YOU_USE ${IWYU_EXE})
  endif()
ENDIF()

IF(${PROJ_NAME}_ENABLE_CUDA)
  enable_language(CUDA)
ENDIF()

if(_is_emscripten OR _is_android OR _is_ios)
  get_property(${PROJ_NAME}_DISABLE_ARCHITECTURE_OPTIMIZATION_HELPSTRING CACHE "${${PROJ_NAME}_DISABLE_ARCHITECTURE_OPTIMIZATION}" PROPERTY HELPSTRING)
  set(${PROJ_NAME}_DISABLE_ARCHITECTURE_OPTIMIZATION ON CACHE BOOL "${${PROJ_NAME}_DISABLE_ARCHITECTURE_OPTIMIZATION_HELPSTRING}" FORCE)
  set(TARGET_ARCHITECTURE "none" CACHE STRING "" FORCE)
  set(${PROJ_NAME}_BUILD_SHARED_LIBS FALSE CACHE BOOL "" FORCE)
elseif(${PROJ_NAME}_DISABLE_ARCHITECTURE_OPTIMIZATION)
  set(TARGET_ARCHITECTURE "core" CACHE STRING "" FORCE)
endif()

if(NOT ${PROJ_NAME}_DISABLE_ARCHITECTURE_OPTIMIZATION AND NOT OPT_ARCH_FLAGS)
  OptimizeForArchitecture()
  set(ARCH_FLAGS "")
  foreach(_flag IN LISTS Vc_ARCHITECTURE_FLAGS)
    set(ARCH_FLAGS "${ARCH_FLAGS} ${_flag}" )
  endforeach()
  string(STRIP "${ARCH_FLAGS}" OPT_ARCH_FLAGS)
  add_compile_options(${OPT_ARCH_FLAGS})
endif()

if(${PROJ_NAME}_DEV)
  add_compile_definitions(${PROJ_NAME}_DEV)
endif()

if(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
  # Enable math defines like M_PI
  add_compile_definitions(_USE_MATH_DEFINES)
  # Enable multi-threaded compilation
  add_compile_options(/MP)
  # Enable Edit and Continue
  set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /ZI")
  set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_DEBUG} /ZI")
  # Define _WIN32_WINNT=0x0600 for gRPC
  add_compile_definitions(_WIN32_WINNT=0x0600)
  # Disable CRT security warnings
  add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
endif()

# Turn on the ability to group targets in IDE folders.
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# Java/Python projects are created as runnable tests, so enable testing regardless
# of the ${PROJ_NAME}_BUILD_TESTS option.
enable_testing()

set(SOURCE_GROUP_NAME ${PROJ_NAME})

if(${PROJ_NAME}_BUILD_PROJECTS)
  include(CreateProject)
endif()

if(${PROJ_NAME}_BUILD_TESTS)
  include(CreateTest)
endif()

include(SwigCommonSetup)
include(GenerateJavaBindings)
include(GeneratePythonBindings)

include(GenerateProtobufFiles)
