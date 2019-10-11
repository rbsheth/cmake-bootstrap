#!/usr/bin/env python
import sys
import errno
import os
import argparse
import shutil
import subprocess
import re

def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

#Function from: http://stackoverflow.com/questions/3853722/python-argparse-how-to-insert-newline-in-the-help-text
class SmartFormatter(argparse.HelpFormatter):
    def _split_lines(self, text, width):
        if text.startswith('R|'):
            return text[2:].splitlines()
        # this is the RawTextHelpFormatter._split_lines
        return argparse.HelpFormatter._split_lines(self, text, width)

#Function from: http://stackoverflow.com/questions/34927479/command-line-show-list-of-options-and-let-user-choose
def let_user_pick(options):
    print("Please choose:")
    for idx, element in enumerate(options):
        print("{}) {}".format(idx+1,element))
    i = input("Enter number: ")
    try:
        if 0 < int(i) <= len(options):
            return int(i) - 1
    except:
        pass
    return None

availableToolchainsDescriptions = [
    "osx-10-13-dep-10-10-cxx17 (macOS SDK 10.13, Deployment Target OSX 10.10, Clang/LLVM, C++17, Xcode)",
    "osx-10-14-dep-10-10-cxx17 (macOS SDK 10.14, Deployment Target OSX 10.10, Clang/LLVM, C++17, Xcode)",
    "ios-11-4-dep-9-0-bitcode-cxx17 (iOS SDK 11.4, Deployment Target iOS 9.0, Clang/LLVM, Bitcode, C++17, Xcode)",
    "clang-libcxx17-fpic (Clang/LLVM, LLVM Standard C++ Library (libc++), C++17, PIC, Default Generator: Unix Makefiles)",
    "emscripten-cxx17 (Emscripten/LLVM, C++17, Unix Makefiles)",
    "gcc-8-cxx17-fpic (gcc/g++ 8, C++17, PIC, Unix Makefiles)"
    "vs-15-2017-win64-cxx17 (Visual Studio 2017 Win64, C++17)",
    "vs-16-2019-win64-cxx17 (Visual Studio 2019 Win64, C++17)"
]

availableToolchains = [
    "osx-10-13-dep-10-10-cxx17",
    "osx-10-14-dep-10-10-cxx17",
    "ios-11-4-dep-9-0-bitcode-cxx17",
    "clang-libcxx17-fpic",
    "emscripten-cxx17",
    "gcc-8-cxx17-fpic",
    "vs-15-2017-win64-cxx17",
    "vs-16-2019-win64-cxx17"
]

availableConfigs = [
    "Debug",
    "Release",
    "RelWithDebInfo",
    "MinSizeRel"
]

configurableToolchains = [
    "clang-libcxx17-fpic",
    "emscripten-cxx17",
    "gcc-8-cxx17-fpic"
]

