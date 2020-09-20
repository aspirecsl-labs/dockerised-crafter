#!/bin/ash
set -e

usage() {
  echo ""
  echo "Usage: $(basename "$0") name COMMAND"
  echo ""
  echo "Manage the given Crafter site"
  echo ""
  echo "name: The site name"
  echo ""
  echo "Commands:"
  echo "  create   Create a site."
  echo "  delete   Delete the given site."
  echo "  info     Show the site properties."
  echo "  reset    Reset the specified site."
  echo "  refresh  Refresh the specified site."
  echo "  status   Show the status of the specified site."
  echo ""
}

SITE=$1
export SITE

command=$2

case $command in
refresh | reset | status)
  "/engine/site-${command}.sh"
  RTNCD=$?
  ;;
create | delete | info)
  "/studio/site-${command}.sh"
  RTNCD=$?
  ;;
*)
  usage
  RTNCD=1
  ;;
esac

exit $RTNCD
