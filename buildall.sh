#!/usr/bin/env bash
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

# Exit on non-true return value
set -e
# Exit on reference to uninitialized variable
set -u
set -o pipefail

# Set up the environment configuration.
source ./init.sh

if [[ "$DOWNLOAD_CCACHE" -ne 0 ]]; then
  download_ccache
fi

# Configure the compiler/linker flags, bootstrapping tools if necessary.
source ./init-compiler.sh

################################################################################
# How to add new versions to the toolchain:
#
#   * Make sure the build script is ready to build the new version.
#   * Find the libary in the list below and create new line that follows the
#     pattern: LIBRARYNAME_VERSION=Version $SOURCE_DIR/source/LIBRARYNAME/build.sh
#
#  WARNING: Once a library has been rolled out to production, it cannot be
#  removed, but only new versions can be added. Make sure that the library
#  and version you want to add works as expected.
################################################################################
################################################################################
# Boost
################################################################################
if [[ "$ARCH_NAME" != "aarch64" ]]; then
  if (( BUILD_HISTORICAL )) ; then
    BOOST_VERSION=1.57.0 $SOURCE_DIR/source/boost/build.sh
    BOOST_VERSION=1.57.0-p1 $SOURCE_DIR/source/boost/build.sh
    BOOST_VERSION=1.57.0-p2 $SOURCE_DIR/source/boost/build.sh
    BOOST_VERSION=1.57.0-p3 $SOURCE_DIR/source/boost/build.sh
    BOOST_VERSION=1.61.0-p2 $SOURCE_DIR/source/boost/build.sh
  fi
fi
BOOST_VERSION=1.74.0-p1 $SOURCE_DIR/source/boost/build.sh

################################################################################
# Build BZip2
################################################################################
if (( BUILD_HISTORICAL )); then
  BZIP2_VERSION=1.0.6-p1 $SOURCE_DIR/source/bzip2/build.sh
  BZIP2_VERSION=1.0.6-p2 $SOURCE_DIR/source/bzip2/build.sh
fi
BZIP2_VERSION=1.0.8-p2 $SOURCE_DIR/source/bzip2/build.sh

################################################################################
# Build Python
################################################################################
export BZIP2_VERSION=1.0.8-p2
if [[ ! "$OSTYPE" == "darwin"* ]]; then
  # For now, provide both Python 2 and 3 until we can switch over to Python 3.
  PYTHON_VERSION=2.7.16 $SOURCE_DIR/source/python/build.sh
  PYTHON_VERSION=3.7.16 $SOURCE_DIR/source/python/build.sh
else
  PYTHON_VERSION=2.7.16 build_fake_package "python"
fi

export -n BZIP2_VERSION
################################################################################
# LLVM
################################################################################
# Build LLVM 3.3 with and without asserts.
# For LLVM 3.3, the default is a release build with assertions. The assertions
# are disabled by including "no-asserts" in the version string.
if (( BUILD_HISTORICAL )) ; then
  LLVM_VERSION=3.3-p1 $SOURCE_DIR/source/llvm/build.sh
  LLVM_VERSION=3.3-no-asserts-p1 $SOURCE_DIR/source/llvm/build.sh
fi

# Build LLVM 3.7+ with and without assertions. For LLVM 3.7+, the default is a
# release build with no assertions.
(
  export PYTHON_VERSION=2.7.16
  if (( BUILD_HISTORICAL )) ; then
    LLVM_VERSION=3.7.0 $SOURCE_DIR/source/llvm/build.sh
    LLVM_VERSION=3.8.0 $SOURCE_DIR/source/llvm/build.sh
    LLVM_VERSION=3.8.0-p1 $SOURCE_DIR/source/llvm/build.sh
    LLVM_VERSION=3.8.0-asserts-p1 $SOURCE_DIR/source/llvm/build.sh
    LLVM_VERSION=3.9.1 $SOURCE_DIR/source/llvm/build.sh
    LLVM_VERSION=3.9.1-asserts $SOURCE_DIR/source/llvm/build.sh
    LLVM_VERSION=5.0.1 $SOURCE_DIR/source/llvm/build.sh
    LLVM_VERSION=5.0.1-asserts $SOURCE_DIR/source/llvm/build.sh
  fi
  LLVM_VERSION=5.0.1-p5 $SOURCE_DIR/source/llvm/build.sh
  LLVM_VERSION=5.0.1-asserts-p5 $SOURCE_DIR/source/llvm/build.sh
)

