# A script to make MSVC-compatible lib files for gcc-compiled libraries.
# Useful on Windows only. This script assumes dumpbin.exe and lib.exe are available in the same folder as the current cl.exe.
# If you mix toolchains (x64 host, compile for x86 or vice versa) the tools look for missing DLLs and output empty files.
if(MSVC)
get_filename_component(VSTOOLPATH "${CMAKE_CXX_COMPILER}" DIRECTORY CACHE)
find_program(DUMPBIN_PATH "dumpbin" PATHS ${VSTOOLPATH})
find_program(VSLIB_PATH "lib" PATHS ${VSTOOLPATH})

function(CreateLibFromDll LIBRARY_NAME SOURCE_DLL DESTINATION_FOLDER)
  execute_process(COMMAND ${DUMPBIN_PATH} /exports ${SOURCE_DLL}
                  OUTPUT_VARIABLE ${LIBRARY_NAME}_EXPORTS)
  # Remove garbage in file
  string(REGEX REPLACE ".*RVA[ ]+name(.*)Summary.*" "\\1" ${LIBRARY_NAME}_EXPORTS "${${LIBRARY_NAME}_EXPORTS}")
  # Split output into lines in a list
  string(REGEX REPLACE "\n" ";" ${LIBRARY_NAME}_EXPORTS "${${LIBRARY_NAME}_EXPORTS}")
  set(EXPORT_LIST "EXPORTS\n")
  foreach(EXPORT_LINE ${${LIBRARY_NAME}_EXPORTS})
    string(REGEX REPLACE "[ ]+[0-9]+[ ]+[0-9A-F]+[ ]+[0-9A-F]+[ ]+([0-9a-z_A-Z]+)" "\\1" FOUND_LINE ${EXPORT_LINE})
    set(EXPORT_LIST "${EXPORT_LIST}${FOUND_LINE}\n")
  endforeach()
  set(DEF_PATH ${CMAKE_CURRENT_BINARY_DIR}/${LIBRARY_NAME}.def)
  file(WRITE ${DEF_PATH} "${EXPORT_LIST}")
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(MACHINE_TYPE "X64")
  else()
    set(MACHINE_TYPE "X86")
  endif()
  message("Generating MSVC lib file from ${SOURCE_DLL}")
  execute_process(COMMAND ${VSLIB_PATH} /DEF:${DEF_PATH} /MACHINE:${MACHINE_TYPE} /OUT:${DESTINATION_FOLDER}/${LIBRARY_NAME}.lib
                  OUTPUT_VARIABLE VSLIB_LOGS)
endfunction()
endif(MSVC)
