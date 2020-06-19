#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} command"
  echo ""
  echo "Manage Crafter ${INTERFACE} containers"
  echo ""
  echo "Commands:"
  echo "(when a Crafter ${INTERFACE} container is not running)"
  echo "    start    Start a Crafter ${INTERFACE} container"
  echo "(when a Crafter ${INTERFACE} container is running)"
  echo "    backup   Backup the data in the Crafter ${INTERFACE} container"
  echo "    login    Login to the Crafter ${INTERFACE} container"
  echo "    port     Show the port bindings of the Crafter ${INTERFACE} container"
  echo "    restore  Restore the data in the Crafter ${INTERFACE} container"
  echo "    show     Show all the running Crafter ${INTERFACE} containers"
  echo "    status   Show the status of the Crafter ${INTERFACE} container"
  echo "    version  Show the Crafter ${INTERFACE} version of the container"
  echo "    volume   Show the volume container attached to the Crafter ${INTERFACE} container"
  echo ""
  echo "Run '${CMD_PREFIX:-$(basename "$0")} command --help' for more information about a command."
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter authoring container' to manage Crafter authoring containers"
  echo "Use 'crafter delivery container' to manage Crafter delivery containers"
fi

command=$1

case $command in
backup | login | port | restore | show | start | status | version | volume)
  CMD_PREFIX="${CMD_PREFIX:-$(basename "$0")} $command"
  export CMD_PREFIX
  if [ -x "${CRAFTER_SCRIPTS_HOME}/${command}.sh" ]; then
    # shellcheck disable=SC2068
    "${CRAFTER_SCRIPTS_HOME}/${command}.sh" ${@:2}
  else
    # shellcheck disable=SC2068
    "${CRAFTER_SCRIPTS_HOME}/executor.sh" "$command" ${@:2}
  fi
  ;;
*)
  usage
  exit 1
  ;;
esac
