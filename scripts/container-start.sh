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
  echo "    http_port:      The host machine port to bind the container's HTTP (80) port. Example \"http_port=1080\""
  echo "    https_port:     The host machine port to bind the container's HTTPS (443) port. Example \"https_port=10443\""
  echo "    tag:            The programmer friendly tag to set in the metadata of the container. Example \"label=my.unique.container\""
  echo "    volume:         The container (name) from which Crafter container obtains its user data volumes. Example \"volume=crafter-auth-3.1.5-volume\""
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  exit 9
fi

# shellcheck source=<repo_root>/scripts/lib.sh
source "$CRAFTER_SCRIPTS_HOME"/lib.sh

if ! enumerateKeyValuePairs "$1"; then
  usage
  exit 1
fi

IMAGE=aspirecsl/crafter-cms-${INTERFACE}
# shellcheck disable=SC2154
# version may be specified as an option from the command line
if [ -n "$version" ]; then
  eval IMAGE_REFERENCE="${IMAGE}:${version}"
else
  eval IMAGE_REFERENCE="${IMAGE}"
fi

echo "Starting container from image: ${IMAGE_REFERENCE}"

DOCKER_RUN_CMD="docker run"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD --rm"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD --env TZ=Europe/London"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD --env CRAFTER_ENVIRONMENT=local"
DOCKER_RUN_CMD="$DOCKER_RUN_CMD --hostname ${INTERFACE}"

if [ "${volume:-X}" = 'X' ]; then
  echo ""
  RANDOM=$(date '+%s')
  volume="crafter_${INTERFACE}_vol_${RANDOM}"
  echo "No volume container specified"
  echo "Creating a volume container with name $volume"
  local_crafter_data="${LOCAL_FS_MOUNT_LOC:?}/${volume}__crafter_data"
  local_crafter_backups="${LOCAL_FS_MOUNT_LOC:?}/${volume}__crafter_backups"
  mkdir -p "$local_crafter_data" "$local_crafter_backups"
  DOCKER_VOLUME_CRE_CMD="docker create"
  DOCKER_VOLUME_CRE_CMD="$DOCKER_VOLUME_CRE_CMD --env TZ=Europe/London"
  DOCKER_VOLUME_CRE_CMD="$DOCKER_VOLUME_CRE_CMD --label container.type=CRAFTER-VOLUME"
  DOCKER_VOLUME_CRE_CMD="$DOCKER_VOLUME_CRE_CMD --label attaches.to=CRAFTER-${INTERFACE}"
  if [ "${tag:-X}" != 'X' ]; then
    DOCKER_VOLUME_CRE_CMD="$DOCKER_VOLUME_CRE_CMD --label crafter.container.tag=$tag"
  fi
  DOCKER_VOLUME_CRE_CMD="$DOCKER_VOLUME_CRE_CMD --volume ${local_crafter_data}:/opt/crafter/data"
  DOCKER_VOLUME_CRE_CMD="$DOCKER_VOLUME_CRE_CMD --volume ${local_crafter_backups}:/opt/crafter/backups"
  DOCKER_VOLUME_CRE_CMD="$DOCKER_VOLUME_CRE_CMD --name $volume $VOLUME_CONTAINER_IMAGE /bin/true"
  $DOCKER_VOLUME_CRE_CMD
  echo "Crafter data directory is     :  [$local_crafter_data]"
  echo "Crafter backups directory is  :  [$local_crafter_backups]"
  echo ""
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} --volumes-from ${volume}"
else
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} --volumes-from ${volume}"
fi

if [ "${tag:-X}" != 'X' ]; then
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} --label Tag=${tag}"
fi

if [ "${http_port:-X}" = 'X' ]; then
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p 80:80"
else
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p ${http_port}:80"
fi

if [ "${https_port:-X}" = 'X' ]; then
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p 443:443"
else
  DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p ${https_port}:443"
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
