#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} COMMAND"
  echo ""
  echo "Manage Crafter ${INTERFACE} data volume containers"
  echo ""
  echo "Data volume containers allow 'data' and 'backups' folders in the Crafter ${INTERFACE} container to persist container shutdowns"
  echo ""
  echo "Commands:"
  echo "  create  Create a Crafter ${INTERFACE} data volume container"
  echo "  list    List all the Crafter ${INTERFACE} data volume containers"
  echo "  prune   Prune unused Crafter ${INTERFACE} data volume containers and the associated local directories"
  echo ""
  echo "Run '${CMD_PREFIX:-$(basename "$0")} COMMAND --help' for more information about a command."
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter authoring volume' to manage Crafter authoring data volume containers"
  echo "Use 'crafter delivery volume' to manage Crafter delivery data volume containers"
  exit 9
fi

command=$1

case $command in
create | list | prune)
  CMD_PREFIX="${CMD_PREFIX:-$(basename "$0")} $command"
  export CMD_PREFIX
  "${CRAFTER_SCRIPTS_HOME}/${CONTEXT}-${command}.sh" "${2}"
  ;;
*)
  usage
  exit 1
  ;;
esac
