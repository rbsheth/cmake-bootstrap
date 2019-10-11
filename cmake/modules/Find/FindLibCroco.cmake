# - Try to find LibCroco
# Once done, this will define
#
#  LibCroco_FOUND - system has LibCroco
#  LibCroco_INCLUDE_DIRS - the LibCroco include directories
#  LibCroco_LIBRARIES - link these to use LibCroco
#
# See documentation on how to write CMake scripts at
# http://www.cmake.org/Wiki/CMake:How_To_Find_Libraries

include(LibFindMacros)

libfind_package(LibRSVG LibXML2)

libfind_pkg_check_modules(LibCroco_PKGCONF libcroco-0.6)

find_path(LibCroco_INCLUDE_DIR
  NAMES libcroco/libcroco.h
  PATHS ${LibCroco_PKGCONF_INCLUDE_DIRS}
  PATH_SUFFIXES libcroco-0.6
)

find_library(LibCroco_LIBRARY
  NAMES croco-0.6
  PATHS ${LibCroco_PKGCONF_LIBRARY_DIRS}
)

set(LibCroco_PROCESS_INCLUDES LibCroco_INCLUDE_DIR LibXML2_INCLUDE_DIR)
set(LibCroco_PROCESS_LIBS LibCroco_LIBRARY LibXML2_LIBRARY)
libfind_process(LibCroco)