################################################################################
# Build protobuf
################################################################################
PROTOBUF_VERSION=3.14.0 $SOURCE_DIR/source/protobuf/build.sh
# Impala Clang builds hit a micro redefinition compiling error and symbol related
# issue in linking with protobuf 3.14.0. Two patches were created to fix these
# Clang compatibility issues.
# 3.14.0-clangcompat-p2 should be used for Impala Clang builds.
PROTOBUF_VERSION=3.14.0-clangcompat-p2 $SOURCE_DIR/source/protobuf/build.sh

################################################################################
# Build libev
################################################################################
LIBEV_VERSION=4.20-p1 $SOURCE_DIR/source/libev/build.sh

################################################################################
# Build crcutil
################################################################################
if (( BUILD_HISTORICAL )) ; then
  CRCUTIL_VERSION=440ba7babeff77ffad992df3a10c767f184e946e\
    $SOURCE_DIR/source/crcutil/build.sh
  CRCUTIL_VERSION=440ba7babeff77ffad992df3a10c767f184e946e-p1\
    $SOURCE_DIR/source/crcutil/build.sh
  CRCUTIL_VERSION=440ba7babeff77ffad992df3a10c767f184e946e-p2\
    $SOURCE_DIR/source/crcutil/build.sh
fi
CRCUTIL_VERSION=2903870057d2f1f109b245650be29e856dc8b646\
  $SOURCE_DIR/source/crcutil/build.sh

################################################################################
# Build OpenSSL - this is not intended for production use of Impala.
# Libraries that depend on OpenSSL will only use it if PRODUCTION=1.
################################################################################
if (( BUILD_HISTORICAL )); then
  OPENSSL_VERSION=1.0.1p $SOURCE_DIR/source/openssl/build.sh
  OPENSSL_VERSION=1.0.2l $SOURCE_DIR/source/openssl/build.sh
fi

################################################################################
# Build ZLib
################################################################################
if (( BUILD_HISTORICAL )); then
  ZLIB_VERSION=1.2.8 $SOURCE_DIR/source/zlib/build.sh
  ZLIB_VERSION=1.2.11 $SOURCE_DIR/source/zlib/build.sh
fi
ZLIB_VERSION=1.2.12 $SOURCE_DIR/source/zlib/build.sh


################################################################################
# Build Bison
################################################################################
BISON_VERSION=3.0.4-p1 $SOURCE_DIR/source/bison/build.sh

################################################################################
# Build Thrift
#  * depends on bison, boost, zlib and openssl
################################################################################
export BISON_VERSION=3.0.4-p1
export BOOST_VERSION=1.74.0-p1
export ZLIB_VERSION=1.2.12
export PYTHON_VERSION=2.7.16

if [[ ! "$OSTYPE" == "darwin"* ]]; then
  if (( BUILD_HISTORICAL )); then
    THRIFT_VERSION=0.9.0-p2 $SOURCE_DIR/source/thrift/build.sh
    THRIFT_VERSION=0.9.0-p4 $SOURCE_DIR/source/thrift/build.sh
    THRIFT_VERSION=0.9.0-p5 $SOURCE_DIR/source/thrift/build.sh
    # 0.9.0-p6 is a revert of -p5 patch. It doesn't need to be built.
    # It is equivalent to p4 and is needed for subsequent patches.
    THRIFT_VERSION=0.9.0-p7 $SOURCE_DIR/source/thrift/build.sh
    THRIFT_VERSION=0.9.0-p8 $SOURCE_DIR/source/thrift/build.sh
    THRIFT_VERSION=0.9.0-p9 $SOURCE_DIR/source/thrift/build.sh
    THRIFT_VERSION=0.9.0-p10 $SOURCE_DIR/source/thrift/build.sh
    THRIFT_VERSION=0.9.0-p12 $SOURCE_DIR/source/thrift/build.sh
    THRIFT_VERSION=0.9.3-p5 $SOURCE_DIR/source/thrift/build.sh
    THRIFT_VERSION=0.9.3-p6 $SOURCE_DIR/source/thrift/build.sh
    THRIFT_VERSION=0.9.3-p8 $SOURCE_DIR/source/thrift/build.sh
    THRIFT_VERSION=0.11.0-p4 $SOURCE_DIR/source/thrift/build.sh
    THRIFT_VERSION=0.13.0-p4 $SOURCE_DIR/source/thrift/build.sh
    THRIFT_VERSION=0.14.2-p4 $SOURCE_DIR/source/thrift/build.sh
  fi
  THRIFT_VERSION=0.11.0-p5 $SOURCE_DIR/source/thrift/build.sh
  THRIFT_VERSION=0.16.0-p3 $SOURCE_DIR/source/thrift/build.sh
else
  THRIFT_VERSION=0.9.2-p4 $SOURCE_DIR/source/thrift/build.sh
fi

