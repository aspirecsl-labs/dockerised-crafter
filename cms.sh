#!/bin/bash
#set -x

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

run() {
  local service=$1
  enumerateOptions "$2"

  debug_port=${debug_port:-8000}
  version=${version:-$DEFAULT_CRAFTER_VERSION}

  echo "Starting container: crafter-$service:${version}"
  if [ "$service" = 'authoring' ]; then
    port=${port:-8080}
    echo "*** port=${port} | debug port=${debug_port} ***"
    sleep 1s
    docker run -p "${port}":8080 -p "${debug_port}":8000 "crafter-$service:$version"
  else
    port=${port:-9080}
    echo "*** port=${port} | debug port=${debug_port} ***"
    sleep 1s
    docker run -p "${port}":9080 -p "${debug_port}":8000 "crafter-$service:$version"
  fi
}

build() {
  enumerateOptions "$2"
  export CRAFTER_SERVICE=$1
  export SERVICE_PORTS=8000 # JDPA debug port for the Crafter tomcat server - same for authoring and delivery servers

  if [ "$CRAFTER_SERVICE" = 'authoring' ]; then
    export SERVICE_PORTS="${SERVICE_PORTS} 8080"
  else
    export SERVICE_PORTS="${SERVICE_PORTS} 9080"
  fi

  CRAFTER_VERSION=${version:-$DEFAULT_CRAFTER_VERSION}
  export CRAFTER_VERSION

  CRAFTER_INSTALLER_CHECKSUM=$(readProperty "$CMS_HOME"/cms.properties "${CRAFTER_SERVICE}-${CRAFTER_VERSION}")
  export CRAFTER_INSTALLER_CHECKSUM

  docker build \
    --build-arg SERVICE_PORTS \
    --build-arg CRAFTER_VERSION \
    --build-arg CRAFTER_SERVICE \
    --build-arg CRAFTER_INSTALLER_CHECKSUM \
    --tag crafter-"$CRAFTER_SERVICE":"$CRAFTER_VERSION" .
}

CMS_HOME=${CMS_HOME:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

DEFAULT_CRAFTER_VERSION=$(readProperty "$CMS_HOME"/cms.properties "default-crafter-version")

ops=(run build)
services=(authoring delivery)

if ! arrayContainsElement "$1" "${services[@]}"; then
  bad_usage
fi
if ! arrayContainsElement "$2" "${ops[@]}"; then
  bad_usage
fi

service=$1
operation=$2
options_string=$3

case $operation in
build)
  build "$service" "$options_string"
  ;;
run)
  run "$service" "$options_string"
  ;;
esac

exit 0
