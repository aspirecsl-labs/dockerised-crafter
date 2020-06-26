#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")}"
  echo ""
  echo "Create a Crafter ${INTERFACE} data volume container"
  echo ""
  echo "Overrides:"
  echo "Allow users to override the defaults"
  echo "  Overrides are specified as \"name1=value1,name2=value2,...,nameN=valueN\""
  echo "  Supported overrides are:-"
  echo "    prefix  The prefix to use while naming the volume container. Example \"prefix=my_data_volume\"."
  echo "            Docker recommends words made from lowercase letters and numbers separated by underscores as container names."
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter authoring container start' to start a Crafter authoring container"
  echo "Use 'crafter delivery container start' to start a Crafter delivery container"
  exit 9
fi

# shellcheck source=<repo_root>/scripts/lib.sh
source "$CRAFTER_SCRIPTS_HOME"/lib.sh

if ! enumerateKeyValuePairs "$1"; then
  usage
  exit 1
fi

echo ""
echo "Creating a Crafter ${INTERFACE} data volume container"
RANDOM=$(date '+%s')
prefix=${prefix:-cms_${INTERFACE}_vol}
if ! [[ $prefix =~ ^[_a-z0-9]+$ ]]; then
  usage
  exit 1
fi
volume="${prefix}_${RANDOM}"
mkdir -p "${CRAFTER_HOME}/workspace/${volume}_data" "${CRAFTER_HOME}/workspace/${volume}_backups"
docker create \
  --env TZ=Europe/London \
  --label container.type="CRAFTER-VOLUME" \
  --label attaches.to="CRAFTER-${INTERFACE}" \
  --volume "${CRAFTER_HOME}/workspace/${volume}_data":/opt/crafter/data \
  --volume "${CRAFTER_HOME}/workspace/${volume}_backups":/opt/crafter/backups \
  --name "$volume" tianon/true /bin/true
echo ""

echo "Crafter ${INTERFACE} data volume container successfully created"
echo ""
docker container ls -a --filter="name=$volume" --format "table {{.ID}}\t{{.Names}}"
echo ""
echo "Crafter ${INTERFACE} containers using this volume will persist their sites and backups to"
echo "'${CRAFTER_HOME}/workspace/${volume}_data' and "
echo "'${CRAFTER_HOME}/workspace/${volume}_backups' folders"
echo ""
exit $?
