# Use to add sources, resources, and sub-directories to the source
# list of a project. Populates the ${SOURCE_GROUP_NAME}_SOURCE_FILES variable.
# Example usage:
#
# - A/
#   - B/
#     - foo.cpp
#   - C/
#     - bar.cpp
#     - image.jpg
#     - D/
#        - foobar.cpp
#
# A/CMakeLists.txt:
#   AddSources(TARGET mylib SUB_DIRECTORIES B)
#
# B/CMakeLists.txt
#   AddSources(TARGET mylib C_SOURCE_FILES bar.c CXX_SOURCE_FILES foo.cpp)
#
# C/CMakeLists.txt
#   AddSources(TARGET mylib CXX_SOURCE_FILES bar.cpp RESOURCE_FILES image.jpg SUB_DIRECTORIES D)
#
# D/CMakeLists.txt
#   AddSources(TARGET mylib CXX_SOURCE_FILES foobar.cpp)

macro(AddSources)
    set(_OPTIONS_ARGS)
    set(_SINGLE_VALUE_ARGS)
    set(_MULTI_VALUE_ARGS TARGET C_HEADER_FILES C_SOURCE_FILES CXX_HEADER_FILES CXX_SOURCE_FILES CUDA_SOURCE_FILES RESOURCE_FILES SUB_DIRECTORIES DIRECTORY_PREFIX)
    cmake_parse_arguments(_ADD_SOURCES_ARGS "${_OPTIONS_ARGS}" "${_SINGLE_VALUE_ARGS}" "${_MULTI_VALUE_ARGS}" ${ARGN})

    if(_ADD_SOURCES_ARGS_TARGET)
      set(_ADD_SOURCES_TARGET_NAME ${_ADD_SOURCES_ARGS_TARGET})
    endif()
    if(_ADD_SOURCES_ARGS_DIRECTORY_PREFIX)
      set(_ADD_SOURCES_DIRECTORY_PREFIX ${_ADD_SOURCES_ARGS_DIRECTORY_PREFIX})
    endif()

    # Source files are optional. Resolve the relative path to the project source directory,
    # and add to the source file list.
    unset(_ADD_SOURCES_ALL_SOURCE_FILES)
    list(APPEND _ADD_SOURCES_ALL_SOURCE_FILES ${_ADD_SOURCES_ARGS_C_HEADER_FILES}
                                              ${_ADD_SOURCES_ARGS_C_SOURCE_FILES}
                                              ${_ADD_SOURCES_ARGS_CXX_HEADER_FILES}
                                              ${_ADD_SOURCES_ARGS_CXX_SOURCE_FILES}
                                              ${_ADD_SOURCES_ARGS_CUDA_SOURCE_FILES})
    list(SORT _ADD_SOURCES_ALL_SOURCE_FILES)
    foreach (_SRC ${_ADD_SOURCES_ALL_SOURCE_FILES})
        if(NOT _ADD_SOURCES_TARGET_NAME)
          message(FATAL_ERROR "AddSources was not given a valid TARGET!")
        endif()
        set(_ABS_SRC_PATH ${CMAKE_CURRENT_LIST_DIR}/${_SRC})
        target_sources(${_ADD_SOURCES_TARGET_NAME} PRIVATE "${_ABS_SRC_PATH}")
        source_group(TREE "${_ADD_SOURCES_DIRECTORY_PREFIX}" FILES "${_ABS_SRC_PATH}")
        list(FIND _ADD_SOURCES_ARGS_CUDA_SOURCE_FILES "${_SRC}" _ADD_SOURCES_IS_CUDA_FILE)
        if(NOT _ADD_SOURCES_IS_CUDA_FILE EQUAL -1)
          # CUDA files need a property added if their extensions are not .cu
          set_source_files_properties("${_ABS_SRC_PATH}" PROPERTIES LANGUAGE CUDA)
        endif()
    endforeach()
    # Resource files are optional.
    list(SORT _ADD_SOURCES_ARGS_RESOURCE_FILES)
    foreach (_RSRC ${_ADD_SOURCES_ARGS_RESOURCE_FILES})
        set(_ABS_RSRC_PATH ${CMAKE_CURRENT_LIST_DIR}/${_RSRC})
        list(APPEND ${_ADD_SOURCES_TARGET_NAME}_RESOURCE_FILES "${_ABS_RSRC_PATH}")
    endforeach()

    # Sub-directories are optional. Add any passed in.
    foreach (_SUB_DIR ${_ADD_SOURCES_ARGS_SUB_DIRECTORIES})
        include(${CMAKE_CURRENT_LIST_DIR}/${_SUB_DIR}/Sources.cmake)
    endforeach()

    # Take the modified local copy of these lists and propagate it to the parent CMakeLists.txt, if it exists.
    get_directory_property(_HAS_PARENT PARENT_DIRECTORY)
    if(_HAS_PARENT)
      set(${_ADD_SOURCES_TARGET_NAME}_RESOURCE_FILES ${${_ADD_SOURCES_TARGET_NAME}_RESOURCE_FILES} PARENT_SCOPE)
    else()
      set(${_ADD_SOURCES_TARGET_NAME}_RESOURCE_FILES ${${_ADD_SOURCES_TARGET_NAME}_RESOURCE_FILES})
    endif()
