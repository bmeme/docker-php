#!/bin/bash

## Simple script to build images
# Usage:
# $ scripts/build.sh [PHP_PRETTY_VERSION] [OS_VERSION] [PHP_TYPE]
#
# where:
# PHP_PRETTY_VERSION: major.minor version of PHP ex: 8.0
# OS_VERSION: Debian version (buster/bullseyes)
# PHP_TYPE: at this stage only `apache`

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Arguments
PHP_PRETTY_VERSION=$1
OS_VERSION=$2
PHP_TYPE=$3

# Variables
DOCKERFILE="${PHP_PRETTY_VERSION}/${OS_VERSION}/${PHP_TYPE}/Dockerfile"
FROM=$(head -1 "${DOCKERFILE}" | awk '{print $2}')
PHP_VERSION=$(echo "${FROM}" | awk -F: '{print $2}' | awk -F- '{print $1}' )
LATEST=$(cat .latest)

docker build \
  -f "${PHP_PRETTY_VERSION}"/"${OS_VERSION}"/"${PHP_TYPE}"/Dockerfile \
  -t bmeme/php:"${PHP_PRETTY_VERSION}"-"${PHP_TYPE}"-"${OS_VERSION}" \
  -t bmeme/php:"${PHP_VERSION}"-"${PHP_TYPE}"-"${OS_VERSION}" .

if [[ $(echo "${FROM}" | awk -F: '{print $2}') == "${LATEST}" ]]; then
    docker build \
      -f "${PHP_PRETTY_VERSION}"/"${OS_VERSION}"/"${PHP_TYPE}"/Dockerfile \
      -t bmeme/php:latest .
fi