export -n BISON_VERSION
export -n BOOST_VERSION
export -n ZLIB_VERSION
export -n PYTHON_VERSION

################################################################################
# gflags
################################################################################
if (( BUILD_HISTORICAL )); then
    GFLAGS_VERSION=2.0 $SOURCE_DIR/source/gflags/build.sh
fi
GFLAGS_VERSION=2.2.0-p2 $SOURCE_DIR/source/gflags/build.sh

################################################################################
# Build gperftools
################################################################################
if (( BUILD_HISTORICAL )); then
  GPERFTOOLS_VERSION=2.0-p1 $SOURCE_DIR/source/gperftools/build.sh
  GPERFTOOLS_VERSION=2.3 $SOURCE_DIR/source/gperftools/build.sh
fi
# IMPALA-6414: Required until issues with 2.6.3 have been sorted out.
GPERFTOOLS_VERSION=2.5-p4 $SOURCE_DIR/source/gperftools/build.sh
GPERFTOOLS_VERSION=2.6.3 $SOURCE_DIR/source/gperftools/build.sh
GPERFTOOLS_VERSION=2.8.1-p1 $SOURCE_DIR/source/gperftools/build.sh

################################################################################
# Build glog
################################################################################
if (( BUILD_HISTORICAL )) ; then
  GFLAGS_VERSION=2.0 GLOG_VERSION=0.3.2-p1 $SOURCE_DIR/source/glog/build.sh
  GFLAGS_VERSION=2.0 GLOG_VERSION=0.3.2-p2 $SOURCE_DIR/source/glog/build.sh
  if [[ ! "$RELEASE_NAME" =~ CentOS.*5\.[[:digit:]] ]]; then
      # CentOS 5 has issues with the glog patch, probably autotools is too old.
      GFLAGS_VERSION=2.2.0 GLOG_VERSION=0.3.3-p1 $SOURCE_DIR/source/glog/build.sh
  fi
  GFLAGS_VERSION=2.2.0-p1 GLOG_VERSION=0.3.4-p2 $SOURCE_DIR/source/glog/build.sh
  GFLAGS_VERSION=2.2.0-p2 GLOG_VERSION=0.3.4-p3 $SOURCE_DIR/source/glog/build.sh
fi

GFLAGS_VERSION=2.2.0-p2 GLOG_VERSION=0.3.5-p3 $SOURCE_DIR/source/glog/build.sh

################################################################################
# Build gtest
################################################################################
GTEST_VERSION=1.6.0 $SOURCE_DIR/source/gtest/build.sh

# New versions of gtest are named googletest
GOOGLETEST_VERSION=1.8.0 $SOURCE_DIR/source/googletest/build.sh

################################################################################
# Build Snappy
################################################################################
if (( BUILD_HISTORICAL )); then
  SNAPPY_VERSION=1.0.5 $SOURCE_DIR/source/snappy/build.sh
  SNAPPY_VERSION=1.1.3 $SOURCE_DIR/source/snappy/build.sh
  SNAPPY_VERSION=1.1.4 $SOURCE_DIR/source/snappy/build.sh
fi
SNAPPY_VERSION=1.1.8 $SOURCE_DIR/source/snappy/build.sh

################################################################################
# Build Lz4
################################################################################
if (( BUILD_HISTORICAL )); then
  LZ4_VERSION=svn $SOURCE_DIR/source/lz4/build.sh
  LZ4_VERSION=1.7.5 $SOURCE_DIR/source/lz4/build.sh
fi
LZ4_VERSION=1.9.3 $SOURCE_DIR/source/lz4/build.sh

################################################################################
# Build Zstd
################################################################################
if (( BUILD_HISTORICAL )); then
  ZSTD_VERSION=1.4.0 $SOURCE_DIR/source/zstd/build.sh
  ZSTD_VERSION=1.4.9 $SOURCE_DIR/source/zstd/build.sh
fi
ZSTD_VERSION=1.5.2 $SOURCE_DIR/source/zstd/build.sh

################################################################################
# Build re2
################################################################################
if (( BUILD_HISTORICAL )); then
  RE2_VERSION=20130115 $SOURCE_DIR/source/re2/build.sh
  RE2_VERSION=20130115-p1 $SOURCE_DIR/source/re2/build.sh
fi
RE2_VERSION=20190301 $SOURCE_DIR/source/re2/build.sh

################################################################################
# Build Ldap
################################################################################
OPENLDAP_VERSION=2.4.47 $SOURCE_DIR/source/openldap/build.sh

################################################################################
# Build Avro
################################################################################
if (( BUILD_HISTORICAL )); then
  AVRO_VERSION=1.7.4-p4 $SOURCE_DIR/source/avro/build.sh
