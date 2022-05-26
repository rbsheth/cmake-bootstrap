#!/usr/bin/env python3
import os
import argparse
import re
import subprocess
import sys
import shutil
from enum import Enum
from distutils.version import StrictVersion

SCRIPT_ROOT = os.path.dirname(os.path.abspath(__file__))
POLLY_PATH = os.path.join(SCRIPT_ROOT,  "hunter", "polly")
sys.path.append(os.path.join(POLLY_PATH, 'bin'))
from detail.toolchain_table import get_by_name # noqa

NODEJS_TEMPLATE_PATH = os.path.join(SCRIPT_ROOT, "cmake", "nodejs", "CMakeLists.txt.in")

DEFAULT_CMAKE_FLAGS = '-DHUNTER_STATUS_DEBUG=OFF -DHUNTER_USE_CACHE_SERVERS=YES'

'''
The following data structure maps between command line flags that are supported, and the associated cmake
variable that is used to trigger the behaviour controlled by the flag. Note that the cmake variables are
prefixed downstream.
'''
DESCRIPTION = 'description'
CMAKE_VAR = 'cmake_var'
FLAGS = {
    'with_java': {
        DESCRIPTION: 'Build Java bindings and JNI classes (requires JDK and SWIG)',
        CMAKE_VAR: 'BUILD_JAVA_BINDINGS=ON'
    },
    'with_python': {
        DESCRIPTION: 'Build Python bindings',
        CMAKE_VAR: 'BUILD_PYTHON_BINDINGS=ON'
    },
    'with_node': {
        DESCRIPTION: 'Build Node V8 JS bindings for Node version specified',
        CMAKE_VAR: 'BUILD_JS_V8_BINDINGS=ON'
    },
    'without_projects': {
        DESCRIPTION: 'Disable building of the included projects',
        CMAKE_VAR: 'BUILD_PROJECTS=OFF'
    },
    'build_shared': {
        DESCRIPTION: 'Build shared libraries (.so/.dylib/.dll) instead of static libraries (.a)',
        CMAKE_VAR: 'BUILD_SHARED_LIBS=ON'
    },
    'without_tests': {
        DESCRIPTION: 'Disable building of the included tests',
        CMAKE_VAR: 'BUILD_TESTS=OFF'
    },
    'without_clang_format': {
        DESCRIPTION: 'Disable automatic formatting of code',
        CMAKE_VAR: 'ENABLE_CLANG_FORMAT=OFF'
    },
    'with_clang_tidy': {
        DESCRIPTION: 'Use clang-tidy',
        CMAKE_VAR: 'ENABLE_CLANG_TIDY=OFF'
    },
    'with_iwyu': {
        DESCRIPTION: 'Use Include-What-You-Use',
        CMAKE_VAR: 'ENABLE_IWYU=OFF'
    },
    'with_cuda': {
        DESCRIPTION: 'Enable usage of NVIDIA CUDA',
        CMAKE_VAR: 'ENABLE_CUDA=ON'
    },
    'with_librsvg': {
        DESCRIPTION: 'Enable usage of librsvg and the relevant support functions',
        CMAKE_VAR: 'BUILD_WITH_LIBRSVG_SUPPORT=ON'
    },
    'with_nvsvg': {
        DESCRIPTION: 'Enable usage of nvsvg (NVIDIA Path Rendering)',
        CMAKE_VAR: 'BUILD_WITH_NVSVG_SUPPORT=ON'
    },
    'with_amanithsvg': {
        DESCRIPTION: 'Enable usage of AmanithSVG rendering library',
        CMAKE_VAR: 'BUILD_WITH_AMANITHSVG_SUPPORT=ON'
    },
    'disable_tuning': {
        DESCRIPTION: 'Fallback to tuning for SSE2 instead of newer instruction sets',
        CMAKE_VAR: 'DISABLE_ARCHITECTURE_OPTIMIZATION=ON'
    }
}


# For configurable toolchains, these are the available build configurations.
class Configs(Enum):

    Debug = "Debug"
    Release = "Release"
    RelWithDebInfo = "RelWithDebInfo"
    MinSizeRel = "MinSizeRel"

    def __str__(self):
        return self.name

