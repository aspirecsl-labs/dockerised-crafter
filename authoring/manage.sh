#!/bin/bash
set -e

CAM_HOME=${CAM_HOME:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

# shellcheck source=../functions.sh
source "$CAM_HOME"/../functions.sh

SERVICE=authoring
GLOBAL_PROPERTIES="$CAM_HOME"/../global.properties

MAINTAINED_BY=$(readProperty "$GLOBAL_PROPERTIES" "maintained-by")
DOCKER_IMAGE_PREFIX=$(readProperty "$GLOBAL_PROPERTIES" "image-prefix")
VERSION=${1:-$(readProperty "$GLOBAL_PROPERTIES" "default-crafter-version")}

ALLOWED_COMMANDS=(port login status backup restore upgrade version list-backups)

container_id=$(docker container ls --format "{{.ID}}" --filter="ancestor=${MAINTAINED_BY}/${DOCKER_IMAGE_PREFIX}-${SERVICE}:${VERSION}")
command=$(validatableInput "Enter a command (available commands are:- ${ALLOWED_COMMANDS[*]}): " "n" "n" "${ALLOWED_COMMANDS[@]}")
if [ "$command" = 'port' ]; then
  echo -e "\n"
  docker port "${container_id}"
  echo -e "\n"
elif [ "$command" = 'login' ]; then
  command=/bin/bash
  docker exec -it "$container_id" "/docker-entrypoint.sh" "$command"
else
  docker exec "$container_id" "/docker-entrypoint.sh" "$command"
fi

exit 0