#Retrieve the available generators from cmake.
sp = subprocess.Popen("cmake -G", stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
out, err = sp.communicate()
availableGenerators = []
if err:
    for row in err.split(b'\n'):
        if b'=' in row:
            key, value = row.split(b'=')
            key = key.strip()
            if key is not b'':
                availableGenerators.append(key.decode('utf-8'))

if len(availableGenerators) == 0:
    print("cmake not found in path. Please install it and try again!")
    exit(1)

parser = argparse.ArgumentParser(description="Configure script to generate build files using CMake.", formatter_class=SmartFormatter)
parser.add_argument("toolchain", help="R|Toolchain to use to build. Supported values are:\n\t"+"\n\t".join(availableToolchainsDescriptions), choices=availableToolchains, metavar='<toolchain>')
parser.add_argument("--with-gui", help="Build with Qt5 User Interface", action='store_true')
parser.add_argument("--with-assimp", help="Build with Assimp", action='store_true')
parser.add_argument("--with-java", help="Build Java bindings and JNI classes (requires JDK and SWIG)", action='store_true')
parser.add_argument("--with-python", help="Build Python bindings (requires Python and SWIG)", action='store_true')
parser.add_argument("--without-projects", help="Disable building of the included projects.", action='store_true')
parser.add_argument("--build-shared", help="Build shared libraries (.so/.dylib/.dll) instead of static libraries (.a). Forced on by --with-java.", action='store_true')
parser.add_argument("--without-tests", help="Disable building of the included tests.", action='store_true')
parser.add_argument("--without-clang-format", help="Disable auto-formatting of code.", action='store_true')
parser.add_argument("--with-clang-tidy", help="Enable using clang-tidy to analyze code.", action='store_true')
parser.add_argument("--with-iwyu", help="Enable running include-what-you-use on code.", action='store_true')
parser.add_argument("--with-gpu", help="Enable gpu processing.", action='store_true')
parser.add_argument("--dev", help="Enable development features like debug logging, regardless of build type", action='store_true')
parser.add_argument("-r","--reconfigure", help="Clear the CMake cache when configuring, use when changing options for already configured toolchains.", action='store_true')
parser.add_argument("-c","--config",help="R|Build configuration, applies to non-Xcode/Visual Studio generators. Default is Debug. Should be one of:\n\t"+"\n\t".join(availableConfigs), choices=availableConfigs, metavar='')
parser.add_argument("-G","--generator",help="R|Which CMake generator to use, only applies to toolchains with a \"Default Generator.\" Should be one of:\n\t"+"\n\t".join(availableGenerators), choices=availableGenerators, metavar='')
parser.add_argument("-B","--build-dir",help="Specify the build directory to use. Default is _builds/<toolchain_name>-<config>")
parser.add_argument("--clear", help="Delete the toolchain's directory in _builds before configuring.", action='store_true')
parser.add_argument("--clear-all", help="Delete the _builds directory before configuring.", action='store_true')
parser.add_argument("--disable-tuning", help="Fallback to tuning for SSE2 instead of newer instruction sets.", action='store_true')
args = parser.parse_args()

if(not os.path.isfile("CMakeLists.txt")):
    print("Couldn't find CMakeLists.txt in the current folder. Please run this script from a folder with CMakeLists.txt!")
    exit(1)

# Try to extract the project name from the CMake file
projNameRegex = re.compile(r"^set\(PROJ_NAME[\"\ ]*([a-zA-Z0-9]*)[\"\ ]*\)$")
for line in open("CMakeLists.txt", 'r'):
    for match in re.finditer(projNameRegex, line):
        projectName = match.group(1)
        break

if(projectName is None):
    print("Couldn't find PROJ_NAME in CMakeLists.txt in the current folder. Please double check CMakeLists.txt!")
    exit(1)

selectedToolchain = args.toolchain

additionalCMakeArguments = ""
need3rdPartyBuild = False
if "emscripten" in args.toolchain:
    additionalCMakeArguments += " -DEMSCRIPTEN_FORCE_COMPILERS=ON"
    print("The Emscripten toolchain will not build Java bindings, shared libraries, projects, or tests, even if selected.")
    args.with_java = False
    args.build_shared = False
    args.without_projects = True
    args.without_tests = True

if args.with_gui:
    additionalCMakeArguments += " -D"+projectName+"_BUILD_QT5_GUI=ON"
if args.with_assimp:
    additionalCMakeArguments += " -D"+projectName+"_BUILD_ASSIMP=ON"
if args.with_java:
    additionalCMakeArguments += " -D"+projectName+"_BUILD_JAVA_BINDINGS=ON"
if args.with_python:
    additionalCMakeArguments += " -D"+projectName+"_BUILD_PYTHON_BINDINGS=ON"
if args.build_shared:
    additionalCMakeArguments += " -D"+projectName+"_BUILD_SHARED_LIBS=ON"
if args.without_projects:
    additionalCMakeArguments += " -D"+projectName+"_BUILD_PROJECTS=OFF"
if args.without_tests:
    additionalCMakeArguments += " -D"+projectName+"_BUILD_TESTS=OFF"
if args.without_clang_format:
    additionalCMakeArguments += " -D"+projectName+"_ENABLE_CLANG_FORMAT=OFF"
if args.with_clang_tidy:
    additionalCMakeArguments += " -D"+projectName+"_ENABLE_CLANG_TIDY=ON"
if args.with_iwyu:
    additionalCMakeArguments += " -D"+projectName+"_ENABLE_IWYU=ON"
if args.with_gpu:
    additionalCMakeArguments += " -D"+projectName+"_ENABLE_GPU=ON"
# Turn the dev flag on if you have explicitly requested for the dev
# flag to be on, or if the build type is not explicitly a type of
# release build. This is useful for not needing to regenerate Xcode
# projects - they just always default to Dev mode.
if args.dev or args.config is None or args.config == "Debug":
    additionalCMakeArguments += " -D"+projectName+"_DEV=ON"
if args.disable_tuning:
    additionalCMakeArguments += " -D"+projectName+"_DISABLE_ARCHITECTURE_OPTIMIZATION=ON"
configArgument = ""
generatorArgument = ""
extraDirName = ""
if selectedToolchain in configurableToolchains:
    if args.config is None:
        args.config = "Debug"
    if args.generator is None:
        args.generator = "Unix Makefiles"
    extraDirName = "-"+args.config
    configArgument = "--config " + args.config + " "
    additionalCMakeArguments += " -DCMAKE_BUILD_TYPE="+args.config
else:
    if "ios" in selectedToolchain or "osx" in selectedToolchain:
        args.generator = "Xcode"
    elif selectedToolchain == "vs-15-2017-win64-cxx17":
        args.generator = "Visual Studio 15 2017 Win64"
        additionalCMakeArguments += " -T host=x64"
    elif selectedToolchain == "vs-16-2019-win64-cxx17":
        args.generator = "Visual Studio 16 2019"
        additionalCMakeArguments += " -A x64"
    else:
        args.generator = "Unix Makefiles"
buildDir = "_builds/"+selectedToolchain+extraDirName
if args.build_dir is not None:
    buildDir = args.build_dir

if args.clear_all:
    if(os.path.isdir("_builds")):
        shutil.rmtree("_builds")
elif args.clear:
    if(os.path.isdir(buildDir)):
        shutil.rmtree(buildDir)

mkdir_p(buildDir)

if need3rdPartyBuild:
    cmake3rdPartyCallString = "cmake -H3rdparty/ -B3rdparty/_build"
    sp3p = subprocess.call(cmake3rdPartyCallString, shell=True)
    if(sp3p != 0):
        exit(sp3p)
    cmake3rdPartyCallString = "cmake --build 3rdparty/_build"
    sp3p = subprocess.call(cmake3rdPartyCallString, shell=True)
    cmake3rdPartyCallString = "cmake -E remove_directory 3rdparty/_build"
    sp3p = subprocess.call(cmake3rdPartyCallString, shell=True)
    if(sp3p != 0):
        exit(sp3p)

pathToToolchain = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "hunter/polly", selectedToolchain+".cmake"))

cmakeCallString = (
    "cmake -H. -B" +
    buildDir +
    " -G\"" +
    args.generator +
    "\" -DCMAKE_TOOLCHAIN_FILE=" +
    pathToToolchain +
    " -DHUNTER_STATUS_DEBUG=OFF -DHUNTER_USE_CACHE_SERVERS=YES" +
    additionalCMakeArguments)
sp = subprocess.call(cmakeCallString, shell=True)

exit(sp)
