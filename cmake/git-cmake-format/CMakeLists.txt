project(git-clang-format-cmake)
cmake_minimum_required(VERSION 2.8)

# set(GCF_GIT_PATH "NOTSET" CACHE STRING "Absolute path to the git executable")
# set(GCF_PYTHON_NAME "python" CACHE STRING "Name of the python executable, eg. python2")
# set(GCF_PYTHON_PATH "NOTSET" CACHE STRING "Absolute path to the python executable")
# set(GCF_CLANGFORMAT_PATH "NOTSET" CACHE STRING "Absolute path to the clang-format executable")
# set(GCF_CLANGFORMAT_STYLE "file" CACHE STRING "Parameter pass to clang-format -style=<here>")
# set(GCF_IGNORE_LIST "") # CACHE STRING "Semi colon separated list of directories to ignore")

# if("${GCF_GIT_PATH}" STREQUAL "NOTSET")
# 	find_program(FIND_GIT git)
# 	if("${FIND_GIT}" STREQUAL "FIND_GIT-NOTFOUND")
# 		message(FATAL_ERROR "Could not find 'git' please set GCF_GIT_PATH:STRING")
# 	else()
# 		set(GCF_GIT_PATH ${FIND_GIT})
# 		message(STATUS "Found: ${GCF_GIT_PATH}")
# 	endif()
# else()
# 	if(NOT EXISTS ${GCF_GIT_PATH})
# 		message(WARNING "Could not find git: ${GCF_GIT_PATH}")
# 	else()
# 		message(STATUS "Found: ${GCF_GIT_PATH}")
# 	endif()
# endif()

# if("${GCF_PYTHON_PATH}" STREQUAL "NOTSET")
# 	find_program(FIND_PYTHON ${GCF_PYTHON_NAME})
# 	if("${FIND_PYTHON}" STREQUAL "FIND_PYTHON-NOTFOUND")
# 		message(FATAL_ERROR "Could not find '${GCF_PYTHON_NAME}' please set GCF_PYTHON_PATH:STRING")
# 	else()
# 		set(GCF_PYTHON_PATH ${FIND_PYTHON})
# 		message(STATUS "Found: ${GCF_PYTHON_PATH}")
# 	endif()
# else()
# 	if(NOT EXISTS ${GCF_PYTHON_PATH})
# 		message(WARNING "Could not find python: ${GCF_PYTHON_PATH}")
# 	else()
# 		message(STATUS "Found: ${GCF_PYTHON_PATH}")
# 	endif()
# endif()

# if("${GCF_CLANGFORMAT_PATH}" STREQUAL "NOTSET")
# 	find_program(FIND_CLANGFORMAT clang-format)
# 	if("${FIND_CLANGFORMAT}" STREQUAL "FIND_CLANGFORMAT-NOTFOUND")
# 		message(FATAL_ERROR "Could not find 'clang-format' please set GCF_CLANGFORMAT_PATH:STRING")
# 	else()
# 		set(GCF_CLANGFORMAT_PATH ${FIND_CLANGFORMAT})
# 		message(STATUS "Found: ${GCF_CLANGFORMAT_PATH}")
# 	endif()
# else()
# 	if(NOT EXISTS ${GCF_CLANGFORMAT_PATH})
# 		message(WARNING "Could not find clang-format: ${GCF_CLANGFORMAT_PATH}")
# 	else()
# 		message(STATUS "Found: ${GCF_CLANGFORMAT_PATH}")
# 	endif()
# endif()

# set(GCF_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/git-cmake-format.py)
# string(REGEX REPLACE "\\\\" "/" GCF_GIT_PATH ${GCF_GIT_PATH})
# string(REGEX REPLACE "\\\\" "/" GCF_PYTHON_PATH ${GCF_PYTHON_PATH})
# string(REGEX REPLACE "\\\\" "/" GCF_CLANGFORMAT_PATH ${GCF_CLANGFORMAT_PATH})

execute_process(COMMAND git rev-parse --show-toplevel
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  OUTPUT_VARIABLE GCF_GIT_ROOT
  OUTPUT_STRIP_TRAILING_WHITESPACE)
if(NOT GCF_GIT_ROOT)
  message(WARNING "Not in a git repository")
else()
  message(STATUS "Found git root: ${GCF_GIT_ROOT}")
endif()

file(RELATIVE_PATH GCF_SCRIPT ${GCF_GIT_ROOT}/.git/ ${CMAKE_CURRENT_SOURCE_DIR}/git-cmake-format.py)
set(GCF_SCRIPT "$GIT_DIR/${GCF_SCRIPT}")

# configure_file(
# 	${CMAKE_CURRENT_SOURCE_DIR}/git-pre-commit-hook
#   ${GCF_GIT_ROOT}/.git/hooks/pre-commit)

add_custom_target(format
	${GCF_PYTHON_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/git-cmake-format.py --cmake ${GCF_GIT_PATH} ${GCF_CLANGFORMAT_PATH} -style=${GCF_CLANGFORMAT_STYLE} -ignore="${GCF_IGNORE_LIST}"
	WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
