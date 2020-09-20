# shellcheck shell=bash

arrayContainsElement() {
  local element
  for element in "${@:2}"; do
    [[ "$element" == "$1" ]] && return 0
  done
  return 1
}

createNetworkAndAttachCrafterContainer() {
  local _container="$2"
  local _alias="${3:-crafter}"
  local random
  random=$(date '+%s')
  local _network="${1}_${random}"
  docker network create "${_network}" >/dev/null
  sleep 1s
  docker network connect --alias "${_alias}" --alias "${_container}" "${_network}" "${_container}" >/dev/null
  sleep 1s
  echo "${_network}"
}

detachCrafterContainerAndDeleteNetwork() {
  local _network=$1
  local _container=$2
  if [ -n "$_network" ]; then
    local nw_id
    nw_id=$(docker network ls --filter name="$_network" --format '{{.ID}}')
    if [ -n "$nw_id" ]; then
      sleep 1s
      docker network disconnect --force "${nw_id}" "${_container}" >/dev/null
      sleep 1s
      docker network rm "${nw_id}" >/dev/null
    fi
  fi
}

enumerateKeyValuePairs() {
  local overrides_regex='^([_a-z]*=[-._0-9a-zA-Z]*,)*[_a-z]*=[-._0-9a-zA-Z]*$'
  if [[ $1 =~ $overrides_regex ]]; then
    IFS="," read -r -a options <<<"$1"
    for option in "${options[@]}"; do
      if [ -n "$option" ]; then
        local k
        k=$(echo "$option" | cut -d"=" -f1 | tr '[:upper:]' '[:lower:]')
        local v
        v=$(echo "$option" | cut -d"=" -f2)
        eval "$k"="$v"
      fi
    done
    return 0
  else
    if [ -n "$1" ]; then
      return 1
    else
      return 0
    fi
  fi

}

getUniqueRunningContainer() {
  local interface="$1"
  local image_reference="$2"
  if [ "$(docker container ls --format "{{.ID}}" --filter="ancestor=${image_reference}" | wc -l)" -gt 1 ]; then
    echo "Multiple running containers found for image: ${image_reference}" >&2
    echo "Try again specifying the container id or name using \"container={id|name}\" override" >&2
    echo "To find all the running containers, run 'crafter ${interface} container show'" >&2
    return 1
  fi

  local _container
  _container=$(docker container ls --format "{{.ID}}" --filter="ancestor=${image_reference}")

  if [ -z "$_container" ]; then
    echo "ERROR: Unable to find a running Crafter ${interface} container" >&2
    echo "" >&2
    echo "To start a Crafter ${interface} container, run 'crafter ${interface} container start'" >&2
    echo "For a specific Crafter version, try again with 'version=x.y.z' override where 'x.y.z' is the required version" >&2
    return 1
  fi

  echo "$_container"
  return 0
}

input() {
  local label=$1
  local nullable=$2
  local sensitive=$3
  local response
  if [ "${sensitive:-n}" = "y" ]; then
    read -r -s -p "${label}  " response
  else
    read -r -p "${label}  " response
  fi
  while [ "${nullable:-y}" = 'n' ] && [ -z "$response" ]; do
    echo -e "\nInvalid response!" >&2
    echo "Must not be empty" >&2
    echo -e "Please try again.\n" >&2
    if [ "${sensitive:-n}" = "y" ]; then
      read -r -s -p "${label}  " response
    else
      read -r -p "${label}  " response
    fi
  done
  echo "$response"
  return 0
}

validatedInput() {
  local label=$1
  local nullable=$2
  local sensitive=$3
  IFS=" " read -r -a valid_values <<<"${@:4}"
  local response
  response=$(input "$label" "$nullable" "$sensitive")
  while ! arrayContainsElement "$response" "${valid_values[@]}"; do
    echo -e "\nInvalid response!" >&2
    echo "Must be one of [${valid_values[*]}]" >&2
    echo -e "Please try again.\n" >&2
    response=$(input "$label" "$nullable" "$sensitive")
  done
  echo "$response"
  return 0
}

readProperty() {
  if [[ $# -ne 2 || ! -r $1 ]]; then
    echo "Invalid arguments or property file not readable" >&2
    return 1
  fi
  local PROP_VAL
  PROP_VAL=$(awk -F "=" \
    -v PROP_KEY="$2" \
    '{
                   if ($1 == PROP_KEY)
                   {
                     print $2;
                     exit;
                   }
                }' "$1")
  echo "${PROP_VAL}"
  return 0
}

# Global Variables
eval VOLUME_CONTAINER_IMAGE=tianon/true
eval LOCAL_FS_LIB_LOC="$HOME/lib/crafter"
eval LOCAL_FS_MOUNT_LOC="$HOME/workspace/crafter"
