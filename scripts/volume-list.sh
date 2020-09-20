#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")}"
  echo ""
  echo "List Crafter ${INTERFACE} data volume containers and the associated local storage"
  echo ""
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  exit 9
fi

# shellcheck source=<repo_root>/scripts/lib.sh
source "$CRAFTER_SCRIPTS_HOME"/lib.sh

DKR_BASE_CMD="docker container ls --all"
DKR_BASE_CMD="$DKR_BASE_CMD --filter ancestor=$VOLUME_CONTAINER_IMAGE"
DKR_BASE_CMD="$DKR_BASE_CMD --filter label=container.type=CRAFTER-VOLUME"
DKR_BASE_CMD="$DKR_BASE_CMD --filter label=attaches.to=CRAFTER-${INTERFACE}"
DKR_ID_CMD="$DKR_BASE_CMD --format {{.ID}}"
DKR_NAMES_CMD="$DKR_BASE_CMD --format {{.Names}}"

volume_container_names=$($DKR_NAMES_CMD)
IFS=" " read -r -a volume_container_names <<<"${volume_container_names//$'\n'/ }"

volume_container_ids=$($DKR_ID_CMD)
IFS=" " read -r -a volume_container_ids <<<"${volume_container_ids//$'\n'/ }"

if [ ${#volume_container_names[@]} -gt 0 ]; then
  echo ""
  awk -F"," \
    '{ printf "%-16s %-32s %-8s %-8s %-48s\n", $1, $2, $3, $4, $5}' \
    <<<"Id,Name,Data,Backup,Container Start Override String"

  counter=0
  shopt -s nullglob
  for volume in "${volume_container_names[@]}"; do
    if [ -d "${LOCAL_FS_MOUNT_LOC:?}/${volume}__crafter_data" ]; then
      dataSize=$(du -c -m -h "${LOCAL_FS_MOUNT_LOC:?}/${volume}__crafter_data" | tail -n1 | awk '{print $1}')
    fi
    if [ -d "${LOCAL_FS_MOUNT_LOC:?}/${volume}__crafter_backups" ]; then
      backupSize=$(du -c -m -h "${LOCAL_FS_MOUNT_LOC:?}/${volume}__crafter_backups" | tail -n1 | awk '{print $1}')
    fi
    awk -F"," \
      '{ printf "%-16s %-32s %-8s %-8s %-48s\n", $1, $2, $3, $4, $5}' \
      <<<"${volume_container_ids[$counter]},${volume},${dataSize:-0B},${backupSize:-0B},volume=${volume}"
    counter=$((counter + 1))
  done

  echo ""
  echo "Crafter volumes are persisted locally at: ${LOCAL_FS_MOUNT_LOC:?}"
  echo ""
else
  echo ""
  echo "No crafter $INTERFACE volumes found."
  echo ""
fi

exit 0
