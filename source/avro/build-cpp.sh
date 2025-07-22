#!/usr/bin/env bash
# Copyright 2023 Cloudera Inc.
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

source $SOURCE_DIR/functions.sh
THIS_DIR="$( cd "$( dirname "$0" )" && pwd )"
prepare $THIS_DIR

if needs_build_package ; then
  # Download the dependency from S3
  TARBALL_BASE_NAME="avro-release-${PACKAGE_VERSION}"
  download_dependency $PACKAGE "${TARBALL_BASE_NAME}.tar.gz" $THIS_DIR

  # Rename the directory from avro-release-VERSION to avro-VERSION
  setup_package_build $PACKAGE $PACKAGE_VERSION "${TARBALL_BASE_NAME}.tar.gz" \
      "$TARBALL_BASE_NAME" $PACKAGE_STRING

  # Avro turns on all sorts of warnings with Werror. We don't want new versions
  # of GCC to run into errors, so turn off Werror
  CXXFLAGS="${CXXFLAGS} -Wno-error"

  cd lang/c++
  mkdir -p build
  cd build
  # Avro only needs Boost if building the tests, so specify AVRO_BUILD_TESTS=OFF
  # to avoid that dependency.
  wrap cmake -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$LOCAL_INSTALL \
    -DAVRO_BUILD_TESTS=OFF \
    ..
  wrap make VERBOSE=1 -C . -j${BUILD_THREADS:-4}

  # Different versions of CMake produce different locations for the avro-c.pc file
  if [[ -e avro-c.pc ]]; then
    cp avro-c.pc src/
  fi

  wrap make -C . -j${BUILD_THREADS:-4} install
  finalize_package_build $PACKAGE $PACKAGE_VERSION
fi
