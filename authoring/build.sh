#!/bin/bash
set -e

CAM_HOME=${CAM_HOME:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

# shellcheck source=../functions.sh
source "$CAM_HOME"/../functions.sh

SERVICE=authoring
GLOBAL_PROPERTIES="$CAM_HOME"/../global.properties

MAINTAINED_BY=$(readProperty "$GLOBAL_PROPERTIES" "maintained-by")
DOCKER_IMAGE_PREFIX=$(readProperty "$GLOBAL_PROPERTIES" "image-prefix")
VERSION=${1:-$(readProperty "$GLOBAL_PROPERTIES" "default-crafter-version")}
export VERSION

DOWNLOAD_LINK="https://downloads.craftercms.org/$VERSION/crafter-cms-authoring-$VERSION.tar.gz"
export DOWNLOAD_LINK

SHA512_DOWNLOAD_LINK="https://downloads.craftercms.org/$VERSION/crafter-cms-authoring-$VERSION.tar.gz.sha512"
export SHA512_DOWNLOAD_LINK

docker build \
  --build-arg VERSION \
  --build-arg DOWNLOAD_LINK \
  --build-arg SHA512_DOWNLOAD_LINK \
  --tag "${MAINTAINED_BY}/${DOCKER_IMAGE_PREFIX}-${SERVICE}:latest" .

docker tag "${MAINTAINED_BY}/${DOCKER_IMAGE_PREFIX}-${SERVICE}:latest" \
           "${MAINTAINED_BY}/${DOCKER_IMAGE_PREFIX}-${SERVICE}:${VERSION}"

exit 0
