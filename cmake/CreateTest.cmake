function(CreateTest SUBTEST_NAME SUBTEST_SOURCES)
  include_directories(${${PROJ_NAME}_INCLUDE_DIRS})
  link_directories(${${PROJ_NAME}_LINK_DIRS})

  # Don't add resources to source groups yet
  BuildSourceGroup("${SUBTEST_SOURCES}")

  add_executable(${SUBTEST_NAME} ${SUBTEST_SOURCES})
  target_link_libraries(${SUBTEST_NAME} ${PROJ_NAME} GMock::main GTest::main)

  if(${PROJ_NAME}_ENABLE_CLANG_FORMAT)
    add_dependencies(${SUBTEST_NAME} format)
  endif(${PROJ_NAME}_ENABLE_CLANG_FORMAT)

  # Put the test in the Tests folder in IDEs.
  set_target_properties(${SUBTEST_NAME} PROPERTIES FOLDER Tests)

  add_test(Test${SUBTEST_NAME} ${SUBTEST_NAME})
endfunction()
