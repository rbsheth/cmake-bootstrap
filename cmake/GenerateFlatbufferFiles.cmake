if(IOS OR ANDROID)
  add_executable(flatbuffers::flatc IMPORTED)
  set_property(TARGET flatbuffers::flatc APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
  set_target_properties(flatbuffers::flatc PROPERTIES IMPORTED_LOCATION_RELEASE "${HUNTER_HOST_ROOT}/bin/flatc")

  message(STATUS "Using imported flatc from host: ${HUNTER_HOST_ROOT}/bin/flatc")
endif(IOS OR ANDROID)

# Flatbuffer stuff: Fairly analagous to what we do for the protobuf stuff. We (currently) refer to
# a shared .fbs schema file located in monorepo. This step invokes the flatbuffer compiler
# to generate a corresponding header file for each schema file provided in the target directory.
macro(GenerateFlatbufferFiles)
  set(_OPTIONS_ARGS)
  set(_SINGLE_VALUE_ARGS TARGET DIRECTORY_PREFIX)
  set(_MULTI_VALUE_ARGS FLATBUFFER_FILES)
  cmake_parse_arguments(_GFBF_ARGS "${_OPTIONS_ARGS}" "${_SINGLE_VALUE_ARGS}" "${_MULTI_VALUE_ARGS}" ${ARGN})

  get_filename_component(COMMON_FLATBUFFER_PATH "${_GFBF_ARGS_DIRECTORY_PREFIX}" ABSOLUTE)

  # Specify target directory for generated flatbuffer header file
  set(${PROJ_NAME}_FLATBUFFER_DIR "Flatbuffers")

  foreach(FLATBUFFER_FILE_NAME ${_GFBF_ARGS_FLATBUFFER_FILES})
    set(FLATBUFFER_FILE ${COMMON_FLATBUFFER_PATH}/${FLATBUFFER_FILE_NAME})

    get_filename_component(FLATBUFFER_FILE_ABSOLUTE ${FLATBUFFER_FILE} ABSOLUTE)
    get_filename_component(FLATBUFFER_FILE_BASENAME ${FLATBUFFER_FILE} NAME_WE)
    get_filename_component(FLATBUFFER_FILE_DIR ${FLATBUFFER_FILE} DIRECTORY)

    # Preserve relative paths for each generated header file based on the location of the
    # corresponding .fbs file. E.g. if the schema file was located in COMMON_FLATBUFFER_PATH/foo/bar.fbs
    # we would want to generate the resultant header file ${_GFBF_ARGS_TARGET}_SRC_DIR/Flatbuffers/foo/bar.h
    string(REGEX REPLACE "${COMMON_FLATBUFFER_PATH}" "${${_GFBF_ARGS_TARGET}_FLATBUFFER_DIR}" FLATBUFFER_FILE_DIR "${FLATBUFFER_FILE_DIR}")

    set(${_GFBF_ARGS_TARGET}_FLATBUFFER_GENERATED_DIR_ABSOLUTE
        ${CMAKE_CURRENT_BINARY_DIR}/${_GFBF_ARGS_TARGET}/${FLATBUFFER_FILE_DIR})
    set(${_GFBF_ARGS_TARGET}_FLATBUFFER_GENERATED_FILE_ABSOLUTE
        "${${_GFBF_ARGS_TARGET}_FLATBUFFER_GENERATED_DIR_ABSOLUTE}/${FLATBUFFER_FILE_BASENAME}_generated.h")

    # Add the absolute paths for both the source schema and generated header files
    # to the Lightning source list so they show up in IDEs when added to a
    # source group.
    target_sources(${_GFBF_ARGS_TARGET} PRIVATE ${FLATBUFFER_FILE} ${${_GFBF_ARGS_TARGET}_FLATBUFFER_GENERATED_FILE_ABSOLUTE})

    # Use a Windows-style path for source groups, so that directory structure
    # is preserved.
    string(REPLACE "/" "\\" FLATBUFFER_FILE_DIR ${FLATBUFFER_FILE_DIR})
    source_group("${FLATBUFFER_FILE_DIR}" FILES ${FLATBUFFER_FILE})
    source_group("${FLATBUFFER_FILE_DIR}\\Generated Files" FILES ${${_GFBF_ARGS_TARGET}_FLATBUFFER_GENERATED_FILE_ABSOLUTE})

    # Create output directory if needed
    file(MAKE_DIRECTORY ${${_GFBF_ARGS_TARGET}_FLATBUFFER_GENERATED_DIR_ABSOLUTE})

    # Here we use a custom command that explicitly invokes the flatbuffer compiler executable compiled with hunter.
    # This is why DON'T simply use the FLATBUFFERS_GENERATE_C_HEADERS command (defined here:
    # https://github.com/hunter-packages/flatbuffers/blob/383963f9e6d045cea82482feb807f15f7669ad83/CMake/FindFlatBuffers.cmake#L37)
    # as there are no guarantees for which flatc that function will use.
    add_custom_command(
        OUTPUT ${${_GFBF_ARGS_TARGET}_FLATBUFFER_GENERATED_FILE_ABSOLUTE}
        COMMAND flatbuffers::flatc --cpp -o ${${_GFBF_ARGS_TARGET}_FLATBUFFER_GENERATED_DIR_ABSOLUTE} ${FLATBUFFER_FILE_ABSOLUTE}
        COMMENT "Generating ${FLATBUFFER_FILE_BASENAME}_generated.h from ${FLATBUFFER_FILE}"
        DEPENDS ${FLATBUFFER_FILE}
        VERBATIM
    )
  endforeach()

  # Include the current directory so that include paths like
  # Project/Flatbuffers/Example_generated.h work as intended.
  include_directories(SYSTEM ${CMAKE_CURRENT_BINARY_DIR})
  # Include the Flatbuffers directory because flatc adds subdirectories
  # into the generated .h files.
  include_directories(SYSTEM ${CMAKE_CURRENT_BINARY_DIR}/${_GFBF_ARGS_TARGET}/${${_GFBF_ARGS_TARGET}_FLATBUFFER_DIR})
endmacro()
