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
  echo "    alt_id:         A programmer friendly alternate id value to set in the metadata of the container. Example \"alt_id=my.unique.container\""
  echo "    debug_port:     The host machine port to bind the container's Crafter engine port. Example \"debug_port=8000\""
  echo "    deployer_port:  The host machine port to bind the container's Crafter deployer port. Example \"deployer_port=9191\""
  echo "    es_port:        The host machine port to bind the container's Elasticsearch port. Example \"es_port=9201\""
  echo "    http_port:      The host machine port to bind the container's HTTP (80) port. Example \"http_port=1080\""
  echo "    https_port:     The host machine port to bind the container's HTTPS (443) port. Example \"https_port=10443\""
  echo "    mode:           The container start mode. Allowed values are 'demo' (default) and 'dev'. Example \"mode=dev\""
  echo "                    In 'demo' mode if a volume container is not specified then the 'data' and 'backups' folder in the "
  echo "                    Crafter ${INTERFACE} container are bound to the container lifecycle."
  echo "                    In 'dev' mode if a volume container is not specified then a new one is created so that the 'data' "
  echo "                    and 'backups' folder in the Crafter ${INTERFACE} container can persist a container shutdown."
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
  exit 1
fi

mode=${mode:-demo}
allowed_modes=(demo dev)
if ! arrayContainsElement "${mode}" "${allowed_modes[@]}"; then
  usage
  exit 1
fi
CONTAINER_MODE="${mode}"
export CONTAINER_MODE

IMAGE=aspirecsl/crafter-cms-${INTERFACE}
# shellcheck disable=SC2154
# version may be specified as an option from the command line
if [ -n "$version" ]; then
  eval IMAGE_REFERENCE="${IMAGE}:${version}"
else
  eval IMAGE_REFERENCE="${IMAGE}"
fi

echo "Starting container from image: ${IMAGE_REFERENCE}"

DOCKER_RUN_CMD="docker run --rm --env TZ=Europe/London --env CONTAINER_MODE"

if [ "${volume:-X}" = 'X' ]; then
  if [ "${mode}" = 'dev' ]; then
    echo ""
    RANDOM=$(date '+%s')
    volume="crafter_${INTERFACE}_vol_${RANDOM}"
    echo "No volume container specified"
    echo "Creating a volume container with name $volume"
    mkdir -p "${CRAFTER_HOME}/workspace/${volume}_data" "${CRAFTER_HOME}/workspace/${volume}_backups"
    docker create \
      --env TZ=Europe/London \
      --label container.type="CRAFTER-VOLUME" \
      --label attaches.to="CRAFTER-${INTERFACE}" \
      --volume "${CRAFTER_HOME}/workspace/${volume}_data":/opt/crafter/data \
      --volume "${CRAFTER_HOME}/workspace/${volume}_backups":/opt/crafter/backups \
      --name "$volume" tianon/true /bin/true
    echo ""
    DOCKER_RUN_CMD="${DOCKER_RUN_CMD} --volumes-from ${volume}"
  fi
else
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} --volumes-from ${volume}"
fi

if [ "${alt_id:-X}" != 'X' ]; then
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} --alt_id ALT_ID=${alt_id}"
fi

if [ "${http_port:-X}" = 'X' ]; then
  if [ "${INTERFACE}" = 'authoring' ]; then
    DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p 80:80"
  else
    DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p 10080:80"
  fi
else
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p ${http_port}:80"
fi

if [ "${https_port:-X}" = 'X' ]; then
  if [ "${INTERFACE}" = 'authoring' ]; then
    DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p 443:443"
  else
    DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p 10443:443"
  fi
else
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p ${https_port}:443"
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

DOCKER_RUN_CMD="${DOCKER_RUN_CMD} ${IMAGE_REFERENCE}"

if [ "${debug:-no}" = 'yes' ]; then
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} debug"
fi

${DOCKER_RUN_CMD}

exit $?
