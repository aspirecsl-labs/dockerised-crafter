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

yes_no_array=(yes no)
available_versions=$(docker images |
  awk -v image_prefix="${MAINTAINED_BY}/${DOCKER_IMAGE_PREFIX}-${SERVICE}" '{  if($1 == image_prefix) {printf("%s ", $2)} }')

# shellcheck disable=SC2068
if ! arrayContainsElement "$VERSION" ${available_versions[@]}; then
  echo -e "\nERROR:- Invalid version $VERSION" >&2
  echo -e "Could not find an image for version $VERSION" >&2
  echo -e "Try building an image for version $VERSION using the command <$MAIN_COMMAND build>\n" >&2
  exit 1
fi
volume_container
volume_container=$(docker container ls -a --format='{{.Names}}' --filter='Name=${DOCKER_IMAGE_PREFIX}-${SERVICE}-${VERSION}_Volume')
if [ -z "$volume_container" ]; then
  volume_container="${DOCKER_IMAGE_PREFIX}-${SERVICE}-${VERSION}_Volume"
  echo -e "\nVolume container corresponding to ${DOCKER_IMAGE_PREFIX}-${SERVICE}:${VERSION} was not found!"
  echo -e "A new volume container will be created (name= $volume_container)\n"
  docker create \
    --volume /opt/crafter/logs \
    --volume /opt/crafter/data \
    --volume /opt/crafter/backups \
    --name "${DOCKER_IMAGE_PREFIX}-${SERVICE}-${VERSION}_Volume" tianon/true /bin/true
fi

echo "Starting container from image: ${DOCKE˚R_IMAGE_PREFIX}-${SERVICE}:${VERSION}"
port=$(numberInput "Map Crafter engine port to (default = 8080): " "y" "n")
developer_mode=$(validatableInput "Developer mode? (default = no): " "y" "n" "${yes_no_array[@]}")
if [ "${developer_mode:-no}" = 'yes' ]; then
  debug=$(validatableInput "Debug? (default = no): " "y" "n" "${yes_no_array[@]}")
  es_port=$(numberInput "Map Elasticsearch port to (default = 9201): " "y" "n")
  deployer_port=$(numberInput "Map Crafter deployer port to (default = 9191): " "y" "n")

  if [ "${debug:-no}" = 'yes' ]; then
    es_debug_port=$(numberInput "Map Elasticsearch debug port to (default = 4004): " "y" "n")
    engine_debug_port=$(numberInput "Map Crafter engine debug port to (default = 8000): " "y" "n")
    deployer_debug_port=$(numberInput "Map Crafter deployer debug port to (default = 5005): " "y" "n")
    docker run --rm \
      -p "${port:-8080}":8080 \
      -p "${es_port:-9201}":9201 \
      -p "${deployer_port:-9191}":9191 \
      -p "${es_debug_port:-4004}":4004 \
      -p "${engine_debug_port:-8000}":8000 \
      -p "${deployer_debug_port:-5005}":5005 \
      --volumes-from "$volume_container" \
      "${MAINTAINED_BY}/${DOCKER_IMAGE_PREFIX}-${SERVICE}:${VERSION}" "debug"
  else
    docker run --rm \
      -p "${port:-8080}":8080 \
      -p "${es_port:-9201}":9201 \
      -p "${deployer_port:-9191}":9191 \
      --volumes-from "$volume_container" \
      "${MAINTAINED_BY}/${DOCKER_IMAGE_PREFIX}-${SERVICE}:${VERSION}"
  fi
else
  docker run --rm \
    -p "${port:-8080}":8080 \
    "${MAINTAINED_BY}/${DOCKER_IMAGE_PREFIX}-${SERVICE}:${VERSION}"
fi

exit 0
