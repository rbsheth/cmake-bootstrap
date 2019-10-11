function(BuildSourceGroup SOURCE_FILES) # REMOVE_PREFIX
  foreach(FILE ${SOURCE_FILES})
    get_filename_component(PARENT_DIR "${FILE}" PATH)

    set(extra_args ${ARGN})
    list(LENGTH extra_args num_extra_args)

    if(${num_extra_args} GREATER 0)
      list(GET extra_args 0 REMOVE_PREFIX)
      string(REGEX REPLACE "${REMOVE_PREFIX}[\/]*" "" PARENT_DIR "${PARENT_DIR}")
    endif()
    
    # skip src or include and changes /'s to \\'s
    string(REGEX REPLACE "(\\./)?(src|include)/?" "" GROUP "${PARENT_DIR}")
    string(REPLACE "/" "\\" GROUP "${GROUP}")

    source_group("${GROUP}" FILES "${FILE}")
  endforeach()
endfunction()
