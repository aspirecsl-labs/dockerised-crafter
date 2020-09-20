#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} COMMAND [OVERRIDES]"
  echo ""
  echo "Manage the specified site on the Crafter delivery instance"
  echo ""
  echo "name  The name of the site to manage"
  echo ""
  echo "Commands:"
  echo "  init             Initialises the site on the Crafter delivery instance from a running Crafter Authoring instance."
  echo "                   Once initialised, the site changes published on the authoring server are automatically delivered"
  echo "                   to the delivery server. This operation requires a running Crafter Authoring instance."
  echo "  context-status   Show the status of the specified site's context"
  echo "  context-destroy  Destroy the specified site's context"
  echo "  context-rebuild  Rebuild the specified site's context"
  echo ""
  echo "Overrides:"
  echo "Allow users to supply overrides for commands"
  echo "  Overrides are specified as \"name1=value1,name2=value2,...,nameN=valueN\""
  echo "  Supported overrides are:-"
  echo "    authoring_container:  The id or name of the authoring container to connect to. Example \"authoring_container=869efc01315c\" or \"authoring_container=awesome_alice\""
  echo "    authoring_version:    The Crafter Authoring instance version to use instead of the default. Example \"authoring_version=3.1.7\""
  echo "                          If this override is specified then the Crafter delivery container will attempt to connect to the"
  echo "                          Crafter authoring container with the given version when initialising a site."
  echo "    container:            The id or name of the container to manage. Example \"container=869efc01315c\" or \"container=awesome_alice\""
  echo "    driver_version:       The Crafter CMS driver version to use instead of the default. Example \"driver_version=20.6.1\""
  echo "    verbose:              Turn on the verbose logging of the site operations. Allowed values are 'yes' and 'no' (default). Example \"verbose=yes\""
  echo "    version:              The Crafter version to use instead of default. Example \"version=3.1.7\""
}

runSiteContextCommand() {
  network="$(createNetworkAndAttachCrafterContainer "crafter_delivery_nw" "$container")"
  export network

  docker run \
    --rm \
    --env VERBOSE \
    --network "${network}" \
    "${DRIVER_IMAGE_REFERENCE}" "/site.sh" "${SITE}" "${command}"

  detachCrafterContainerAndDeleteNetwork "$network" "$container"
}

runSiteInitCommand() {
  network="$(createNetworkAndAttachCrafterContainer "crafter_authoring_delivery_nw" "$container" "crafter-delivery")"
  export network
  if [ -z "$authoring_container" ]; then
    local _authoring_image
    local _authoring_image_reference
    _authoring_image=aspirecsl/crafter-cms-authoring
    # shellcheck disable=SC2154
    # authoring_version may be specified as an option from the command line
    if [ -n "$authoring_version" ]; then
      _authoring_image_reference="${_authoring_image}:${version}"
    else
      _authoring_image_reference="${_authoring_image}"
    fi
    local authoring_container
    if ! authoring_container=$(getUniqueRunningContainer "authoring" "${_authoring_image_reference}"); then
      exit 1
    fi
  fi
  sleep 1s
  docker network connect --alias "crafter-authoring" --alias "${authoring_container}" "${network}" "${authoring_container}" >/dev/null
  sleep 1s

  docker exec -it "$container" "/docker-entrypoint.sh" "$command" "$SITE"

  sleep 1s
  docker network disconnect --force "${network}" "${authoring_container}" >/dev/null
  sleep 1s

  detachCrafterContainerAndDeleteNetwork "$network" "$container"
}

cleanup() {
  detachCrafterContainerAndDeleteNetwork "$network" "$container"
}

trap cleanup EXIT

if [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
  echo "Failed to setup the execution context!"
  echo "Are you running this script directly?"
  echo ""
  echo "Use 'crafter delivery site-{name} COMMAND' to manage the named site on the Crafter delivery container"
  exit 9
fi

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

# source=<repo_root>/scripts/lib.sh
# shellcheck disable=SC1090
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

DRIVER_IMAGE=aspirecsl/crafter-cms-driver
# shellcheck disable=SC2154
# driver_version may be specified as an option from the command line
if [ -n "$driver_version" ]; then
  eval DRIVER_IMAGE_REFERENCE="${DRIVER_IMAGE}:${driver_version}"
else
  eval DRIVER_IMAGE_REFERENCE="${DRIVER_IMAGE}"
fi

if [ -z "$container" ]; then
  IMAGE=aspirecsl/crafter-cms-delivery
  # shellcheck disable=SC2154
  # version may be specified as an option from the command line
  if [ -n "$version" ]; then
    eval IMAGE_REFERENCE="${IMAGE}:${version}"
  else
    eval IMAGE_REFERENCE="${IMAGE}"
  fi
  if ! container=$(getUniqueRunningContainer "delivery" "${IMAGE_REFERENCE}"); then
    exit 1
  fi
fi
export container

case $command in
context-[_-0-9a-zA-Z]*)
  runSiteContextCommand
  ;;
init)
  runSiteInitCommand
  ;;
*)
  usage
  exit 1
  ;;
esac

exit 0
