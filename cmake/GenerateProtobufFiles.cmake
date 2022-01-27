macro(ImportProtobufHostCompiler)
  if(NOT TARGET protobuf::protoc)
    add_executable(protobuf::protoc IMPORTED)
  endif()
  set_property(TARGET protobuf::protoc APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
  set_target_properties(protobuf::protoc PROPERTIES IMPORTED_LOCATION_RELEASE "${HUNTER_HOST_ROOT}/bin/protoc")

  message(STATUS "Using imported protoc from host: ${HUNTER_HOST_ROOT}/bin/protoc")
endmacro()

macro(ImportGrpcHostPlugins)
  foreach(LANG IN ITEMS cpp csharp node objective_c php python ruby)
    if(NOT TARGET gRPC::grpc_${LANG}_plugin)
      add_executable(gRPC::grpc_${LANG}_plugin IMPORTED)
    endif()
    set_property(TARGET gRPC::grpc_${LANG}_plugin APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
    find_program(GRPC_${LANG}_HOST_PLUGIN_LOCATION grpc_${LANG}_plugin PATHS "${HUNTER_HOST_ROOT}/bin/" NO_DEFAULT_PATH REQUIRED)
    set_target_properties(gRPC::grpc_${LANG}_plugin PROPERTIES IMPORTED_LOCATION_RELEASE "${GRPC_${LANG}_HOST_PLUGIN_LOCATION}")
  endforeach()

  message(STATUS "Using imported gRPC plugins from host: ${HUNTER_HOST_ROOT}/bin/grpc_*_plugin")
endmacro()

macro(GenerateProtobufFiles)
  set(_OPTIONS_ARGS)
  set(_SINGLE_VALUE_ARGS TARGET DIRECTORY_PREFIX)
  set(_MULTI_VALUE_ARGS PROTO_FILES GRPC_PROTO_FILES LANGUAGES)
  cmake_parse_arguments(_GPBF_ARGS "${_OPTIONS_ARGS}" "${_SINGLE_VALUE_ARGS}" "${_MULTI_VALUE_ARGS}" ${ARGN})

  # Protobuf summary: Take all .proto files, use the protoc compiler to generate
  # .cpp and .h files, and then add them to the project source files list.
  # It's very helpful to have both the .proto and C++ files available in the
  # IDE, so add them to a source group folder as well.

  # Use a relative path to the common proto directory. The path needs to
  # be converted to absolute otherwise protoc will complain.
  get_filename_component(COMMON_PROTO_PATH "${_GPBF_ARGS_DIRECTORY_PREFIX}" ABSOLUTE)

  # Set where the generated pb.cc/h files will live in the build tree.
  set(${_GPBF_ARGS_TARGET}_PROTO_DIR "Proto")

  # Make the output directory in case it doesn't exist so that protoc doesn't
  # fail.
  file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${_GPBF_ARGS_TARGET}/${${_GPBF_ARGS_TARGET}_PROTO_DIR})

  foreach(PROTO_FILE_NAME ${_GPBF_ARGS_PROTO_FILES} ${_GPBF_ARGS_GRPC_PROTO_FILES})
    set(PROTO_FILE ${COMMON_PROTO_PATH}/${PROTO_FILE_NAME})

    get_filename_component(PROTO_FILE_ABSOLUTE ${PROTO_FILE} ABSOLUTE)
    get_filename_component(PROTO_FILE_BASENAME ${PROTO_FILE} NAME_WE)
    get_filename_component(PROTO_FILE_DIR ${PROTO_FILE} DIRECTORY)

    # Replace the absolute path prefix to the proto with the project-specific
    # prefix so that the source proto and generated files appear in the correct
    # place in the source tree within an IDE and the build directory.
    string(REGEX REPLACE "${COMMON_PROTO_PATH}" "${${_GPBF_ARGS_TARGET}_PROTO_DIR}" PROTO_FILE_DIR "${PROTO_FILE_DIR}")

    if("CXX" IN_LIST _GPBF_ARGS_LANGUAGES)
      set(${_GPBF_ARGS_TARGET}_PROTO_GENERATED_FILES_ABSOLUTE
        ${CMAKE_CURRENT_BINARY_DIR}/${_GPBF_ARGS_TARGET}/${PROTO_FILE_DIR}/${PROTO_FILE_BASENAME}.pb.cc
        ${CMAKE_CURRENT_BINARY_DIR}/${_GPBF_ARGS_TARGET}/${PROTO_FILE_DIR}/${PROTO_FILE_BASENAME}.pb.h)

      # Add the absolute paths to the proto source and generated files
      # to the project source list so they show up in IDEs when added to a
      # source group.
      target_sources(${_GPBF_ARGS_TARGET} PRIVATE ${PROTO_FILE} ${${_GPBF_ARGS_TARGET}_PROTO_GENERATED_FILES_ABSOLUTE})

      # Use a Windows-style path for source groups, so that directory structure
      # is preserved.
      string(REPLACE "/" "\\" PROTO_FILE_DIR ${PROTO_FILE_DIR})
      source_group("${PROTO_FILE_DIR}" FILES ${PROTO_FILE})
      source_group("${PROTO_FILE_DIR}\\Generated Files" FILES ${${_GPBF_ARGS_TARGET}_PROTO_GENERATED_FILES_ABSOLUTE})

      # Use a custom command instead of protobuf_generate_cpp because we need
      # to force usage of the hunter-based protoc compiler. Output the files to
      # the project build directory, and make sure CMake knows these are
      # generated files that might not exist at configure time.
      add_custom_command(
        OUTPUT ${${_GPBF_ARGS_TARGET}_PROTO_GENERATED_FILES_ABSOLUTE}
        COMMAND protobuf::protoc --cpp_out ${CMAKE_CURRENT_BINARY_DIR}/${_GPBF_ARGS_TARGET}/${${_GPBF_ARGS_TARGET}_PROTO_DIR} -I ${COMMON_PROTO_PATH} ${PROTO_FILE_ABSOLUTE}
        COMMENT "Generating ${PROTO_FILE_BASENAME}.pb.h/cc from ${PROTO_FILE}"
        DEPENDS ${PROTO_FILE}
        VERBATIM
      )

      # Run the protoc compiler again with the gRPC plugin for gRPC files.
      if(PROTO_FILE_NAME IN_LIST _GPBF_ARGS_GRPC_PROTO_FILES)
        set(${_GPBF_ARGS_TARGET}_GRPC_PROTO_GENERATED_FILES_ABSOLUTE
          ${CMAKE_CURRENT_BINARY_DIR}/${_GPBF_ARGS_TARGET}/${PROTO_FILE_DIR}/${PROTO_FILE_BASENAME}.grpc.pb.cc
          ${CMAKE_CURRENT_BINARY_DIR}/${_GPBF_ARGS_TARGET}/${PROTO_FILE_DIR}/${PROTO_FILE_BASENAME}.grpc.pb.h)
        target_sources(${_GPBF_ARGS_TARGET} PRIVATE ${${_GPBF_ARGS_TARGET}_GRPC_PROTO_GENERATED_FILES_ABSOLUTE})
        source_group("${PROTO_FILE_DIR}\\Generated Files" FILES ${${_GPBF_ARGS_TARGET}_GRPC_PROTO_GENERATED_FILES_ABSOLUTE})
        add_custom_command(
          OUTPUT ${${_GPBF_ARGS_TARGET}_GRPC_PROTO_GENERATED_FILES_ABSOLUTE}
          COMMAND protobuf::protoc --grpc_out ${CMAKE_CURRENT_BINARY_DIR}/${_GPBF_ARGS_TARGET}/${${_GPBF_ARGS_TARGET}_PROTO_DIR} -I ${COMMON_PROTO_PATH} --plugin=protoc-gen-grpc=$<TARGET_FILE:gRPC::grpc_cpp_plugin> ${PROTO_FILE_ABSOLUTE}
          COMMENT "Generating ${PROTO_FILE_BASENAME}.grpc.pb.h/cc from gRPC-enabled ${PROTO_FILE}"
          DEPENDS ${PROTO_FILE}
          VERBATIM
        )
      endif()
    endif()

    # Generate Python files if requested
    if("Python" IN_LIST _GPBF_ARGS_LANGUAGES)
      set(${_GPBF_ARGS_TARGET}_PYTHON_PROTO_GENERATED_FILES_ABSOLUTE
        ${CMAKE_CURRENT_BINARY_DIR}/${_GPBF_ARGS_TARGET}/${PROTO_FILE_DIR}/${PROTO_FILE_BASENAME}_pb2.py)
      target_sources(${_GPBF_ARGS_TARGET} PRIVATE ${${_GPBF_ARGS_TARGET}_PYTHON_PROTO_GENERATED_FILES_ABSOLUTE})
      source_group("${PROTO_FILE_DIR}\\Generated Files" FILES ${${_GPBF_ARGS_TARGET}_PYTHON_PROTO_GENERATED_FILES_ABSOLUTE})
      add_custom_command(
        OUTPUT ${${_GPBF_ARGS_TARGET}_PYTHON_PROTO_GENERATED_FILES_ABSOLUTE}
        COMMAND protobuf::protoc --python_out ${CMAKE_CURRENT_BINARY_DIR}/${_GPBF_ARGS_TARGET}/${${_GPBF_ARGS_TARGET}_PROTO_DIR} -I ${COMMON_PROTO_PATH} ${PROTO_FILE_ABSOLUTE}
        COMMENT "Generating ${PROTO_FILE_BASENAME}_pb2.py from ${PROTO_FILE}"
        DEPENDS ${PROTO_FILE}
        VERBATIM
      )
      if(PROTO_FILE_NAME IN_LIST _GPBF_ARGS_GRPC_PROTO_FILES)
        set(${_GPBF_ARGS_TARGET}_PYTHON_GRPC_PROTO_GENERATED_FILES_ABSOLUTE
          ${CMAKE_CURRENT_BINARY_DIR}/${_GPBF_ARGS_TARGET}/${PROTO_FILE_DIR}/${PROTO_FILE_BASENAME}_pb2_grpc.py)
        target_sources(${_GPBF_ARGS_TARGET} PRIVATE ${${_GPBF_ARGS_TARGET}_PYTHON_GRPC_PROTO_GENERATED_FILES_ABSOLUTE})
        source_group("${PROTO_FILE_DIR}\\Generated Files" FILES ${${_GPBF_ARGS_TARGET}_PYTHON_GRPC_PROTO_GENERATED_FILES_ABSOLUTE})
        add_custom_command(
          OUTPUT ${${_GPBF_ARGS_TARGET}_PYTHON_GRPC_PROTO_GENERATED_FILES_ABSOLUTE}
          COMMAND protobuf::protoc --grpc_out ${CMAKE_CURRENT_BINARY_DIR}/${_GPBF_ARGS_TARGET}/${${_GPBF_ARGS_TARGET}_PROTO_DIR} -I ${COMMON_PROTO_PATH} --plugin=protoc-gen-grpc=$<TARGET_FILE:gRPC::grpc_python_plugin> ${PROTO_FILE_ABSOLUTE}
          COMMENT "Generating ${PROTO_FILE_BASENAME}_pb2_grpc.py from gRPC-enabled ${PROTO_FILE}"
          DEPENDS ${PROTO_FILE}
          VERBATIM
        )
      endif()
    endif()
  endforeach()

  if("CXX" IN_LIST _GPBF_ARGS_LANGUAGES)
    # Include the current directory so that include paths like
    # Project/Proto/Example.pb.h work as intended.
    include_directories(SYSTEM ${CMAKE_CURRENT_BINARY_DIR})
    # Include the Proto directory because protoc adds subdirectories
    # into the generated .pb.h/cc files.
    include_directories(SYSTEM ${CMAKE_CURRENT_BINARY_DIR}/${_GPBF_ARGS_TARGET}/${${_GPBF_ARGS_TARGET}_PROTO_DIR})
  endif()
endmacro()
