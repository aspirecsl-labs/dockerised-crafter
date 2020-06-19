#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")}"
  echo ""
  echo "Build a Crafter ${INTERFACE} image"
  echo ""
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter authoring image build' to build a Crafter authoring image"
  echo "Use 'crafter delivery image build' to build a Crafter delivery image"
fi

# shellcheck source=<repo_root>/scripts/functions.sh
source "$CRAFTER_SCRIPTS_HOME"/functions.sh

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
