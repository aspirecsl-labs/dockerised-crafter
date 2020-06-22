#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} CONTEXT"
  echo ""
  echo "Manage Crafter ${INTERFACE} images and containers"
  echo ""
  echo "Contexts:"
  echo "    container Manage Crafter ${INTERFACE} containers"
  echo "    site      Manage Crafter ${INTERFACE} sites"
  echo ""
  echo "Run '${CMD_PREFIX:-$(basename "$0")} CONTEXT --help' for more information about the commands available to a context."
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter authoring' to manage a Crafter authoring interface"
  echo "Use 'crafter delivery' to manage a Crafter delivery interface"
fi

case $1 in
image | container)
  context=$1
  export context
  CMD_PREFIX="${CMD_PREFIX:-$(basename "$0")} $1"
  export CMD_PREFIX
  if [ -x "${CRAFTER_SCRIPTS_HOME}/${INTERFACE}/${context}.sh" ]; then
    # shellcheck disable=SC2068
    "${CRAFTER_SCRIPTS_HOME}/${INTERFACE}/${context}.sh" ${@:2}
  else
    # shellcheck disable=SC2068
    "${CRAFTER_SCRIPTS_HOME}/${context}.sh" ${@:2}
  fi
  ;;
*)
  usage
  exit 1
  ;;
esac
