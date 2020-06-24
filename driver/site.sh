#!/bin/ash
set -e

usage() {
  echo ""
  echo "Usage: $(basename "$0") name COMMAND"
  echo ""
  echo "Transfer site data between a Crafter volume container and the host system"
  echo ""
  echo "name: The site name"
  echo ""
  echo "Commands:"
  echo "  context-status   Show the status of the specified site's context"
  echo "  create           Create a site on the container"
  echo "  context-destroy  Destroy the specified site's context"
  echo "  context-rebuild  Rebuild the specified site's context"
  echo ""
  exit 1
}

SITE=$1
export SITE

command=$2

case $command in
context-[_-0-9a-zA-Z]*)
  "/engine/site-${command}.sh"
  ;;
create)
  "/studio/site-create.sh"
  ;;
*)
  usage
  ;;
esac
