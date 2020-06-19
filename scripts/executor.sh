#!/bin/bash
set -e

usage() {
  case $command in
  backup)
    CMD_SUMMARY="Backup the data in the Crafter ${INTERFACE} container"
    ;;
  login)
    CMD_SUMMARY="Login to the specified crafter container"
    ;;
  port)
    CMD_SUMMARY="Show the port bindings of the specified crafter container"
    ;;
  restore)
    CMD_SUMMARY="Restore the data in the Crafter ${INTERFACE} container"
    ;;
  show)
    CMD_SUMMARY="Show all the running Crafter ${INTERFACE} containers"
    ;;
  status)
    CMD_SUMMARY="Show the status of the specified crafter container"
    ;;
  version)
    CMD_SUMMARY="Show the crafter version of the specified container"
    ;;
  volume)
    CMD_SUMMARY="Show the volume container attached to the specified crafter container"
    ;;
  esac
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} OPTIONS"
  echo ""
  echo "$CMD_SUMMARY"
  echo ""
  echo "Container "
  echo ""
  echo "Options:"
  echo "-o|--overrides Allows users to override defaults"
  echo "    Overrides are specified as \"name1=value1,name2=value2,...,nameN=valueN\" "
  echo "    Supported overrides are:-"
  echo "        container:  The id or name of the container to manage. Example \"container=869efc01315c\" or \"container=awesome_alice\""
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter authoring image build' to build a Crafter authoring image"
  echo "Use 'crafter delivery image build' to build a Crafter delivery image"
fi

# shellcheck source=<repo_root>/scripts/functions.sh
source "$CRAFTER_SCRIPTS_HOME"/functions.sh

command=$1
if [ "$2" = '--overrides' ] || [ "$2" = '-o' ]; then
  enumerateOptions "$3"
else
  if [ -n "$2" ]; then
    usage
    exit 1
  fi
fi

VERSION_FILE="${CRAFTER_HOME}/${INTERFACE}/release"
IMAGE=$(readProperty "${VERSION_FILE}" "IMAGE")
VERSION=$(readProperty "${VERSION_FILE}" "VERSION")
IMAGE_REFERENCE="${IMAGE}:${VERSION}"

# shellcheck disable=SC2154
# container may be specified as an option from the command line
if [ -z "${container}" ] && [ "$(docker container ls --format "{{.ID}}" --filter="ancestor=${IMAGE_REFERENCE}" | wc -l)" -gt 1 ]; then
  echo "Multiple running containers found for image: ${IMAGE_REFERENCE}"
  echo "Try again specifying the container id or name using \"container={id|name}\" override"
  echo "To find all the running containers, run 'crafter authoring container show'"
  exit 1
fi

container=${container:-$(docker container ls --format "{{.ID}}" --filter="ancestor=${IMAGE_REFERENCE}")}

if [ -z "$container" ]; then
  echo "ERROR: Unable to find a running Crafter ${INTERFACE} container"
  echo "To start a Crafter ${INTERFACE} container, run 'crafter authoring container start'"
  exit 1
fi

case $command in
login)
  docker exec -it "$container" "/docker-entrypoint.sh" /bin/bash
  ;;
port)
  echo -e "\nPort bindings:"
  docker port "${container}"
  echo -e "\n"
  ;;
show)
  echo -e "\n"
  docker container ls --format "table {{.ID}}\t{{.Names}}\t{{.Label \"ALT_ID\"}}\t{{.Status}}\t{{.RunningFor}}" --filter="ancestor=${IMAGE_REFERENCE}"
  echo -e "\n"
  ;;
volume)
  echo -e "\n"
  echo "Volume container: $(docker inspect "${container}" --format='{{.HostConfig.VolumesFrom}}')"
  echo -e "\n"
  ;;
backup | restore | status | version)
  docker exec -it "$container" "/docker-entrypoint.sh" "$command"
  ;;
*)
  usage
  exit 1
  ;;
esac

exit 0
