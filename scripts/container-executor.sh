#!/bin/bash
set -e

usage() {
  case $command in
  backup)
    CMD_SUMMARY="Backup the data in the Crafter ${INTERFACE} container"
    ;;
  login)
    CMD_SUMMARY="Login to the Crafter ${INTERFACE} container"
    ;;
  mode)
    CMD_SUMMARY="Show the operational mode of the Crafter ${INTERFACE} container"
    ;;
  port)
    CMD_SUMMARY="Show the port bindings of the Crafter ${INTERFACE} container"
    ;;
  recovery)
    CMD_SUMMARY="Start the Crafter ${INTERFACE} container in recovery mode (CLI access)."
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
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} [OVERRIDES]"
  echo ""
  echo "$CMD_SUMMARY"
  echo ""
  echo "Overrides:"
  echo "Allow users to override the defaults"
  echo "  Overrides are specified as \"name1=value1,name2=value2,...,nameN=valueN\""
  echo "  Supported overrides are:-"
  echo "    container:  The id or name of the container to manage. Example \"container=869efc01315c\" or \"container=awesome_alice\""
  echo "    version:    The Crafter version to use instead of default. Example \"version=3.1.7\" "
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter authoring container command' to run a command on the Crafter authoring container"
  echo "Use 'crafter delivery container command' to run a command on the Crafter delivery container"
  exit 9
fi

# shellcheck source=<repo_root>/scripts/lib.sh
source "$CRAFTER_SCRIPTS_HOME"/lib.sh

command=$1
if ! enumerateKeyValuePairs "$2"; then
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

if [ "$command" = 'show' ]; then
  echo ""
  docker container ls --format "table {{.ID}}\t{{.Names}}\t{{.Label \"ALT_ID\"}}\t{{.Status}}\t{{.RunningFor}}" --filter="ancestor=${IMAGE_REFERENCE}"
  echo ""
  exit 0
fi

if ! container=$(getUniqueRunningContainer "${INTERFACE}" "${IMAGE_REFERENCE}"); then
  exit 1
fi

case $command in
login)
  docker exec -it "$container" "/docker-entrypoint.sh" /bin/bash
  ;;
port)
  echo -e "\nPort bindings:"
  docker port "${container}"
  echo ""
  ;;
volume)
  echo ""
  echo "Volume container: $(docker inspect "${container}" --format='{{.HostConfig.VolumesFrom}}')"
  echo ""
  ;;
backup | mode | recovery | status | version)
  if [ "$command" = 'status' ]; then
    echo -e "\n------------------------------------------------------------------------"
    echo "Crafter ${INTERFACE} container status"
    echo "------------------------------------------------------------------------"
    docker stats --no-stream --format "table {{.CPUPerc}}\t{{.MemPerc}}\t{{.MemUsage}}" "$container"
  fi
  docker exec -it "$container" "/docker-entrypoint.sh" "$command"
  ;;
*)
  usage
  exit 1
  ;;
esac

exit 0
