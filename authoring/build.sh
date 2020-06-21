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
CRAFTER_SCRIPTS_HOME=${WORKING_DIR}../scripts

# shellcheck source=<repo_root>/scripts/functions.sh
source "${CRAFTER_SCRIPTS_HOME}"/functions.sh

if [ -n "$1" ]; then
  usage
  exit 1
fi

cd "${CRAFTER_HOME}/${INTERFACE}"
IMAGE=$(readProperty "./release" "IMAGE")

VERSION=$(readProperty "./release" "VERSION")
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

exit $?
