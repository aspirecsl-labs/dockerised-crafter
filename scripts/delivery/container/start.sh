#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} OPTIONS"
  echo ""
  echo "Starts a Crafter ${INTERFACE} container"
  echo ""
  echo "Options:"
  echo "-o|--overrides Allows users to override defaults"
  echo "    Overrides are specified as \"name1=value1,name2=value2,...,nameN=valueN\" "
  echo "    Supported overrides are:-"
  echo "        debug_port:           The host machine port to bind the container's Crafter engine port. Example \"debug_port=9000\" "
  echo "        deployer_port:        The host machine port to bind the container's Crafter deployer port. Example \"deployer_port=9192\" "
  echo "        es_port:              The host machine port to bind the container's Elasticsearch port. Example \"es_port=9202\" "
  echo "        port:                 The host machine port to bind the container's Crafter engine port. Example \"port=9080\" "
  echo "        version:              The Crafter version. Example \"version=3.1.7\" "
  echo "        volume:               The container (name) from which Crafter container obtains its user data volumes. Example \"volume=crafter-auth-3.1.5-volume\" "
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter delivery container start' to start a Crafter delivery container"
fi

# shellcheck source=<repo_root>/scripts/common/functions.sh
source "$CRAFTER_SCRIPTS_HOME"/common/functions.sh

if [ "$1" = '--options' ] || [ "$1" = '-o' ]; then
  enumerateOptions "$2"
else
  if [ -n "$1" ]; then
    usage
    exit 1
  fi
fi

GLOBAL_PROPERTIES="$CRAFTER_SCRIPTS_HOME"/../global.properties

MAINTAINED_BY=$(readProperty "$GLOBAL_PROPERTIES" "maintained-by")
DOCKER_IMAGE_PREFIX=$(readProperty "$GLOBAL_PROPERTIES" "image-prefix")

VERSION=${version:-latest}

available_versions=$(docker image ls --format='{{.Tag}}' --filter="Reference=${MAINTAINED_BY}/${DOCKER_IMAGE_PREFIX}-${INTERFACE}" | tr '\n' ' ')

# shellcheck disable=SC2068
if ! arrayContainsElement "$VERSION" ${available_versions[@]}; then
  echo -e "\nERROR:- Invalid version $VERSION" >&2
  echo -e "Could not find an image for version $VERSION\n" >&2
  exit 1
fi

volume_container=$(docker container ls -a --format='{{.Names}}' --filter="Name=${DOCKER_IMAGE_PREFIX}-${INTERFACE}-${VERSION}_Volume")
if [ -z "$volume_container" ]; then
  volume_container="${DOCKER_IMAGE_PREFIX}-${INTERFACE}-${VERSION}_Volume"
  echo -e "\nVolume container corresponding to ${DOCKER_IMAGE_PREFIX}-${INTERFACE}:${VERSION} was not found!"
  echo -e "A new volume container will be created (name= $volume_container)\n"
  docker create \
    --volume /opt/crafter/logs \
    --volume /opt/crafter/data \
    --volume /opt/crafter/backups \
    --name "${DOCKER_IMAGE_PREFIX}-${INTERFACE}-${VERSION}_Volume" tianon/true /bin/true
fi

echo "Starting container from image: ${MAINTAINED_BY}/${DOCKER_IMAGE_PREFIX}-${INTERFACE}:${VERSION}"

DOCKER_RUN_CMD="docker run --rm "

if [ "${port:-X}" = 'X' ]; then
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p 9080:9080"
else
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p ${port}:9080"
fi

if [ "${es_port:-X}" != 'X' ]; then
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p ${es_port}:9202"
fi

if [ "${deployer_port:-X}" != 'X' ]; then
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p ${deployer_port}:9192"
fi

if [ "${debug_port:-X}" != 'X' ]; then
  debug=yes
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p ${debug_port}:8000"
fi

DOCKER_RUN_CMD="${DOCKER_RUN_CMD} --volumes-from ${volume_container} ${MAINTAINED_BY}/${DOCKER_IMAGE_PREFIX}-${INTERFACE}:${VERSION}"

if [ "${debug:-no}" = 'yes' ]; then
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} debug"
fi

${DOCKER_RUN_CMD}

exit 0
