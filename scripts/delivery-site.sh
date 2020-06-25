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
  echo "  context-status   Show the status of the specified site's context"
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

if [ -z "$INTERFACE" ] || [ -z "$CRAFTER_HOME" ] || [ -z "$CRAFTER_SCRIPTS_HOME" ]; then
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

# shellcheck source=<repo_root>/scripts/lib.sh
source "${CRAFTER_SCRIPTS_HOME}/lib.sh"

command=$1
if [ "$command" = 'create' ]; then
  echo "ERROR: Unsupported operation" >&2
  echo "Sites cannot be created directly on Crafter Delivery instances" >&2
  exit 1
fi

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

PORT=9080
export PORT

RANDOM=$(date '+%s')
NETWORK="cms_${INTERFACE}_nw_${RANDOM}"
docker network create "${NETWORK}" >/dev/null
docker network connect --alias crafter "${NETWORK}" "${container}"

docker run \
  --rm \
  --env PORT \
  --env VERBOSE \
  --network "${NETWORK}" \
  "${DRIVER_IMAGE_REFERENCE}" "/site.sh" "${SITE}" "${command}"

docker network disconnect "${NETWORK}" "${container}"
docker network rm "${NETWORK}"

exit 0
