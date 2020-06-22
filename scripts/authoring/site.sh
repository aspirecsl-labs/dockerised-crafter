#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} COMMAND name [OPTIONS]"
  echo ""
  echo "Manage the specified site on the Crafter authoring instance"
  echo ""
  echo "Commands:"
  echo "    context-status   Show the status of the specified site's context"
  echo "    create           Create a site on the container"
  echo "    destroy-context  Destroy the specified site's context"
  echo "    download         Download a site from the container to the host machine"
  echo "    rebuild-context  Rebuild the specified site's context"
  echo "    upload           Upload a site from the host machine to the container"
  echo ""
  echo "name  The name of the site to manage"
  echo ""
  echo "Options:"
  echo "Allow users to override the defaults"
  echo "    Overrides are specified as \"name1=value1,name2=value2,...,nameN=valueN\" "
  echo "    Supported overrides are:-"
  echo "        container:  The id or name of the container to manage. Example \"container=869efc01315c\" or \"container=awesome_alice\""

}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter authoring site COMMAND site_name' to manage a site on the Crafter authoring container"
fi

if [ $# -lt 2 ]; then
  usage
  exit 1
fi

if ! enumerateKeyValuePairs "$3"; then
  usage
  return 1
fi

# shellcheck source=<repo_root>/scripts/functions.sh
source "$CRAFTER_SCRIPTS_HOME"/functions.sh

command=$1
site=$2
