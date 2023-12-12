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
set -o pipefail

export SOURCE_DIR="$( cd "$( dirname "$0" )" && pwd )"
mkdir -p $SOURCE_DIR/check $SOURCE_DIR/build

# Check that command line arguments were passed correctly.
if [ $# -lt 1 ]; then
  echo "Usage $0 toolchain_id [package_name1 version1 ...]"
  echo "      Fetches one or more packages identified by package_name"
  echo "      and version identifier."
  echo "      If no packages are specified, fetches compilation tools."
  echo ""
  false
fi

TOOLCHAIN_HOST=native-toolchain.s3.amazonaws.com
TOOLCHAIN_BUILD_ID=$1
shift

# Set up the environment configuration.
source ./init.sh

# Map OS_NAME/VERSION to upload locations
case "$OS_NAME" in
  rhel)
    [ $OS_VERSION -lt 9 ] && OS_LABEL=centos-$OS_VERSION || OS_LABEL=rocky-$OS_VERSION ;;
  ubuntu)
    OS_LABEL=ubuntu-$OS_VERSION-04 ;;
  *)
    echo "Prebuilt packages unavailable for $OS_NAME$OS_VERSION" && exit 1 ;;
esac

function fetch() {
  name=$1
  version=$2
  build_version=$version-${COMPILER}-${COMPILER_VERSION}
  build_label=$name-$build_version-ec2-package-$OS_LABEL-$ARCH_NAME
  url="https://${TOOLCHAIN_HOST}/build/${TOOLCHAIN_BUILD_ID}/$name/${build_version}/$build_label.tar.gz"
  echo "Fetching $name $version from ${url}"
  pushd $SOURCE_DIR/build
  download_url ${url} $name-$version.tar.gz
  extract_archive $name-$version.tar.gz
  touch $SOURCE_DIR/check/$name-$version
}

if [ $# = 0 ]; then
  fetch binutils $BINUTILS_VERSION
  fetch gcc $GCC_VERSION
  fetch gdb $GDB_VERSION
  fetch cmake $CMAKE_VERSION
fi

while (( "$#" )); do
  package=$1
  shift
  if [ "$#" == "0" ]; then
    echo "Version not found for ${package}."
    false
  fi
  version=$1
  shift
  fetch $package $version
done