fi
AVRO_VERSION=1.7.4-p5 $SOURCE_DIR/source/avro/build.sh
# Build a new version as well
(
  export BOOST_VERSION=1.74.0-p1
  AVRO_VERSION=1.11.1-p1 $SOURCE_DIR/source/avro/build-cpp.sh
)

################################################################################
# Build Rapidjson
################################################################################
if (( BUILD_HISTORICAL )); then
  RAPIDJSON_VERSION=0.11 $SOURCE_DIR/source/rapidjson/build.sh
fi
RAPIDJSON_VERSION=1.1.0 $SOURCE_DIR/source/rapidjson/build.sh

################################################################################
# Build Libunwind
################################################################################
if (( BUILD_HISTORICAL )); then
  LIBUNWIND_VERSION=1.3-rc1-p3 $SOURCE_DIR/source/libunwind/build.sh
fi
LIBUNWIND_VERSION=1.5.0-p1 $SOURCE_DIR/source/libunwind/build.sh

################################################################################
# Build Breakpad
################################################################################
if (( BUILD_HISTORICAL )); then
  BREAKPAD_VERSION=20150612-p1 $SOURCE_DIR/source/breakpad/build.sh
  BREAKPAD_VERSION=97a98836768f8f0154f8f86e5e14c2bb7e74132e-p2 $SOURCE_DIR/source/breakpad/build.sh
fi
BREAKPAD_VERSION=e09741c609dcd5f5274d40182c5e2cc9a002d5ba-p2 $SOURCE_DIR/source/breakpad/build.sh

################################################################################
# Build Flatbuffers
################################################################################
if (( BUILD_HISTORICAL )); then
  FLATBUFFERS_VERSION=1.6.0 $SOURCE_DIR/source/flatbuffers/build.sh
fi
FLATBUFFERS_VERSION=1.9.0-p1 $SOURCE_DIR/source/flatbuffers/build.sh

################################################################################
# Build Kudu
################################################################################
(
  export BOOST_VERSION=1.74.0-p1
  export KUDU_VERSION=345fd44ca3
  export PYTHON_VERSION=2.7.16
  if $SOURCE_DIR/source/kudu/build.sh is_supported_platform; then
    $SOURCE_DIR/source/kudu/build.sh build
  else
    build_fake_package kudu
  fi
)

################################################################################
# Build TPC-H
################################################################################
TPC_H_VERSION=2.17.0 $SOURCE_DIR/source/tpc-h/build.sh

################################################################################
# Build TPC-DS
################################################################################
TPC_DS_VERSION=2.1.0-p1 $SOURCE_DIR/source/tpc-ds/build.sh

################################################################################
# Build KRB5
################################################################################
if (( BUILD_HISTORICAL )) ; then
  KRB5_VERSION=1.15.1 $SOURCE_DIR/source/krb5/build.sh
fi

################################################################################
# Build ORC
################################################################################
(
  export LZ4_VERSION=1.9.3
  export PROTOBUF_VERSION=3.14.0
  export SNAPPY_VERSION=1.1.8
  export ZLIB_VERSION=1.2.12
  export ZSTD_VERSION=1.5.2
  export GOOGLETEST_VERSION=1.8.0
  if (( BUILD_HISTORICAL )); then
    ORC_VERSION=1.4.3-p3 $SOURCE_DIR/source/orc/build.sh
    ORC_VERSION=1.5.5-p1 $SOURCE_DIR/source/orc/build.sh
    ORC_VERSION=1.6.2-p11 $SOURCE_DIR/source/orc/build.sh
    ORC_VERSION=1.7.0-p8 $SOURCE_DIR/source/orc/build.sh
  fi
  ORC_VERSION=1.7.0-p14 $SOURCE_DIR/source/orc/build.sh
)

################################################################################
# CCTZ
################################################################################
CCTZ_VERSION=2.2 $SOURCE_DIR/source/cctz/build.sh

################################################################################
# JWT-CPP
################################################################################
JWT_CPP_VERSION=0.5.0 $SOURCE_DIR/source/jwt-cpp/build.sh

################################################################################
# ARROW
################################################################################
if (( BUILD_HISTORICAL )); then
  ARROW_VERSION=4.0.1 $SOURCE_DIR/source/arrow/build.sh
fi
ARROW_VERSION=9.0.0-p2 $SOURCE_DIR/source/arrow/build.sh

# CURL
################################################################################
CURL_VERSION=7.78.0 $SOURCE_DIR/source/curl/build.sh

# CALLONCEHACK
################################################################################
CALLONCEHACK_VERSION=1.0.0 $SOURCE_DIR/source/calloncehack/build.sh
