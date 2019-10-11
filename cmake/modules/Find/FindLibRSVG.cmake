# - Try to find LibRSVG
# Once done, this will define
#
#  LibRSVG_FOUND - system has LibRSVG
#  LibRSVG_INCLUDE_DIRS - the LibRSVG include directories
#  LibRSVG_LIBRARIES - link these to use LibRSVG

include(LibFindMacros)

# Dependencies
libfind_package(LibRSVG GIO)
libfind_package(LibRSVG GDK-PixBuf)
libfind_package(LibRSVG PangoCairo)
libfind_package(LibRSVG LibCroco)

# Use pkg-config to get hints about paths
#libfind_pkg_check_modules(LibRSVG_PKGCONF librsvg-2.0)

# Include dir
set(LibRSVG_INCLUDE_DIR
  ${${PROJ_NAME}_ROOT_DIR}/3rdparty/include/librsvg-2.0
)

# Assuming we always build on 64-bit machines
if(NOT ${PROJ_NAME}_BUILD_LIBRSVG)
  if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    set(LIBRSVG_PREBUILT_BINARY_NAME librsvg-2-linux-64.a)
  elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(LIBRSVG_PREBUILT_BINARY_NAME librsvg-2-darwin-64.a)
  elseif(MSVC AND ${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    set(LIBRSVG_PREBUILT_BINARY_NAME librsvg-2-2-win-64.lib)
  endif()
endif()

# Finally the library itself
find_library(LibRSVG_LIBRARY
  NAMES ${LIBRSVG_PREBUILT_BINARY_NAME} librsvg-2.a
  PATHS ${${PROJ_NAME}_ROOT_DIR}/3rdparty/lib
  NO_DEFAULT_PATH
  NO_CMAKE_ENVIRONMENT_PATH
  NO_CMAKE_PATH
  NO_SYSTEM_ENVIRONMENT_PATH
  NO_CMAKE_SYSTEM_PATH
)

# Set the include dir variables and the libraries and let libfind_process do the rest.
# NOTE: Singular variables for this library, plural for libraries this this lib depends on.
set(LibRSVG_PROCESS_INCLUDES LibRSVG_INCLUDE_DIR GDK-PixBuf_INCLUDE_DIR PangoCairo_INCLUDE_DIR LibCroco_INCLUDE_DIR)
set(LibRSVG_PROCESS_LIBS LibRSVG_LIBRARY GDK-PixBuf_LIBRARY PangoCairo_LIBRARY LibCroco_LIBRARY)
libfind_process(LibRSVG)

# Override the detected MinGW libraries with pre-exported ones.
# Need to go through the whole pkg-config process to find include paths.
# Also, apparently these DLLs can't be found outside this file.
if(MSVC)
  include(CreateLibFromDll)

  set(LIBCAIRO_NAME libcairo-2)
  find_library(LIBCAIRO_DLL NAMES ${LIBCAIRO_NAME}.dll)
  CreateLibFromDll(${LIBCAIRO_NAME} ${LIBCAIRO_DLL} ${CMAKE_CURRENT_BINARY_DIR})

  set(LIBGOBJECT_NAME libgobject-2.0-0)
  find_library(LIBGOBJECT_DLL NAMES ${LIBGOBJECT_NAME}.dll)
  CreateLibFromDll(${LIBGOBJECT_NAME} ${LIBGOBJECT_DLL} ${CMAKE_CURRENT_BINARY_DIR})

  set(LIBGLIB_NAME libglib-2.0-0)
  find_library(LIBGLIB_DLL NAMES ${LIBGLIB_NAME}.dll)
  CreateLibFromDll(${LIBGLIB_NAME} ${LIBGLIB_DLL} ${CMAKE_CURRENT_BINARY_DIR})

  set(LIBGIO_NAME libgio-2.0-0)
  find_library(LIBGIO_DLL NAMES ${LIBGIO_NAME}.dll)
  CreateLibFromDll(${LIBGIO_NAME} ${LIBGIO_DLL} ${CMAKE_CURRENT_BINARY_DIR})

  set(LibRSVG_LIBRARIES
    ${LibRSVG_LIBRARY}
    ${CMAKE_CURRENT_BINARY_DIR}/${LIBCAIRO_NAME}.lib
    ${CMAKE_CURRENT_BINARY_DIR}/${LIBGOBJECT_NAME}.lib
    ${CMAKE_CURRENT_BINARY_DIR}/${LIBGLIB_NAME}.lib
    ${CMAKE_CURRENT_BINARY_DIR}/${LIBGIO_NAME}.lib
  )
endif()
