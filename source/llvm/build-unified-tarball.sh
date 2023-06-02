#!/bin/bash
# Copyright 2015 Cloudera Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Builds LLVM 6 and later from unified source tarball.

set -eu
set -o pipefail

function build_unified_llvm() {
  # Cleanup possible leftovers
  rm -Rf "$THIS_DIR/${PACKAGE_STRING}.src"
  rm -Rf "$THIS_DIR/build-${PACKAGE_STRING}"

  # The llvm source is composed of multiple archives, some of which are optional.
  # To allow unified patches across the entirety of the source, we extract all of the
  # desired archives in the appropriate places, and then use
  # setup_extracted_package_build, which can then apply patches across the whole
  # source tree.
  EXTRACTED_DIR="llvm-project-${SOURCE_VERSION}.src"
  TARGET_DIR="$PACKAGE_STRING.src"

  extract_archive "$THIS_DIR/llvm-project-${SOURCE_VERSION}.src.${ARCHIVE_EXT}"
  if [ "$EXTRACTED_DIR" != "$TARGET_DIR" ]; then
    echo "Moving $EXTRACTED_DIR to $TARGET_DIR"
    mv "$EXTRACTED_DIR" "$TARGET_DIR"
  fi

  # Patches are based on source version. Pass to setup_extracted_package_build function
  # with this var.
  PATCH_DIR=${THIS_DIR}/llvm-${SOURCE_VERSION}-patches

  setup_extracted_package_build $PACKAGE $PACKAGE_VERSION $TARGET_DIR

  PYTHON3_ROOT_DIR=$BUILD_DIR/python-$PYTHON3_VERSION/

  mkdir -p ${THIS_DIR}/build-$PACKAGE_STRING
  pushd ${THIS_DIR}/build-$PACKAGE_STRING
  local EXTRA_CMAKE_ARGS=
  local LLVM_BUILD_TYPE=Release
  if [[ "$PACKAGE_VERSION" =~ "-asserts" ]]; then
    EXTRA_CMAKE_ARGS+="-DLLVM_ENABLE_ASSERTIONS=true"
  elif [[ "$PACKAGE_VERSION" =~ "-debug" ]]; then
    LLVM_BUILD_TYPE=Debug
  fi

  if [[ "$ARCH_NAME" == "ppc64le" ]]; then
    LLVM_BUILD_TARGET+="PowerPC"
  elif [[ "$ARCH_NAME" == "aarch64" ]]; then
    LLVM_BUILD_TARGET+="AArch64"
  else
    LLVM_BUILD_TARGET+="X86"
  fi

  LLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt;lld"

  # Disable some builds we don't care about.
  for arg in \
      CLANG_ENABLE_ARCMT \
      CLANG_TOOL_ARCMT_TEST_BUILD \
      CLANG_TOOL_C_ARCMT_TEST_BUILD \
      CLANG_TOOL_C_INDEX_TEST_BUILD \
      CLANG_TOOL_CLANG_CHECK_BUILD \
      CLANG_TOOL_CLANG_DIFF_BUILD \
      CLANG_TOOL_CLANG_FORMAT_VS_BUILD \
      CLANG_TOOL_CLANG_FUZZER_BUILD \
      CLANG_TOOL_CLANG_IMPORT_TEST_BUILD \
      CLANG_TOOL_CLANG_OFFLOAD_BUNDLER_BUILD \
      CLANG_TOOL_CLANG_REFACTOR_BUILD \
      CLANG_TOOL_CLANG_RENAME_BUILD \
      CLANG_TOOL_DIAGTOOL_BUILD \
      COMPILER_RT_BUILD_LIBFUZZER \
      LLVM_BUILD_BENCHMARKS \
      LLVM_ENABLE_OCAMLDOC \
      LLVM_INCLUDE_BENCHMARKS \
      LLVM_INCLUDE_GO_TESTS \
      LLVM_POLLY_BUILD \
      LLVM_TOOL_BUGPOINT_BUILD \
      LLVM_TOOL_BUGPOINT_PASSES_BUILD \
      LLVM_TOOL_DSYMUTIL_BUILD \
      LLVM_TOOL_LLI_BUILD \
      LLVM_TOOL_LLVM_AS_FUZZER_BUILD \
      LLVM_TOOL_LLVM_BCANALYZER_BUILD \
      LLVM_TOOL_LLVM_CAT_BUILD \
      LLVM_TOOL_LLVM_CFI_VERIFY_BUILD \
      LLVM_TOOL_LLVM_C_TEST_BUILD \
      LLVM_TOOL_LLVM_CVTRES_BUILD \
      LLVM_TOOL_LLVM_CXXDUMP_BUILD \
      LLVM_TOOL_LLVM_CXXFILT_BUILD \
      LLVM_TOOL_LLVM_DIFF_BUILD \
      LLVM_TOOL_LLVM_DIS_BUILD \
      LLVM_TOOL_LLVM_DWP_BUILD \
      LLVM_TOOL_LLVM_EXTRACT_BUILD \
      LLVM_TOOL_LLVM_GO_BUILD \
      LLVM_TOOL_LLVM_ISEL_FUZZER_BUILD \
      LLVM_TOOL_LLVM_JITLISTENER_BUILD \
      LLVM_TOOL_LLVM_MC_ASSEMBLE_FUZZER_BUILD \
      LLVM_TOOL_LLVM_MC_BUILD \
      LLVM_TOOL_LLVM_MC_DISASSEMBLE_FUZZER_BUILD \
      LLVM_TOOL_LLVM_MODEXTRACT_BUILD \
      LLVM_TOOL_LLVM_MT_BUILD \
      LLVM_TOOL_LLVM_NM_BUILD \
      LLVM_TOOL_LLVM_OBJCOPY_BUILD \
      LLVM_TOOL_LLVM_OBJDUMP_BUILD \
      LLVM_TOOL_LLVM_OPT_FUZZER_BUILD \
      LLVM_TOOL_LLVM_OPT_REPORT_BUILD \
      LLVM_TOOL_LLVM_PDBUTIL_BUILD \
      LLVM_TOOL_LLVM_PROFDATA_BUILD \
      LLVM_TOOL_LLVM_RC_BUILD \
      LLVM_TOOL_LLVM_READOBJ_BUILD \
      LLVM_TOOL_LLVM_RTDYLD_BUILD \
      LLVM_TOOL_LLVM_SHLIB_BUILD \
      LLVM_TOOL_LLVM_SIZE_BUILD \
      LLVM_TOOL_LLVM_SPECIAL_CASE_LIST_FUZZER_BUILD \
      LLVM_TOOL_LLVM_SPLIT_BUILD \
      LLVM_TOOL_LLVM_STRESS_BUILD \
      LLVM_TOOL_LLVM_STRINGS_BUILD \
      LLVM_TOOL_OBJ2YAML_BUILD \
      LLVM_TOOL_OPT_VIEWER_BUILD \
      LLVM_TOOL_VERIFY_USELISTORDER_BUILD \
      LLVM_TOOL_XCODE_TOOLCHAIN_BUILD \
      LLVM_TOOL_YAML2OBJ_BUILD \
      ; do
    EXTRA_CMAKE_ARGS+=" -D${arg}=OFF"
  done

  # Invoke CMake with the correct configuration
  wrap cmake ${THIS_DIR}/$PACKAGE_STRING.src${PATCH_VERSION}/llvm \
      -DCMAKE_BUILD_TYPE=${LLVM_BUILD_TYPE} \
      -DCMAKE_INSTALL_PREFIX=$LOCAL_INSTALL \
      -DLLVM_TARGETS_TO_BUILD=$LLVM_BUILD_TARGET \
      -DLLVM_ENABLE_PROJECTS=$LLVM_ENABLE_PROJECTS \
      -DLLVM_ENABLE_RTTI=ON \
      -DLLVM_ENABLE_TERMINFO=OFF \
      -DLLVM_INCLUDE_DOCS=OFF \
      -DLLVM_INCLUDE_EXAMPLES=OFF \
      -DLLVM_INCLUDE_TESTS=OFF \
      -DLLVM_PARALLEL_COMPILE_JOBS=${BUILD_THREADS:-4} \
      -DLLVM_PARALLEL_LINK_JOBS=${BUILD_THREADS:-4} \
      -DPython3_ROOT_DIR=$PYTHON3_ROOT_DIR \
      ${EXTRA_CMAKE_ARGS}

  wrap make -j${BUILD_THREADS:-4} install
  popd

  finalize_package_build $PACKAGE $PACKAGE_VERSION
}
