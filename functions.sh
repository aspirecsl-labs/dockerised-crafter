readProperty() {
  if [[ $# -ne 2 || ! -r $1 ]]; then
    echo "UNDEFINED"
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
  echo "${PROP_VAL:-UNDEFINED}"
  return 0
}

arrayContainsElement() {
  local element
  for element in "${@:2}"; do
    [[ "$element" == "$1" ]] && return 0
  done
  return 1
}

input() {
  local label=$1
  local nullable=$2
  local sensitive=$3
  local response
  if [ "${sensitive:-n}" = "y" ]; then
    read -r -s -p "$label" response
  else
    read -r -p "$label" response
  fi
  while [ "${nullable:-y}" = 'n' ] && [ -z "$response" ]; do
    echo -e "\nInvalid response!" >&2
    echo "Must not be empty" >&2
    echo -e "Please try again.\n" >&2
    if [ "${sensitive:-n}" = "y" ]; then
      read -r -s -p "$label" response
    else
      read -r -p "$label" response
    fi
  done
  echo "$response"
  return 0
}

numberInput() {
  local label=$1
  local nullable=$2
  local sensitive=$3
  local response
  response=$(input "$label" "$nullable" "$sensitive")
  if [ -n "$response" ]; then
    local re='^[0-9]+$'
    while ! [[ $response =~ $re ]]; do
      echo -e "\nInvalid response!" >&2
      echo "Must be a number" >&2
      echo -e "Please try again.\n" >&2
      response=$(input "$label" "$nullable" "$sensitive")
      if [ -z "$response" ]; then
        break
      fi
    done
  fi
  echo "$response"
  return 0
}

validatableInput() {
  local label=$1
  local nullable=$2
  local sensitive=$3
  local valid_values=("${@:4}")
  local response
  response=$(input "$label" "$nullable" "$sensitive")
  if [ -n "$response" ]; then
    arrayContainsElement "$response" "${valid_values[@]}"
    local RTN=$?
    while [ $RTN -ne 0 ]; do
      echo -e "\nInvalid response!" >&2
      echo "Must be one of [${valid_values[*]}]" >&2
      echo -e "Please try again.\n" >&2
      response=$(input "$label" "$nullable" "$sensitive")
      if [ -n "$response" ]; then
        arrayContainsElement "$response" "${valid_values[@]}"
        RTN=$?
      else
        RTN=0
      fi
    done
  fi
  echo "$response"
  return 0
}