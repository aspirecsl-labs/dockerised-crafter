#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} command"
  echo ""
  echo "Manage Crafter ${INTERFACE} containers"
  echo ""
  echo "Commands:"
  echo "    site  Transfer site data between a Crafter container and the host system"
  echo ""
  echo "Run '${CMD_PREFIX:-$(basename "$0")} command --help' for more information about a command."
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter volume-manager container' to manage Crafter authoring containers"
fi

command=$1

case $command in
site)
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