endmacro()

# A simple wrapper around AddSources. Used to add sources only when a CMake option is ON.
# Ex.
#
# option(USE_SOME_LIB "Use some lib" ON)
#
# ...
#
# AddConditionalSources(
#   CONDITION
#     ${USE_SOME_LIB}
#   CXX_SOURCE_FILES
#     foobar.cpp
# )
#
# Translates into: AddSources(CXX_SOURCE_FILES foobar.cpp)
#
# But, has no effect when the option is OFF.
# option(USE_SOME_LIB "Use some lib" OFF)
#
# Notes: - CMake option must have ${} to be accessed, and not be treated as a string
#        - Ordering between other AddSources calls in the same file is arbitrary

macro(AddConditionalSources)
    set(_OPTIONS_ARGS)
    set(_SINGLE_VALUE_ARGS CONDITION)
    set(_MULTI_VALUE_ARGS C_HEADER_FILES C_SOURCE_FILES CXX_HEADER_FILES CXX_SOURCE_FILES CUDA_SOURCE_FILES RESOURCE_FILES SUB_DIRECTORIES)
    cmake_parse_arguments(_ADD_COND_SOURCES_ARGS "${_OPTIONS_ARGS}" "${_SINGLE_VALUE_ARGS}" "${_MULTI_VALUE_ARGS}" ${ARGN})

    # Expect the option to be ON or OFF, but must be specified.
    if (NOT DEFINED _ADD_COND_SOURCES_ARGS_CONDITION)
      message(FATAL_ERROR "Requires a CONDITION. None specified.")
    endif()

    if (_ADD_COND_SOURCES_ARGS_CONDITION)
        AddSources(C_HEADER_FILES ${_ADD_COND_SOURCES_ARGS_C_HEADER_FILES}
                   C_SOURCE_FILES ${_ADD_COND_SOURCES_ARGS_C_SOURCE_FILES}
                   CXX_HEADER_FILES ${_ADD_COND_SOURCES_ARGS_CXX_HEADER_FILES}
                   CXX_SOURCE_FILES ${_ADD_COND_SOURCES_ARGS_CXX_SOURCE_FILES}
                   CUDA_SOURCE_FILES ${_ADD_COND_SOURCES_ARGS_CUDA_SOURCE_FILES}
                   RESOURCE_FILES ${_ADD_COND_SOURCES_ARGS_RESOURCE_FILES}
                   SUB_DIRECTORIES ${_ADD_COND_SOURCES_ARGS_SUB_DIRECTORIES})
    endif()
endmacro()
