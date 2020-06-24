#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: $(basename "$0")"
  echo ""
  echo "Build a Crafter CMS Authoring image"
  echo ""
}

WORKING_DIR=${CRAFTER_HOME:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
CRAFTER_SCRIPTS_HOME=${WORKING_DIR}/../scripts

# shellcheck source=<repo_root>/scripts/lib.sh
source "${CRAFTER_SCRIPTS_HOME}"/lib.sh

crafter_version_regex='^[0-9]+.[0-9]+.[0-9]+$'
if [[ "$1" =~ $crafter_version_regex ]]; then
  VERSION="$1"
else
  if [ -n "$1" ]; then
    usage
    exit 0
  fi
fi

cd "${CRAFTER_HOME}/${INTERFACE}"
IMAGE=$(readProperty "./release" "IMAGE")

VERSION=${VERSION:-$(readProperty "./release" "VERSION")}
export VERSION

DOWNLOAD_LINK=$(readProperty "./release" "BUNDLE_URL")
export DOWNLOAD_LINK

SHA512_DOWNLOAD_LINK=$(readProperty "./release" "BUNDLE_SHA512_URL")
export SHA512_DOWNLOAD_LINK

docker build \
  --build-arg VERSION \
  --build-arg DOWNLOAD_LINK \
  --build-arg SHA512_DOWNLOAD_LINK \
  --tag "${IMAGE}:${VERSION}" .

docker tag "${IMAGE}:${VERSION}" "${IMAGE}:latest"

exit $?
