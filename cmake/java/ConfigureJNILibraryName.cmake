string(REGEX REPLACE ".*(${PROJ_NAME}[^\\.]*)\\..*" "\\1" ${PROJ_NAME}_LIBRARY_NAME "${${PROJ_NAME}_FILE_NAME}")
string(REGEX REPLACE ".*(${PROJ_NAME}Java[^\\.]*)\\..*" "\\1" ${PROJ_NAME}JAVA_LIBRARY_NAME "${${PROJ_NAME}JAVA_FILE_NAME}")

if(${PROJ_NAME}_BUILD_SHARED_LIBS)
  set(${PROJ_NAME}_JNI_CONFIG_STRING "NativeUtils.loadLibraryFromJar(\"/\"+System.mapLibraryName(\"${${PROJ_NAME}_LIBRARY_NAME}\"));\n      NativeUtils.loadLibraryFromJar(\"/\"+System.mapLibraryName(\"${${PROJ_NAME}JAVA_LIBRARY_NAME}\"));")
else()
  set(${PROJ_NAME}_JNI_CONFIG_STRING "NativeUtils.loadLibraryFromJar(\"/\"+System.mapLibraryName(\"${${PROJ_NAME}JAVA_LIBRARY_NAME}\"));")
endif()

configure_file(${${PROJ_NAME}JAVA_JNI_FILE} ${${PROJ_NAME}JAVA_JNI_FILE})
