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
  echo "            Only lowercase letters, numbers and underscores are allowed in the prefix."
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
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
prefix=${prefix:-crafter_${INTERFACE}_vol}
if ! [[ $prefix =~ ^[_a-z0-9]+$ ]]; then
  usage
  exit 1
fi
volume="${prefix}_${RANDOM}"
local_crafter_data="${LOCAL_FS_MOUNT_LOC:?}/${volume}__crafter_data"
local_crafter_backups="${LOCAL_FS_MOUNT_LOC:?}/${volume}__crafter_backups"
mkdir -p "$local_crafter_data" "$local_crafter_backups"
docker create \
  --env TZ=Europe/London \
  --label container.type="CRAFTER-VOLUME" \
  --label attaches.to="CRAFTER-${INTERFACE}" \
  --volume "$local_crafter_data":/opt/crafter/data \
  --volume "$local_crafter_backups":/opt/crafter/backups \
  --name "$volume" "$VOLUME_CONTAINER_IMAGE" /bin/true
echo ""

echo "Crafter ${INTERFACE} data volume container successfully created"
echo ""
docker container ls -a --filter="name=$volume" --format "table {{.ID}}\t{{.Names}}"
echo ""
echo "Crafter ${INTERFACE} containers using this volume will persist their"
echo "   * data in [$local_crafter_data], and"
echo "   * backups in [$local_crafter_backups]"
echo ""
exit $?