def getCmakeVersion():
    sp = subprocess.Popen("cmake --version", stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    out, err = sp.communicate()
    versionRegex = re.compile("cmake version\s([0-9\.]*)")

    if out:
        for row in out.split(b'\n'):
            print(row.decode('utf-8'))
            for match in re.finditer(versionRegex, row.decode('utf-8')):
                return match.group(1)

def add_flags_to_parser(parser):
    for flag_name, flag_metadata in FLAGS.items():
        # 'with_java' -> --with-java
        command_line_name = '--' + flag_name.replace('_', '-')

        # Create a parser argument for this flag
        parser.add_argument(command_line_name, help=flag_metadata[DESCRIPTION], action='store_true')


def cmakeWrapper(addParserArguments=None, checkParserArguments=None):
    if(not os.path.isfile("CMakeLists.txt")):
        print("Couldn't find CMakeLists.txt in the current folder. Please run this script from a folder with CMakeLists.txt!")
        exit(1)

    # Try to extract the project name from the CMake file
    projNameRegex = re.compile(r"^set\(PROJ_NAME[\"\ ]*([a-zA-Z0-9\-]*)[\"\ ]*\)$")
    for line in open("CMakeLists.txt", 'r'):
        for match in re.finditer(projNameRegex, line):
            projectName = match.group(1)
            break

    if(projectName is None):
        print("Couldn't find PROJ_NAME in CMakeLists.txt in the current folder. Please double check CMakeLists.txt!")
        exit(1)

    parser = argparse.ArgumentParser(description="Configure script to generate build files for " + projectName + " using CMake.")

    # Toolchain-related arguments.
    parser.add_argument(
        "toolchain",
        help="Toolchain to use to build. Supported toolchain files are found in {}".format(POLLY_PATH),
        type=str)
    parser.add_argument(
        "-c",
        "--config",
        help="Build configuration, applies to non-Xcode/Visual Studio generators. Default is Debug.",
        choices=list(Configs),
        default=Configs.Debug,
        type=Configs
    )
    parser.add_argument(
        "-B", "--build-dir", help="Specify the build directory to use. Default is _builds/<toolchain_name>-<config>")
    parser.add_argument(
        "-ht","--host-toolchain",
        help="Toolchain to use to build for host. Supported toolchain files are found in {}".format(POLLY_PATH),
        type=str)
    parser.add_argument("--clear", help="Delete the toolchain's directory in _builds before configuring.", action='store_true')
    parser.add_argument("--clear-all", help="Delete the _builds directory before configuring.", action='store_true')
    parser.add_argument("--dev", help="Enable development features like debug logging, regardless of build type", action='store_true')

    # On/off flags.
    add_flags_to_parser(parser)
    if(addParserArguments):
        addParserArguments(parser)
    args = parser.parse_args()

    # For every flag that is true, set the appropriate cmake variable.
    project_cmake_arg_list = [
        flag_metadata[CMAKE_VAR] for flag_name, flag_metadata in FLAGS.items() if vars(args)[flag_name]
    ]

    # Add project prefix to each variable.
    additional_cmake_args = ['-D'+ projectName +'_{}'.format(cmake_arg) for cmake_arg in project_cmake_arg_list]
    polly_toolchain = get_by_name(args.toolchain)

    # Situational logic
    if not polly_toolchain.multiconfig:
        additional_cmake_args.append("-DCMAKE_BUILD_TYPE=" + str(args.config))
    elif "emscripten" in polly_toolchain.name:
        additional_cmake_args.append("-DEMSCRIPTEN_FORCE_COMPILERS=ON")
        print("The Emscripten toolchain will not build Java bindings, "
              "shared libraries, projects, or tests, even if selected.")
    if args.host_toolchain:
        polly_host_toolchain = get_by_name(args.host_toolchain)
        additional_cmake_args.append("-DHUNTER_EXPERIMENTAL_HOST_TOOLCHAIN_FILE="+os.path.abspath(os.path.join(POLLY_PATH, polly_host_toolchain.name + '.cmake')))
        additional_cmake_args.append("-DHUNTER_EXPERIMENTAL_HOST_GENERATOR="+polly_host_toolchain.generator)

    # Turn the dev flag on if you have explicitly requested for the dev
    # flag to be on, or if the build type is not explicitly a type of
    # release build. This is useful for not needing to regenerate Xcode
    # projects - they just always default to Dev mode.
    if args.dev or args.config is None or args.config == "Debug":
        additional_cmake_args.append("-D"+projectName+"_DEV=ON")

    if "ios" in polly_toolchain.name or "osx" in polly_toolchain.name:
        if "Xcode" in polly_toolchain.generator:
            # The "new" Xcode buildsystem doesn't work with many Hunter packages
            if StrictVersion("3.19") <= StrictVersion(getCmakeVersion()):
                additional_cmake_args.append("-T buildsystem=1")

    # Use the build dir if set, or create a reasonable default if not.
    build_dir = (
            args.build_dir or
            "_builds/" + polly_toolchain.name + ('-' + str(args.config) if not polly_toolchain.multiconfig else '')
        )

    if checkParserArguments:
        checkParserArguments(args, additional_cmake_args, projectName)

    if args.clear_all:
        if(os.path.isdir("_builds")):
            shutil.rmtree("_builds")
    elif args.clear:
        if(os.path.isdir(build_dir)):
            shutil.rmtree(build_dir)

    os.makedirs(build_dir, exist_ok=True)

    cmake_args = "-G \"{}\" -DCMAKE_TOOLCHAIN_FILE={} {} {}".format(
        polly_toolchain.generator,
        os.path.abspath(os.path.join(POLLY_PATH, polly_toolchain.name + '.cmake')),
        DEFAULT_CMAKE_FLAGS,
        ' '.join(additional_cmake_args)
    )

    if args.with_node:
        print(cmake_args)
    else:
        cmake_call_string = "cmake -H. -B{} {}".format(build_dir, cmake_args)
        sp = subprocess.check_call(cmake_call_string, shell=True)
        return sp

if __name__ == "__main__":
    cmakeWrapper()
