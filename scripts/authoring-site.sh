#!/bin/bash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} COMMAND [OVERRIDES]"
  echo ""
  echo "Manage the specified site on the Crafter authoring instance"
  echo ""
  echo "Commands:"
  echo "    context-status   Show the status of the specified site's context"
  echo "    create           Create a site on the container"
  echo "    destroy-context  Destroy the specified site's context"
  echo "    download         Download a site from the container to the host machine"
  echo "    rebuild-context  Rebuild the specified site's context"
  echo "    upload           Upload a site from the host machine to the container"
  echo ""
  echo "name  The name of the site to manage"
  echo ""
  echo "Overrides:"
  echo "Allow users to supply overrides for commands"
  echo "  Overrides are specified as \"name1=value1,name2=value2,...,nameN=valueN\""
  echo "  Common Overrides are:-"
  echo "    container:      The id or name of the container to manage. Example \"container=869efc01315c\" or \"container=awesome_alice\""
  echo "    version:        The Crafter version to use instead of default. Example \"version=3.1.7\" "
  echo "  Overrides for 'create' command are:-"
  echo "    password        The git password for the site repo. Example \"password=crafter\""
  echo "    url             The git URL for the site repo. Example \"url=https://my-git-server.com/site-repo\""
  echo "    user            The git user for the site repo. Example \"user=crafter\""
  echo "    sandbox_branch  The sandbox branch to use. Example \"sandbox_branch=master\""
  echo "    site_desc       The description for the site. Example \"site_desc=my awesome site\""
  echo "  Overrides for 'upload' command are:-"
  echo "    host_dir        The directory in the host machine from which the site is uploaded to the container. Example \"host_dir=/home/crafter/site\""
  echo "    prompt          Prompt the user before overwriting a file. Valid values are 'yes|no'. Example \"prompt=yes\""
  echo "  Overrides for 'download' command are:-"
  echo "    host_dir        The directory in the host machine to which the site is downloaded from the container. Example \"host_dir=/home/crafter/site\""
  echo "    prompt          Prompt the user before overwriting a file. Valid values are 'yes|no'. Example \"prompt=yes\""
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
  return 1
fi

if ! container=$(getUniqueRunningContainer); then
  exit 1
fi

command=$1
volume_container=$(docker inspect "${container}" --format='{{.HostConfig.VolumesFrom}}')

echo "$command"
echo "$volume_container"
