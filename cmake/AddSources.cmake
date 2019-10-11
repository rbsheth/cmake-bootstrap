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
#   AddSources(SUB_DIRECTORIES B)
#
# B/CMakeLists.txt
#   AddSources(SOURCE_FILES foo.cpp)
#
# C/CMakeLists.txt
#   AddSources(SOURCE_FILES bar.cpp RESOURCES image.jpg SUB_DIRECTORIES D)
#
# D/CMakeLists.txt
#   AddSources(SOURCE_FILES foobar.cpp)

macro (AddSources)
    set(_OPTIONS_ARGS)
    set(_SINGLE_VALUE_ARGS)
    set(_MULTI_VALUE_ARGS SOURCE_FILES RESOURCE_FILES SUB_DIRECTORIES)
    cmake_parse_arguments(_ADD_SOURCES_ARGS "${_OPTIONS_ARGS}" "${_SINGLE_VALUE_ARGS}" "${_MULTI_VALUE_ARGS}" ${ARGN})

    # Sub-directories are optional. Add any passed in.
    foreach (_SUB_DIR ${_ADD_SOURCES_ARGS_SUB_DIRECTORIES})
        add_subdirectory(${_SUB_DIR})
    endforeach()

    # Source files are optional. Resolve the relative path to the project source directory,
    # and add to the source file list.
    file (RELATIVE_PATH _REL_PATH "${PROJECT_SOURCE_DIR}/src" "${CMAKE_CURRENT_SOURCE_DIR}")
    foreach (_SRC ${_ADD_SOURCES_ARGS_SOURCE_FILES})
        list (APPEND ${SOURCE_GROUP_NAME}_SOURCE_FILES "${_REL_PATH}/${_SRC}")
    endforeach()
    # Resource files are also optional.
    foreach (_RSRC ${_ADD_SOURCES_ARGS_RESOURCE_FILES})
        list (APPEND ${SOURCE_GROUP_NAME}_RESOURCE_FILES "${_REL_PATH}/${_RSRC}")
    endforeach()

    # Take the modified local copy of these lists and propagate it to the parent CMakeLists.txt, if it exists.
    get_directory_property(_HAS_PARENT PARENT_DIRECTORY)
    if(_HAS_PARENT)
      set(${SOURCE_GROUP_NAME}_SOURCE_FILES ${${SOURCE_GROUP_NAME}_SOURCE_FILES} PARENT_SCOPE)
      set(${SOURCE_GROUP_NAME}_RESOURCE_FILES ${${SOURCE_GROUP_NAME}_RESOURCE_FILES} PARENT_SCOPE)
    else()
      set(${SOURCE_GROUP_NAME}_SOURCE_FILES ${${SOURCE_GROUP_NAME}_SOURCE_FILES})
      set(${SOURCE_GROUP_NAME}_RESOURCE_FILES ${${SOURCE_GROUP_NAME}_RESOURCE_FILES})
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
#   SOURCE_FILES
#     foobar.cpp
# )
#
# Translates into: AddSources(SOURCE_FILES foobar.cpp)
#
# But, has no effect when the option is OFF.
# option(USE_SOME_LIB "Use some lib" OFF)
#
# Notes: - CMake option must have ${} to be accessed, and not be treated as a string
#        - Ordering between other AddSources calls in the same file is arbitrary

macro (AddConditionalSources)
    set(_OPTIONS_ARGS)
    set(_SINGLE_VALUE_ARGS CONDITION)
    set(_MULTI_VALUE_ARGS SOURCE_FILES RESOURCE_FILES SUB_DIRECTORIES)
    cmake_parse_arguments(_ADD_COND_SOURCES_ARGS "${_OPTIONS_ARGS}" "${_SINGLE_VALUE_ARGS}" "${_MULTI_VALUE_ARGS}" ${ARGN})

    # Expect the option to be ON or OFF, but must be specified.
    if (NOT DEFINED _ADD_COND_SOURCES_ARGS_CONDITION)
      message(FATAL_ERROR "Requires a CONDITION. None specified.")
    endif()

    if (_ADD_COND_SOURCES_ARGS_CONDITION)
        AddSources(SOURCE_FILES ${_ADD_COND_SOURCES_ARGS_SOURCE_FILES}
                   RESOURCE_FILES ${_ADD_COND_SOURCES_ARGS_RESOURCE_FILES}
                   SUB_DIRECTORIES ${_ADD_COND_SOURCES_ARGS_SUB_DIRECTORIES})
    endif()
endmacro()
