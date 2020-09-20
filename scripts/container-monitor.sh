#!/bin/bash
set -e

usage() {
  local CMD_SUMMARY
  case $command in
  copy-libs)
    CMD_SUMMARY="Copy the Crafter ${INTERFACE} assets and the relevant third-party jars to local machine"
    ;;
  log)
    CMD_SUMMARY="Show the Crafter ${INTERFACE} container log"
    ;;
  port)
    CMD_SUMMARY="Show the port bindings of the Crafter ${INTERFACE} container"
    ;;
  list)
    CMD_SUMMARY="List all the running Crafter ${INTERFACE} containers"
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

# source=<repo_root>/scripts/lib.sh
# shellcheck disable=SC1090
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

if [ "$command" = 'list' ]; then
  echo ""
  docker container ls --format "table {{.ID}}\t{{.Names}}\t{{.Label \"Tag\"}}\t{{.Status}}\t{{.RunningFor}}\t{{.Ports}}" --filter="ancestor=${IMAGE_REFERENCE}"
  echo ""
  exit 0
fi

if [ -z "$container" ]; then
  if ! container=$(getUniqueRunningContainer "${INTERFACE}" "${IMAGE_REFERENCE}"); then
    exit 1
  fi
fi

case $command in
copy-libs)
  host_lib_loc="${LOCAL_FS_LIB_LOC:?}/${INTERFACE}"
  if [ -n "$version" ]; then
    host_lib_loc="${host_lib_loc}-${version}"
  fi
  if [ -d "$host_lib_loc" ]; then
    echo ""
    echo "ERROR: $host_lib_loc exists." >&2
    echo "Try again after deleting $host_lib_loc" >&2
    echo ""
    exit 1
  fi
  mkdir -p "$host_lib_loc"

  echo ""
  echo "Copying crafter assets and the relevant third-party jars..."

  docker cp "${container}":/opt/crafter/bin/groovy "$host_lib_loc"
  docker cp "${container}":/opt/crafter/bin/apache-tomcat/lib "$host_lib_loc"/tomcat
  docker cp "${container}":/opt/crafter/bin/apache-tomcat/webapps/ROOT/WEB-INF "$host_lib_loc"/ROOT
  docker cp "${container}":/opt/crafter/bin/apache-tomcat/webapps/crafter-search/WEB-INF "$host_lib_loc"/crafter-search

  if [ "${INTERFACE}" = 'authoring' ]; then
    docker cp "${container}":/opt/crafter/bin/apache-tomcat/webapps/studio/WEB-INF "$host_lib_loc"/studio
  fi

  echo ""
  echo "Crafter assets and the relevant third-party jars copied to ${host_lib_loc}"
  echo ""
  ;;
log)
  docker container logs "$container"
  ;;
port)
  echo -e "\nPort bindings:"
  docker port "${container}"
  echo ""
  ;;
volume)
  echo ""
  echo "Volume container: $(docker container inspect --format='{{.HostConfig.VolumesFrom}}' "${container}")"
  echo ""
  ;;
*)
  usage
  exit 1
  ;;
esac

exit 0
