if(${PROJ_NAME}_BUILD_JAVA_BINDINGS)
  find_package(JNI REQUIRED)
  include_directories(${JNI_INCLUDE_DIRS})

  find_package(Java REQUIRED)
  include(UseJava)
endif()

macro(GenerateJavaBindings InterfaceFiles InterfaceFileDependencies PackageName)
  set(CMAKE_SWIG_FLAGS -package ${PackageName})

  # Sets where to place the Java files for the exceptions, data structures and
  # interfaces. Ex. StringVector.java
  # We also clear any existing files to ensure they get re-generated.
  set(CMAKE_SWIG_OUTDIR ${CMAKE_CURRENT_BINARY_DIR}/${PROJ_NAME}Java)
  file(GLOB GENERATED_JAVA_FILES "${CMAKE_SWIG_OUTDIR}/*.java")
  file(REMOVE "${GENERATED_JAVA_FILES}")

  set_property(SOURCE ${InterfaceFiles} PROPERTY CPLUSPLUS ON)

  # List of source files that the interface generator depends on.
  set(SWIG_MODULE_${PROJ_NAME}JAVA_EXTRA_DEPS ${InterfaceFileDependencies})

  # Use add_library since add_module was deprecated in cmake 3.8
  swig_add_library(${PROJ_NAME}Java LANGUAGE java SOURCES ${InterfaceFiles})
  swig_link_libraries(${PROJ_NAME}Java ${PROJ_NAME})
  IF(UNIX)
    SET_TARGET_PROPERTIES(${SWIG_MODULE_${PROJ_NAME}JAVA_REAL_NAME} PROPERTIES
     PREFIX "lib")
    IF(APPLE)
      # Avoid ".jnilib" suffix
      SET_TARGET_PROPERTIES(${SWIG_MODULE_${PROJ_NAME}JAVA_REAL_NAME} PROPERTIES
        SUFFIX ".dylib")
    ENDIF(APPLE)
  ENDIF(UNIX)

  IF(${PROJ_NAME}_ENABLE_CLANG_FORMAT)
    add_dependencies(${PROJ_NAME}Java format)
  ENDIF()

  # Variable to control where to place the generated Java bytecode *.class
  # files, like RequestData.class
  # We also clear any existing files/subdirectories to ensure they get
  # regenerated.
  set(JAVA_CLASSES_OUTDIR ${CMAKE_CURRENT_BINARY_DIR}/${PROJ_NAME}Java-Classes)
  file(REMOVE_RECURSE ${JAVA_CLASSES_OUTDIR})
  file(MAKE_DIRECTORY ${JAVA_CLASSES_OUTDIR})

  add_custom_command(TARGET ${PROJ_NAME}Java POST_BUILD
    COMMAND ${CMAKE_COMMAND} -DPROJ_NAME=${PROJ_NAME}
                             -D${PROJ_NAME}_BUILD_SHARED_LIBS=${${PROJ_NAME}_BUILD_SHARED_LIBS}
                             -D${PROJ_NAME}_FILE_NAME=$<TARGET_FILE_NAME:${PROJ_NAME}>
                             -D${PROJ_NAME}JAVA_FILE_NAME=$<TARGET_FILE_NAME:${PROJ_NAME}Java>
                             -D${PROJ_NAME}JAVA_JNI_FILE=${CMAKE_SWIG_OUTDIR}/${PROJ_NAME}JNI.java
                             -P ${${PROJ_NAME}_ROOT_DIR}/../cmake/bootstrap/cmake/java/ConfigureJNILibraryName.cmake
    COMMAND "${Java_JAVAC_EXECUTABLE}" -d ${JAVA_CLASSES_OUTDIR}
                                          ${${PROJ_NAME}_ROOT_DIR}/../cmake/bootstrap/cmake/java/NativeUtils.java
    COMMAND "${Java_JAVAC_EXECUTABLE}" -cp ${JAVA_CLASSES_OUTDIR}
                                        -d ${JAVA_CLASSES_OUTDIR}
                                           ${CMAKE_SWIG_OUTDIR}/*.java
    COMMAND "${Java_JAR_EXECUTABLE}" -cfM ${PROJ_NAME}-${CMAKE_SYSTEM}.jar
                                     -C ${JAVA_CLASSES_OUTDIR} .
                                     -C $<TARGET_FILE_DIR:${PROJ_NAME}Java> $<TARGET_FILE_NAME:${PROJ_NAME}Java>
                                     $<$<BOOL:${${PROJ_NAME}_BUILD_SHARED_LIBS}>:-C\ $<TARGET_FILE_DIR:${PROJ_NAME}>\ $<TARGET_FILE_NAME:${PROJ_NAME}>>
    COMMAND ${CMAKE_COMMAND} -E copy ${PROJ_NAME}-${CMAKE_SYSTEM}.jar ${PROJ_NAME}-$<PLATFORM_ID>-$<CONFIG>.jar
  )

  set(${PROJ_NAME}_JAR_FILE ${CMAKE_CURRENT_BINARY_DIR}/${PROJ_NAME}-${CMAKE_SYSTEM}.jar PARENT_SCOPE)
  set(CMAKE_SWIG_FLAGS "")
endmacro()