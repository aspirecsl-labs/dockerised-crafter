#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} COMMAND"
  echo ""
  echo "Manage Crafter ${INTERFACE} containers"
  echo ""
  echo "Commands:"
  echo "(when a Crafter ${INTERFACE} container is not running)"
  echo "  start      Start a Crafter ${INTERFACE} container"
  echo "(when a Crafter ${INTERFACE} container is running)"
  echo "  backup     Backup the data in the Crafter ${INTERFACE} container"
  echo "  copy-libs  Copy the Crafter ${INTERFACE} assets and the relevant third-party jars to local machine"
  echo "  list       List all the running Crafter ${INTERFACE} containers"
  echo "  log        Show the Crafter ${INTERFACE} container log"
  echo "  login      Login to the Crafter ${INTERFACE} container"
  echo "  mode       Show the operational mode of the Crafter ${INTERFACE} container"
  echo "  port       Show the port bindings of the Crafter ${INTERFACE} container"
  echo "  recovery   Start the Crafter ${INTERFACE} container in recovery mode."
  echo "             No crafter services are started in this mode."
  echo "  status     Show the status of the Crafter ${INTERFACE} container"
  echo "  version    Show the Crafter ${INTERFACE} version of the container"
  echo "  volume     Show the volume container attached to the Crafter ${INTERFACE} container"
  echo ""
  echo "Run '${CMD_PREFIX:-$(basename "$0")} COMMAND --help' for more information about a command."
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter authoring container' to manage Crafter authoring containers"
  echo "Use 'crafter delivery container' to manage Crafter delivery containers"
  exit 9
fi

command=$1
CMD_PREFIX="${CMD_PREFIX:-$(basename "$0")} $command"
export CMD_PREFIX

case $command in
start)
  "${CRAFTER_SCRIPTS_HOME}/${CONTEXT}-start.sh" "${2}"
  ;;
copy-libs | list | log | port | volume)
  "${CRAFTER_SCRIPTS_HOME}/${CONTEXT}-monitor.sh" "$command" "${2}"
  ;;
backup | login | recovery | status | version)
  "${CRAFTER_SCRIPTS_HOME}/${CONTEXT}-executor.sh" "$command" "${2}"
  ;;
*)
  usage
  exit 1
  ;;
esac
