#!/bin/bash
set -e
set -x

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
  echo "    driver_version:  The Crafter CMS driver version to use instead of the default. Example \"driver_version=20.6.1\""
  echo "    verbose:         Turn on the verbose logging of the site operations. Allowed values are 'yes' and 'no' (default). Example \"verbose=yes\""
  echo "    version:         The Crafter version to use instead of default. Example \"version=3.1.7\""
}

createNetworkAndAttachCrafterContainer() {
  RANDOM=$(date '+%s')
  eval NETWORK="cms_${INTERFACE}_nw_${RANDOM}"
  docker network create "${NETWORK}" >/dev/null
  sleep 1s
  docker network connect --alias crafter --alias "${container}" "${NETWORK}" "${container}" >/dev/null
  sleep 1s
}

detachCrafterContainerAndDeleteNetwork() {
  if [ -n "$NETWORK" ]; then
    nw_id=$(docker network ls --filter name="$NETWORK" --format '{{.ID}}')
    if [ -n "$nw_id" ]; then
      sleep 1s
      docker network disconnect --force "${nw_id}" "${container}" >/dev/null
      sleep 1s
      docker network rm "${nw_id}" >/dev/null
    fi
  fi
}

runSiteCreateCommand() {
  echo ""
  # input "label" "nullable" "sensitive"
  CRAFTER_USER=$(input "Crafter username?" "n" "n")
  CRAFTER_PASSWORD=$(input "Crafter password?" "n" "y")
  REPO_URL=$(input "${SITE} repo url? " "n" "n")
  REPO_BRANCH=$(input "${SITE} repo branch? " "n" "n")
  REPO_USER=$(input "${SITE} repo user? " "n" "n")
  REPO_PASSWORD=$(input "${SITE} repo password? " "n" "y")
  echo ""

  if [ "$(docker exec "${container}" env | grep CONTAINER_MODE | cut -f2 -d=)" = 'dev' ]; then
    DETACH_REPO=false
  else
    DETACH_REPO=true
  fi

  export REPO_URL
  export REPO_USER
  export REPO_BRANCH
  export DETACH_REPO
  export CRAFTER_USER
  export REPO_PASSWORD
  export CRAFTER_PASSWORD

  createNetworkAndAttachCrafterContainer

  docker run \
    --rm \
    --env VERBOSE \
    --env REPO_URL \
    --env REPO_USER \
    --env REPO_BRANCH \
    --env DETACH_REPO \
    --env CRAFTER_USER \
    --env REPO_PASSWORD \
    --env CRAFTER_PASSWORD \
    --network "${NETWORK}" \
    "${DRIVER_IMAGE_REFERENCE}" "/site.sh" "${SITE}" "${command}"

  detachCrafterContainerAndDeleteNetwork
}

runSiteContextCommand() {
  createNetworkAndAttachCrafterContainer

  docker run \
    --rm \
    --env VERBOSE \
    --network "${NETWORK}" \
    "${DRIVER_IMAGE_REFERENCE}" "/site.sh" "${SITE}" "${command}"

  detachCrafterContainerAndDeleteNetwork
}

trap detachCrafterContainerAndDeleteNetwork EXIT

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

# shellcheck disable=SC2154
# verbose may be specified as an option from the command line
if [ -n "$verbose" ]; then
  allowed_verbose_modes=(no yes)
  if ! arrayContainsElement "${verbose}" "${allowed_verbose_modes[@]}"; then
    usage
    exit 1
  fi
  VERBOSE=$verbose
  export VERBOSE
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

case $command in
context-[_-0-9a-zA-Z]*)
  runSiteContextCommand
  ;;
create)
  runSiteCreateCommand
  ;;
*)
  usage
  exit 1
  ;;
esac

exit 0
