#!/bin/bash
set -x

bad_usage() {
  echo -e "\nUsage: cms.sh authoring|delivery run|build [options]\n"
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

enumerateOptions() {
  IFS="," read -r -a options <<<"$1"
  for option in "${options[@]}"; do
    k=$(echo "$option" | cut -d"=" -f1 | tr '[:upper:]' '[:lower:]')
    v=$(echo "$option" | cut -d"=" -f2)
    eval "$k"="$v"
  done
}

start() {
  local service=$2
  enumerateOptions "$3"

  version=${version:-$DEFAULT_CRAFTER_VERSION}
  es_debug_port=${es_debug_port:-4004}
  engine_debug_port=${engine_debug_port:-8000}
  deployer_debug_port=${deployer_debug_port:-5005}

  echo "Starting container: crafter-$service:${version}"

  if [ "$service" = 'authoring' ]; then
    port=${port:-8080}
    es_port=${es_port:-9201}
    deployer_port=${deployer_port:-9191}
    echo "*** port=${port} | debug port=${engine_debug_port} ***"
    sleep 1s
    # $1 = "run" means the docker container starts in normal mode
    # $1 = "debug" means the docker container starts in debug mode
    if [ "$1" = 'debug' ]; then
      docker run --rm \
        -p "${port}":8080 \
        -p "${es_port}":9201 \
        -p "${deployer_port}":9191 \
        -p "${es_debug_port}":4004 \
        -p "${engine_debug_port}":8000 \
        -p "${deployer_debug_port}":5005 \
        "crafter-$service:$version" "debug"
    else
      docker run --rm \
        -p "${port}":8080 \
        -p "${es_port}":9201 \
        -p "${deployer_port}":9191 \
        -p "${es_debug_port}":4004 \
        -p "${engine_debug_port}":8000 \
        -p "${deployer_debug_port}":5005 \
        "crafter-$service:$version"
    fi
  else
    port=${port:-9080}
    es_port=${es_port:-9202}
    deployer_port=${deployer_port:-9192}
    echo "*** port=${port} | debug port=${engine_debug_port} ***"
    sleep 1s
    # $1 = "run" means the docker container starts in normal mode
    # $1 = "debug" means the docker container starts in debug mode
    if [ "$1" = 'debug' ]; then
      docker run --rm \
        -p "${port}":9080 \
        -p "${es_port}":9202 \
        -p "${deployer_port}":9192 \
        -p "${es_debug_port}":4004 \
        -p "${engine_debug_port}":8000 \
        -p "${deployer_debug_port}":5005 \
        "crafter-$service:$version" "debug"
    else
      docker run --rm \
        -p "${port}":9080 \
        -p "${es_port}":9202 \
        -p "${deployer_port}":9192 \
        -p "${es_debug_port}":4004 \
        -p "${engine_debug_port}":8000 \
        -p "${deployer_debug_port}":5005 \
        "crafter-$service:$version"
    fi
  fi
}

build() {
  enumerateOptions "$2"
  export CRAFTER_SERVICE=$1
  # JPDA debug ports - same for Authoring and Delivery
  # 4004 - ElasticSearch
  # 5005 - Crafter Deployer
  # 8000 - Crafter Studio & Engine
  AUX_PORTS="4004 5005 8000"

  if [ "$CRAFTER_SERVICE" = 'authoring' ]; then
    MAIN_PORT=8080
    AUX_PORTS="${AUX_PORTS} 9191 9201"
  else
    MAIN_PORT=9080
    AUX_PORTS="${AUX_PORTS} 9192 9202"
  fi
  export MAIN_PORT
  export AUX_PORTS

  CRAFTER_VERSION=${version:-$DEFAULT_CRAFTER_VERSION}
  export CRAFTER_VERSION

  CRAFTER_INSTALLER_CHECKSUM=$(readProperty "$CMS_HOME"/cms.properties "${CRAFTER_SERVICE}-${CRAFTER_VERSION}")
  export CRAFTER_INSTALLER_CHECKSUM

  docker build \
    --build-arg MAIN_PORT \
    --build-arg AUX_PORTS \
    --build-arg CRAFTER_VERSION \
    --build-arg CRAFTER_SERVICE \
    --build-arg CRAFTER_INSTALLER_CHECKSUM \
    --tag crafter-"$CRAFTER_SERVICE":"$CRAFTER_VERSION" .
}

executeCommand() {
  if [ "$2" = 'exec' ]; then
    docker exec -it "$1" "$3"
  else
    docker exec "$1" "/crafter-entrypoint.sh" "$2" "$3"
  fi
}

CMS_HOME=${CMS_HOME:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

DEFAULT_CRAFTER_VERSION=$(readProperty "$CMS_HOME"/cms.properties "default-crafter-version")

ops=(run exec build status backup restore upgrade selfupdate)

if ! arrayContainsElement "$1" "${ops[@]}"; then
  bad_usage
fi

case $1 in
run)
  start "run" "$2" "$3"
  ;;
debug)
  start "debug" "$2" "$3"
  ;;
build)
  build "$2" "$3"
  ;;
*)
  executeCommand "$2" "$1" "$3"
  ;;
esac

exit 0
