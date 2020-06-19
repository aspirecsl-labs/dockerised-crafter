#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} command"
  echo ""
  echo "Manage Crafter ${INTERFACE} images"
  echo ""
  echo "Commands:"
  echo "    build Build a Crafter ${INTERFACE} image"
  echo ""
  echo "Run '${CMD_PREFIX:-$(basename "$0")} command --help' for more information about a command."
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter authoring image' to manage Crafter authoring images"
  echo "Use 'crafter delivery image' to manage Crafter delivery images"
  echo "Use 'crafter volume-manager image' to manage Crafter delivery images"
fi

command=$1

case $command in
build)
  CMD_PREFIX="${CMD_PREFIX:-$(basename "$0")} $command"
  export CMD_PREFIX
  if [ -x "${CRAFTER_SCRIPTS_HOME}/${INTERFACE}-${command}.sh" ]; then
    # shellcheck disable=SC2068
    "${CRAFTER_SCRIPTS_HOME}/${INTERFACE}-${command}.sh" ${@:2}
  else
    # shellcheck disable=SC2068
    "${CRAFTER_SCRIPTS_HOME}/${command}.sh" ${@:2}
  fi
  ;;
*)
  usage
  exit 1
  ;;
esac
