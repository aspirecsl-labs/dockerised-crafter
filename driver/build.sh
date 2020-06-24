#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: $(basename "$0")"
  echo ""
  echo "Build a Crafter CMS Driver image"
  echo ""
}

WORKING_DIR=${CRAFTER_HOME:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
CRAFTER_SCRIPTS_HOME=${WORKING_DIR}/../scripts

# shellcheck source=<repo_root>/scripts/lib.sh
source "${CRAFTER_SCRIPTS_HOME}"/lib.sh

if [ -n "$1" ]; then
  usage
  exit 1
fi

IMAGE=$(readProperty "./release" "IMAGE")
VERSION=$(readProperty "./release" "VERSION")

docker build --tag "${IMAGE}:${VERSION}" .

docker tag "${IMAGE}:${VERSION}" "${IMAGE}:latest"
