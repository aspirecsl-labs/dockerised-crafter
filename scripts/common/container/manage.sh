#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} OPTIONS"
  echo ""
  echo "Manages a running Crafter ${INTERFACE} container"
  echo ""
  echo "Commands:"
  echo "    backup                 Build a Crafter ${INTERFACE} image"
  echo "    login                  Build a Crafter ${INTERFACE} image"
  echo "    restore                Build a Crafter ${INTERFACE} image"
  echo "    status                 Build a Crafter ${INTERFACE} image"
  echo "    show-backups           Build a Crafter ${INTERFACE} image"
  echo "    show-port-mappings     Build a Crafter ${INTERFACE} image"
  echo "    show-volume-container  Build a Crafter ${INTERFACE} image"
  echo "    upgrade                Build a Crafter ${INTERFACE} image"
  echo "    version                Build a Crafter ${INTERFACE} image"
  echo ""
  echo "Options:"
  echo "-o|--overrides Allows users to override defaults"
  echo "    Overrides are specified as \"name1=value1,name2=value2,...,nameN=valueN\" "
  echo "    Supported overrides are:-"
  echo "        container_id:  The id of the container to manage. Example \"container_id=869efc01315c\" "
  echo "        version:       The Crafter version. Example \"version=3.1.7\" "
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

if [ "$2" = '--options' ] || [ "$2" = '-o' ]; then
  enumerateOptions "$2"
else
  if [ -n "$2" ]; then
    usage
    exit 1
  fi
fi

GLOBAL_PROPERTIES="$CRAFTER_SCRIPTS_HOME"/../global.properties

MAINTAINED_BY=$(readProperty "$GLOBAL_PROPERTIES" "maintained-by")
DOCKER_IMAGE_PREFIX=$(readProperty "$GLOBAL_PROPERTIES" "image-prefix")
VERSION=${version:-latest}
IMAGE_REFERENCE="${MAINTAINED_BY}/${DOCKER_IMAGE_PREFIX}-${INTERFACE}:${VERSION}"

if [ "$(docker container ls --filter="ancestor=${IMAGE_REFERENCE}" | wc -l)" -gt 1 ]; then
  echo "Multiple running containers found for image: ${IMAGE_REFERENCE}"
  echo "Try again specifying the container id using \"container_id={id}\" override"
  exit 0
fi

container_id=${container_id:-$(docker container ls --format "{{.ID}}" --filter="ancestor=${IMAGE_REFERENCE}")}
command=$1
case $command in
login)
  docker exec -it "$container_id" "/docker-entrypoint.sh" /bin/bash
  ;;
show-port-mappings)
  echo -e "\n"
  docker port "${container_id}"
  echo -e "\n"
  ;;
show-volume-container)
  echo -e "\n"
  docker port "${container_id}"
  echo -e "\n"
  ;;
status | backup | restore | upgrade | version | show-backups)
  docker exec -it "$container_id" "/docker-entrypoint.sh" "$command"
  ;;
*)
  usage
  exit 1
  ;;
esac

exit 0
