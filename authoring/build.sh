#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: $(basename "$0") version"
  echo ""
  echo "version  The required version of Crafter CMS Authoring service "
  echo ""
  echo "Build an image containing the specified version of Crafter CMS Authoring service"
  echo ""
}

WORKING_DIR=${CRAFTER_HOME:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
CRAFTER_SCRIPTS_HOME=${WORKING_DIR}/../scripts

# shellcheck source=<repo_root>/scripts/lib.sh
source "${CRAFTER_SCRIPTS_HOME}"/lib.sh

crafter_version_regex='^[0-9]+.[0-9]+.[0-9]+$'
if [[ "$1" =~ $crafter_version_regex ]]; then
  VERSION="$1"
  export VERSION
else
  usage
  exit 1
fi

cd "${CRAFTER_HOME}/${INTERFACE}"
IMAGE=$(readProperty "./release" "IMAGE")

docker build --build-arg VERSION --tag "${IMAGE}:${VERSION}" .

docker tag "${IMAGE}:${VERSION}" "${IMAGE}:latest"

exit $?
