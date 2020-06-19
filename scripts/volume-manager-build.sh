#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")}"
  echo ""
  echo "Build a Crafter ${INTERFACE} image"
  echo ""
}

# shellcheck source=<repo_root>/scripts/functions.sh
source "$CRAFTER_SCRIPTS_HOME"/functions.sh

if [ -n "$1" ]; then
  usage
  exit 1
fi

cd "${CRAFTER_HOME}/${INTERFACE}"

IMAGE=$(readProperty "./release" "IMAGE")
VERSION=$(readProperty "./release" "VERSION")

docker build --tag "${IMAGE}:${VERSION}" .
