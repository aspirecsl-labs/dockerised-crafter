#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} [OVERRIDES]"
  echo ""
  echo "Start a Crafter ${INTERFACE} container"
  echo ""
  echo "Overrides:"
  echo "Allow users to override the defaults"
  echo "  Overrides are specified as \"name1=value1,name2=value2,...,nameN=valueN\""
  echo "  Supported overrides are:-"
  echo "    debug_port:     The host machine port to bind the container's Crafter engine port. Example \"debug_port=8000\""
  echo "    deployer_port:  The host machine port to bind the container's Crafter deployer port. Example \"deployer_port=9191\""
  echo "    es_port:        The host machine port to bind the container's Elasticsearch port. Example \"es_port=9201\""
  echo "    alt_id:         A programmer friendly alternate id value to set in the metadata of the container. Example \"alt_id=my.unique.container\""
  echo "    port:           The host machine port to bind the container's Crafter engine port. Example \"port=8080\""
  echo "    volume:         The container (name) from which Crafter container obtains its user data volumes. Example \"volume=crafter-auth-3.1.5-volume\""
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter authoring container start' to start a Crafter authoring container"
  echo "Use 'crafter delivery container start' to start a Crafter delivery container"
  exit 9
fi

# shellcheck source=<repo_root>/scripts/lib.sh
source "$CRAFTER_SCRIPTS_HOME"/lib.sh

if ! enumerateKeyValuePairs "$1"; then
  usage
  return 1
fi

VERSION_FILE="${CRAFTER_HOME}/${INTERFACE}/release"
IMAGE=$(readProperty "${VERSION_FILE}" "IMAGE")
VERSION=${version:-$(readProperty "${VERSION_FILE}" "VERSION")}
IMAGE_REFERENCE="${IMAGE}:${VERSION}"

if [ "${volume:-X}" = 'X' ]; then
  echo ""
  RANDOM=$(date '+%s')
  volume="cms_${INTERFACE}_vol_${RANDOM}"
  echo "No volume container specified"
  echo "Creating a volume container with name $volume"
  docker create \
    --volume /opt/crafter/data \
    --volume /opt/crafter/backups \
    --name "$volume" tianon/true /bin/true
  echo ""
fi
echo "Starting container from image: ${IMAGE}:${VERSION}"

DOCKER_RUN_CMD="docker run --rm "

if [ "${alt_id:-X}" != 'X' ]; then
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} --alt_id ALT_ID=${alt_id}"
fi
if [ "${port:-X}" = 'X' ]; then
  if [ "${INTERFACE}" = 'authoring' ]; then
    DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p 8080:8080"
  else
    DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p 9080:9080"
  fi
else
  if [ "${INTERFACE}" = 'authoring' ]; then
    DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p ${port}:8080"
  else
    DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p ${port}:9080"
  fi
fi

if [ "${es_port:-X}" != 'X' ]; then
  if [ "${INTERFACE}" = 'authoring' ]; then
    DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p ${es_port}:9201"
  else
    DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p ${es_port}:9202"
  fi
fi

if [ "${deployer_port:-X}" != 'X' ]; then
  if [ "${INTERFACE}" = 'authoring' ]; then
    DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p ${deployer_port}:9191"
  else
    DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p ${deployer_port}:9192"
  fi
fi

if [ "${debug_port:-X}" != 'X' ]; then
  debug=yes
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p ${debug_port}:8000"
fi

DOCKER_RUN_CMD="${DOCKER_RUN_CMD} --volumes-from ${volume} ${IMAGE_REFERENCE}"

if [ "${debug:-no}" = 'yes' ]; then
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} debug"
fi

${DOCKER_RUN_CMD}

exit $?