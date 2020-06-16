#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} COMMAND"
  echo ""
  echo "Manages Crafter ${INTERFACE} containers"
  echo ""
  echo "Commands:"
  echo "    start Start a Crafter ${INTERFACE} container"
  echo ""
  echo "Run '${CMD_PREFIX:-$(basename "$0")} COMMAND --help' for more information about a command."
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter authoring container' to manage Crafter authoring containers"
  echo "Use 'crafter delivery container' to manage Crafter delivery containers"
fi

COMMAND=$1
CMD_PREFIX="${CMD_PREFIX:-$(basename "$0")} $COMMAND"
export CMD_PREFIX

case $COMMAND in
start)
  if [ -x "${CRAFTER_SCRIPTS_HOME}/${INTERFACE}/${CONTEXT:-container}/${COMMAND}.sh" ]; then
    # shellcheck disable=SC2068
    "${CRAFTER_SCRIPTS_HOME}/${INTERFACE}/${CONTEXT:-container}/${COMMAND}.sh" ${@:2}
  else
    # shellcheck disable=SC2068
    "${CRAFTER_SCRIPTS_HOME}/common/${CONTEXT:-container}/${COMMAND}.sh" ${@:2}
  fi
  ;;
login | status | backup | restore | upgrade | version | show-backups | show-port-mappings | show-volume-container)
  if [ -x "${CRAFTER_SCRIPTS_HOME}/${INTERFACE}/${CONTEXT:-container}/manage.sh" ]; then
    # shellcheck disable=SC2068
    "${CRAFTER_SCRIPTS_HOME}/${INTERFACE}/${CONTEXT:-container}/manage.sh" "$COMMAND" ${@:2}
  else
    # shellcheck disable=SC2068
    "${CRAFTER_SCRIPTS_HOME}/common/${CONTEXT:-container}/manage.sh" "$COMMAND" ${@:2}
  fi
  ;;

*)
  usage
  exit 1
  ;;
esac
