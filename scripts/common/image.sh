#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} COMMAND"
  echo ""
  echo "Manages Crafter ${INTERFACE} images"
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
CMD_PREFIX="${CMD_PREFIX:-$(basename "$0")} $COMMAND"
export CMD_PREFIX

case $COMMAND in
build)
  if [ -x "${CRAFTER_SCRIPTS_HOME}/${INTERFACE}/${CONTEXT:-image}/${COMMAND}.sh" ]; then
    # shellcheck disable=SC2068
    "${CRAFTER_SCRIPTS_HOME}/${INTERFACE}/${CONTEXT:-image}/${COMMAND}.sh" ${@:2}
  else
    # shellcheck disable=SC2068
    "${CRAFTER_SCRIPTS_HOME}/common/${CONTEXT:-image}/${COMMAND}.sh" ${@:2}
  fi
  ;;
*)
  usage
  exit 1
  ;;
esac
