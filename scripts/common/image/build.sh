#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} OPTIONS"
  echo ""
  echo "Builds a Crafter ${INTERFACE} image"
  echo ""
  echo "Options:"
  echo "-o|--overrides Allows users to override defaults"
  echo "    Overrides are specified as \"name1=value1,name2=value2,...,nameN=valueN\" "
  echo "    Supported overrides are:-"
  echo "        version:  The Crafter version. Example \"version=3.1.7\" "
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter authoring image build' to build a Crafter authoring image"
  echo "Use 'crafter delivery image build' to build a Crafter delivery image"
fi

# shellcheck source=<repo_root>/scripts/common/functions.sh
source "$CRAFTER_SCRIPTS_HOME"/common/functions.sh

if [ "$1" = '--overrides' ] || [ "$1" = '-o' ]; then
  enumerateOptions "$2"
else
  if [ -n "$1" ]; then
    usage
    exit 1
  fi
fi

GLOBAL_PROPERTIES="${CRAFTER_HOME}/global.properties"

MAINTAINED_BY=$(readProperty "$GLOBAL_PROPERTIES" "maintained-by")
DOCKER_IMAGE_PREFIX=$(readProperty "$GLOBAL_PROPERTIES" "image-prefix")

VERSION=${version:-$(readProperty "$GLOBAL_PROPERTIES" "default-crafter-version")}
export VERSION

DOWNLOAD_LINK="https://downloads.craftercms.org/$VERSION/crafter-cms-authoring-$VERSION.tar.gz"
export DOWNLOAD_LINK

SHA512_DOWNLOAD_LINK="https://downloads.craftercms.org/$VERSION/crafter-cms-authoring-$VERSION.tar.gz.sha512"
export SHA512_DOWNLOAD_LINK

cd "${CRAFTER_HOME}/${INSTANCE}"

docker build \
  --build-arg VERSION \
  --build-arg DOWNLOAD_LINK \
  --build-arg SHA512_DOWNLOAD_LINK \
  --tag "${MAINTAINED_BY}/${DOCKER_IMAGE_PREFIX}-${INTERFACE}:latest" .

exit 0
