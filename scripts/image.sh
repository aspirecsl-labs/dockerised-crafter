#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} COMMAND"
  echo ""
  echo "Manage Crafter ${INTERFACE} images"
  echo ""
  echo "Commands:"
  echo "    build Build a Crafter ${INTERFACE} image"
  echo ""
  echo "Run '${CMD_PREFIX:-$(basename "$0")} COMMAND --help' for more information about a command."
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter authoring image' to manage Crafter authoring images"
  echo "Use 'crafter delivery image' to manage Crafter delivery images"
fi

COMMAND=$1

case $COMMAND in
build)
  CMD_PREFIX="${CMD_PREFIX:-$(basename "$0")} $COMMAND"
  export CMD_PREFIX
  # shellcheck disable=SC2068
  "${CRAFTER_SCRIPTS_HOME}/${COMMAND}.sh" ${@:2}
  ;;
*)
  usage
  exit 1
  ;;
esac