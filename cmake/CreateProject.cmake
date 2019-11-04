function(CreateProject SUBPROJECT_NAME SUBPROJECT_SOURCES SUBPROJECT_RESOURCES)
  include_directories(${${PROJ_NAME}_INCLUDE_DIRS})
  link_directories(${${PROJ_NAME}_LINK_DIRS})

  if(_is_ios OR _is_ios_sim)
    set(RESOURCES ${SUBPROJECT_RESOURCES})
  endif()

  # Don't add resources to source groups yet
  BuildSourceGroup("${SUBPROJECT_SOURCES}")

  set(SUBPROJECT_SOURCES ${SUBPROJECT_SOURCES} ${RESOURCES})

  add_executable(${SUBPROJECT_NAME} ${SUBPROJECT_SOURCES})
  target_link_libraries(${SUBPROJECT_NAME} ${PROJ_NAME})

  if(${PROJ_NAME}_ENABLE_CLANG_FORMAT)
    add_dependencies(${SUBPROJECT_NAME} format)
  endif(${PROJ_NAME}_ENABLE_CLANG_FORMAT)

  # Put the project in the Projects folder in IDEs.
  set_target_properties(${SUBPROJECT_NAME} PROPERTIES FOLDER Projects)
  # Get rid of link warning for MSVC
  if(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
    set_target_properties(${SUBPROJECT_NAME} PROPERTIES LINK_FLAGS "/ignore:4099")
  endif()

  if(_is_ios OR _is_ios_sim)
    # TODO(rbsheth): Pass in bundle identifier here
    set_target_properties(${SUBPROJECT_NAME} PROPERTIES
      MACOSX_BUNDLE_BUNDLE_NAME "${SUBPROJECT_NAME}"
      MACOSX_BUNDLE_GUI_IDENTIFIER "com.example.${SUBPROJECT_NAME}"
      MACOSX_BUNDLE_INFO_PLIST ${${PROJ_NAME}_ROOT_DIR}/cmake/MacOSXBundleInfo.plist.in
      RESOURCE "${RESOURCES}")
  else()
    set_target_properties(${SUBPROJECT_NAME} PROPERTIES DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX} RELWITHDEBINFO_POSTFIX ${CMAKE_RELWITHDEBINFO_POSTFIX})
    INSTALL(TARGETS ${SUBPROJECT_NAME} DESTINATION ${${PROJ_NAME}_ROOT_DIR}/bin)
  endif()
endfunction()

function(CreateJavaProject SUBPROJECT_NAME SUBPROJECT_SOURCES SUBPROJECT_ENTRY_POINT)
  find_package(Java REQUIRED)
  include(UseJava)

  add_jar(${SUBPROJECT_NAME} ${SUBPROJECT_SOURCES} INCLUDE_JARS ${${PROJ_NAME}_JAR_FILE} ENTRY_POINT ${SUBPROJECT_ENTRY_POINT})
  get_target_property(${SUBPROJECT_NAME}_JAR_FILE ${SUBPROJECT_NAME} JAR_FILE)
  # ${PROJ_NAME}JNI is dependent on format, don't need to add the dependency again.
  add_dependencies(${SUBPROJECT_NAME} ${PROJ_NAME}Java)

  # Windows uses a semicolon to delimit class paths, whereas other platforms use a colon.
  add_test(NAME Run${SUBPROJECT_NAME}
           COMMAND ${Java_JAVA_EXECUTABLE} -cp ${${PROJ_NAME}_JAR_FILE}$<IF:$<PLATFORM_ID:Windows>,$<SEMICOLON>,":">${${SUBPROJECT_NAME}_JAR_FILE} ${SUBPROJECT_ENTRY_POINT})

  # Put the "test" in the Projects folder in IDEs.
  set_target_properties(${SUBPROJECT_NAME} PROPERTIES FOLDER Projects)
endfunction()
