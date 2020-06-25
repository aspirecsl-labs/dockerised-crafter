#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} COMMAND [OVERRIDES]"
  echo ""
  echo "Manage the specified site on the Crafter authoring instance"
  echo ""
  echo "name  The name of the site to manage"
  echo ""
  echo "Commands:"
  echo "  context-status   Show the status of the specified site's context"
  echo "  create           Create a site on the container"
  echo "  context-destroy  Destroy the specified site's context"
  echo "  context-rebuild  Rebuild the specified site's context"
  echo ""
  echo "Overrides:"
  echo "Allow users to supply overrides for commands"
  echo "  Overrides are specified as \"name1=value1,name2=value2,...,nameN=valueN\""
  echo "  Supported overrides are:-"
  echo "    container:       The id or name of the container to manage. Example \"container=869efc01315c\" or \"container=awesome_alice\""
  echo "    driver_version:  The Crafter CMS driver version to use instead of the default. Example \"driver_version=20.6.1\" "
  echo "    version:         The Crafter version to use instead of default. Example \"version=3.1.7\" "
}

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter authoring site-{name} COMMAND' to manage the named site on the Crafter authoring container"
  exit 9
fi

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

# shellcheck source=<repo_root>/scripts/lib.sh
source "${CRAFTER_SCRIPTS_HOME}/lib.sh"

command=$1
if ! enumerateKeyValuePairs "$2"; then
  usage
  exit 1
fi

IMAGE=aspirecsl/crafter-cms-${INTERFACE}
# shellcheck disable=SC2154
# version may be specified as an option from the command line
if [ -n "$version" ]; then
  eval IMAGE_REFERENCE="${IMAGE}:${version}"
else
  eval IMAGE_REFERENCE="${IMAGE}"
fi

DRIVER_IMAGE=aspirecsl/crafter-cms-driver
# shellcheck disable=SC2154
# driver_version may be specified as an option from the command line
if [ -n "$driver_version" ]; then
  eval DRIVER_IMAGE_REFERENCE="${DRIVER_IMAGE}:${driver_version}"
else
  eval DRIVER_IMAGE_REFERENCE="${DRIVER_IMAGE}"
fi

if ! container=$(getUniqueRunningContainer "${INTERFACE}" "${IMAGE_REFERENCE}"); then
  exit 1
fi

if [ "$(docker exec "${container}" echo "${CONTAINER_MODE}")" = 'dev' ]; then
  DETACH_REPO=false
  # input "label" "nullable" "sensitive"
  REPO_BRANCH=$(input "${SITE} Repo Branch " "n" "n")
  if ! [[ ${REPO_BRANCH} =~ ^feature|bugfix|hotfix/[-_a-zA-Z0-9]+$ ]]; then
    echo "" >&2
    echo "Site branches intended for development should start with 'bugfix', 'feature' or 'hotfix'" >&2
    echo "" >&2
    exit 1
  fi
else
  DETACH_REPO=true
  REPO_USER=$(readProperty "${CRAFTER_HOME}/.default_repo_properties" "repo_user")
  REPO_URL=$(readProperty "${CRAFTER_HOME}/.default_repo_properties" "${SITE}_repo")
  REPO_PASSWORD=$(readProperty "${CRAFTER_HOME}/.default_repo_properties" "repo_password")
  # input "label" "nullable" "sensitive"
  REPO_BRANCH=$(input "${SITE} Repo Branch (default: master)" "y" "n")
  REPO_BRANCH=${REPO_BRANCH:-master}
fi

RANDOM=$(date '+%s')
NETWORK="cms_${INTERFACE}_nw_${RANDOM}"
docker network create "${NETWORK}"
docker network connect --alias crafter "${NETWORK}" "${container}"

# input "label" "nullable" "sensitive"
REPO_URL=${REPO_URL:-$(input "${SITE} Repo URL" "n" "n")}
REPO_USER=${REPO_USER:-$(input "${SITE} Repo user" "n" "n")}
REPO_PASSWORD=${REPO_PASSWORD:-$(input "${SITE} Repo password" "n" "y")}

export REPO_URL
export REPO_USER
export REPO_BRANCH
export DETACH_REPO
export REPO_PASSWORD

docker run \
  --rm \
  --env REPO_URL \
  --env REPO_USER \
  --env REPO_BRANCH \
  --env DETACH_REPO \
  --env REPO_PASSWORD \
  --network "${NETWORK}" \
  "${DRIVER_IMAGE_REFERENCE}" "/site.sh" "${SITE}" "${command}"

docker network disconnect "${NETWORK}" "${container}"
docker network prune

exit 0
