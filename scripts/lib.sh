arrayContainsElement() {
  local element
  for element in "${@:2}"; do
    [[ "$element" == "$1" ]] && return 0
  done
  return 1
}

enumerateKeyValuePairs() {
  overrides_regex='^([.-_a-zA-Z0-9]+=[.-_a-zA-Z0-9]+,)*[.-_a-zA-Z0-9]+=[.-_a-zA-Z0-9]+$'
  if [[ $1 =~ $overrides_regex ]]; then
    IFS="," read -r -a options <<<"$1"
    for option in "${options[@]}"; do
      if [ -n "$option" ]; then
        k=$(echo "$option" | cut -d"=" -f1 | tr '[:upper:]' '[:lower:]')
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
  # shellcheck disable=SC2154
  # container may be specified as an option from the command line
  if [ -z "${container}" ] && [ "$(docker container ls --format "{{.ID}}" --filter="ancestor=${image_reference}" | wc -l)" -gt 1 ]; then
    echo "Multiple running containers found for image: ${image_reference}" >&2
    echo "Try again specifying the container id or name using \"container={id|name}\" override" >&2
    echo "To find all the running containers, run 'crafter ${interface} container show'" >&2
    return 1
  fi

  container=${container:-$(docker container ls --format "{{.ID}}" --filter="ancestor=${image_reference}")}

  if [ -z "$container" ]; then
    echo "ERROR: Unable to find a running Crafter ${interface} container" >&2
    echo "" >&2
    echo "To start a Crafter ${interface} container, run 'crafter authoring container start'" >&2
    echo "For a specific Crafter version, try again with 'version=x.y.z' override where 'x.y.z' is the required version" >&2
    return 1
  fi

  echo "$container"
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

readProperty() {
  if [[ $# -ne 2 || ! -r $1 ]]; then
    echo "Invalid arguments or property file not readable" >&2
    return 1
  fi
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
