#!/bin/bash
#set -x

usage() {
  echo -e "\nUsage: $(basename "$0") run|exec|build\n"
  exit 1
}

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

numberInput() {
  local label=$1
  local sensitive=$2
  local response
  if [ "${sensitive:-n}" = "y" ]; then
    read -r -s -p "$label" response
  else
    read -r -p "$label" response
  fi
  local re='^[0-9]+$'
  while ! [[ $response =~ $re ]]; do
    echo -e "\nInvalid response!"
    echo "Must be a number"
    echo -e "Please try again.\n"
    if [ "${sensitive:-n}" = "y" ]; then
      read -r -s -p "$label" response
    else
      read -r -p "$label" response
    fi
  done
  echo "$response"
  return 0
}

textInput() {
  local label=$1
  local sensitive=$2
  local response
  if [ "${sensitive:-n}" = "y" ]; then
    read -r -s -p "$label" response
  else
    read -r -p "$label" response
  fi
  echo "$response"
  return 0
}

validatableInput() {
  local label=$1
  local sensitive=$2
  local valid_values=("${@:3}")
  local response
  response=$(textInput "$label" "$sensitive")
  arrayContainsElement "$response" "${valid_values[@]}"
  local RTN=$?
  while [ $RTN -ne 0 ]; do
    echo -e "\nInvalid response!"
    echo "Must be one of [${valid_values[*]}]"
    echo -e "Please try again.\n"
    response=$(textInput "$label" "$sensitive")
    arrayContainsElement "$response" "${valid_values[@]}"
    RTN=$?
  done
  echo "$response"
  return 0
}

enumerateOptions() {
  IFS="," read -r -a options <<<"$1"
  for option in "${options[@]}"; do
    k=$(echo "$option" | cut -d"=" -f1 | tr '[:upper:]' '[:lower:]')
    v=$(echo "$option" | cut -d"=" -f2)
    eval "$k"="$v"
  done
}

run() {
  local available_versions
  available_versions=$(docker images |
    awk -v image_prefix="${DOCKER_IMAGE_PREFIX}-${SERVICE}" '{  if($1 == image_prefix) {printf("%s ", $2)} }')
  local version
  version=$(textInput "Crafter Version (default = $DEFAULT_CRAFTER_VERSION): " "n")
  VERSION=${version:-$DEFAULT_CRAFTER_VERSION}
  if ! arrayContainsElement "$VERSION" "${available_versions[@]}"; then
    echo -e "\nERROR:- Invalid version $version"
    echo -e "Could not find an image for version $VERSION"
    echo -e "Try building an image for version $VERSION using the command <$(basename "$0") build>\n"
    exit 1
  fi

  echo "Starting container from image: ${DOCKER_IMAGE_PREFIX}-${SERVICE}:${VERSION}"
  port=${port:-8080}
  es_port=${es_port:-9201}
  deployer_port=${deployer_port:-9191}
  es_debug_port=${es_debug_port:-4004}
  engine_debug_port=${engine_debug_port:-8000}
  deployer_debug_port=${deployer_debug_port:-5005}
  echo "*** port=${port} | debug port=${engine_debug_port} ***"
  sleep 1s
  if [ "${debug:-no}" = 'yes' ]; then
    docker run --rm \
      -p "${port}":8080 \
      -p "${es_port}":9201 \
      -p "${deployer_port}":9191 \
      -p "${es_debug_port}":4004 \
      -p "${engine_debug_port}":8000 \
      -p "${deployer_debug_port}":5005 \
      "${DOCKER_IMAGE_PREFIX}-${SERVICE}:${VERSION}" "debug"
  else
    docker run --rm \
      -p "${port}":8080 \
      -p "${es_port}":9201 \
      -p "${deployer_port}":9191 \
      -p "${es_debug_port}":4004 \
      -p "${engine_debug_port}":8000 \
      -p "${deployer_debug_port}":5005 \
      "${DOCKER_IMAGE_PREFIX}-${SERVICE}:${VERSION}"
  fi
}

build() {
  local version
  version=$(textInput "Crafter Version (default = $DEFAULT_CRAFTER_VERSION): " "n")
  VERSION=${version:-$DEFAULT_CRAFTER_VERSION}
  export VERSION

  INSTALLER_CHECKSUM=$(readProperty "$GLOBAL_PROPERTIES" "${SERVICE}-${VERSION}")
  export INSTALLER_CHECKSUM

  docker build \
    --build-arg VERSION \
    --build-arg INSTALLER_CHECKSUM \
    --tag "${DOCKER_IMAGE_PREFIX}-${SERVICE}:${VERSION}" .
}

executeCommand() {
  local allowed_commands=(status backup restore upgrade selfupdate)
  #  if [ "$2" = 'exec' ]; then
  #    docker exec -it "$1" "$3"
  #  else
  #    docker exec "$1" "/crafter-entrypoint.sh" "$2" "$3"
  #  fi
}

SERVICE=authoring
DOCKER_IMAGE_PREFIX="crafter-cms"
CAM_HOME=${CAM_HOME:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
GLOBAL_PROPERTIES="$CAM_HOME"/../global.properties

DEFAULT_CRAFTER_VERSION=$(readProperty "$GLOBAL_PROPERTIES" "default-crafter-version")

case $1 in
run)
  run
  ;;
exec)
  executeCommand
  ;;
build)
  build
  ;;
*)
  usage
  ;;
esac

exit 0
