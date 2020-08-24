if(${PROJ_NAME}_BUILD_PYTHON_BINDINGS)
  find_package(PythonLibs REQUIRED)
  include_directories(${PYTHON_INCLUDE_PATH})
endif()

macro(GeneratePythonBindings InterfaceFiles InterfaceFileDependencies)
  # Sets where to place the Python files for the exceptions, data structures and
  # interfaces. Ex. RawModel.py
  # We also clear any existing files to ensure they get re-generated.
  set(CMAKE_SWIG_OUTDIR ${CMAKE_CURRENT_BINARY_DIR}/${PROJ_NAME}Python)
  file(GLOB GENERATED_PYTHON_FILES "${CMAKE_SWIG_OUTDIR}/*.py")
  file(REMOVE "${GENERATED_PYTHON_FILES}")

  set_property(SOURCE ${InterfaceFiles} PROPERTY CPLUSPLUS ON)

  # List of source files that the interface generator depends on.
  set(SWIG_MODULE_${PROJ_NAME}Python_EXTRA_DEPS ${InterfaceFileDependencies})

  # Save the postfixes for restoration later.
  set(SAVED_CMAKE_DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX})
  set(SAVED_CMAKE_RELWITHDEBINFO_POSTFIX ${CMAKE_RELWITHDEBINFO_POSTFIX})
  set(CMAKE_DEBUG_POSTFIX "")
  set(CMAKE_RELWITHDEBINFO_POSTFIX "")

  # Use add_library since add_module was deprecated in cmake 3.8
  swig_add_library(${PROJ_NAME}Python LANGUAGE python SOURCES ${InterfaceFiles})
  swig_link_libraries(${PROJ_NAME}Python ${PROJ_NAME} ${PYTHON_LIBRARIES})

  IF(${PROJ_NAME}_ENABLE_CLANG_FORMAT)
    add_dependencies(${PROJ_NAME}Python format)
  ENDIF()

  set(CMAKE_DEBUG_POSTFIX ${SAVED_CMAKE_DEBUG_POSTFIX})
  set(CMAKE_RELWITHDEBINFO_POSTFIX ${SAVED_CMAKE_RELWITHDEBINFO_POSTFIX})
endmacro()