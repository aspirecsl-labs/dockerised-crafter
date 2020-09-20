#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")}"
  echo ""
  echo "Prune unused Crafter ${INTERFACE} data volume containers and the associated local storage"
  echo ""
  echo "Overrides:"
  echo "Allow users to override the defaults"
  echo "  Overrides are specified as \"name1=value1,name2=value2,...,nameN=valueN\""
  echo "  Supported overrides are:-"
  echo "    force  Force the removal of volume containers that are still attached to the inactive crafter ${INTERFACE} containers."
  echo "           Example \"force=yes\"."
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
echo "Pruning unused Crafter ${INTERFACE} data volume containers and the associated local storage"
echo ""

DKR_ALL_VOLUME_CMD="docker container ls --all"
DKR_ALL_VOLUME_CMD="$DKR_ALL_VOLUME_CMD --format {{.Names}}"
DKR_ALL_VOLUME_CMD="$DKR_ALL_VOLUME_CMD --filter ancestor=$VOLUME_CONTAINER_IMAGE"
DKR_ALL_VOLUME_CMD="$DKR_ALL_VOLUME_CMD --filter label=container.type=CRAFTER-VOLUME"
DKR_ALL_VOLUME_CMD="$DKR_ALL_VOLUME_CMD --filter label=attaches.to=CRAFTER-${INTERFACE}"
DKR_ACTIVE_CRAFTER_CMD="docker container ls"
DKR_ACTIVE_CRAFTER_CMD="$DKR_ACTIVE_CRAFTER_CMD --format {{.ID}}"
DKR_ACTIVE_CRAFTER_CMD="$DKR_ACTIVE_CRAFTER_CMD --filter ancestor=aspirecsl/crafter-cms-${INTERFACE}"
DKR_ALL_CRAFTER_CMD="docker container ls --all"
DKR_ALL_CRAFTER_CMD="$DKR_ALL_CRAFTER_CMD --format {{.ID}}"
DKR_ALL_CRAFTER_CMD="$DKR_ALL_CRAFTER_CMD --filter ancestor=aspirecsl/crafter-cms-${INTERFACE}"

# all volume containers (derived from tianon/true image)
all_volume_containers=$($DKR_ALL_VOLUME_CMD)
IFS=" " read -r -a all_volume_containers <<<"${all_volume_containers//$'\n'/ }"

# volume containers attached to active (running) crafter containers
active_crafter_containers=$($DKR_ACTIVE_CRAFTER_CMD)
IFS=" " read -r -a active_crafter_containers <<<"${active_crafter_containers//$'\n'/ }"
if [ ${#active_crafter_containers[@]} -gt 0 ]; then
  active_volume_containers=$(docker container inspect --format='{{.HostConfig.VolumesFrom}}' "${active_crafter_containers[@]}" | sed -e 's/\[//g;s/\]//g;')
  IFS=" " read -r -a active_volume_containers <<<"${active_volume_containers//$'\n'/ }"
fi

# volume containers attached to active (running) and inactive (stopped) crafter containers
all_crafter_containers=$($DKR_ALL_CRAFTER_CMD)
IFS=" " read -r -a all_crafter_containers <<<"${all_crafter_containers//$'\n'/ }"
if [ ${#all_crafter_containers[@]} -gt 0 ]; then
  attached_volume_containers=$(docker container inspect --format='{{.HostConfig.VolumesFrom}}' "${all_crafter_containers[@]}" | sed -e 's/\[//g;s/\]//g;')
  IFS=" " read -r -a attached_volume_containers <<<"${attached_volume_containers//$'\n'/ }"
fi

for volume in "${all_volume_containers[@]}"; do
  if ! arrayContainsElement "${volume}" "${active_volume_containers[@]}"; then
    if [ "${force:-no}" = 'yes' ] || ! arrayContainsElement "${volume}" "${attached_volume_containers[@]}"; then
      echo "Deleting $volume and its associated storage"
      docker container rm --force "${volume}"
      rm -fr "${LOCAL_FS_MOUNT_LOC:?}/${volume}__crafter_data" "${LOCAL_FS_MOUNT_LOC:?}/${volume}__crafter_backups"
      echo ""
    else
      echo "Unable to delete $volume as it might be attached to a stopped crafter container"
      echo "Try again with 'force=yes' override to force the removal of this volume container"
      echo ""
    fi
  fi
done

shopt -s nullglob
for volume_mount in "${LOCAL_FS_MOUNT_LOC:?}"/*__crafter_data; do
  volume=${volume_mount##*/}
  # strip '__crafter_data' from the folder name
  volume=${volume/__crafter_data/}
  if ! arrayContainsElement "${volume}" "${all_volume_containers[@]}"; then
    echo "Deleting dangling data storage for $volume"
    rm -fr "$volume_mount"
    echo ""
  fi
done

for volume_mount in "${LOCAL_FS_MOUNT_LOC:?}"/*__crafter_backups; do
  volume=${volume_mount##*/}
  # strip '__crafter_backups' from the folder name
  volume=${volume/__crafter_backups/}
  if ! arrayContainsElement "${volume}" "${all_volume_containers[@]}"; then
    echo "Deleting dangling backup storage for $volume"
    rm -fr "$volume_mount"
    echo ""
  fi
done

exit 0
