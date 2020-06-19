#!/bin/ash
set -e

usage() {
  echo ""
  echo "Usage: site COMMAND site_name"
  echo ""
  echo "Transfers site data between a Crafter container and the host system"
  echo ""
  echo "Commands:"
  echo "    download  Download the specified site to the present working directory of the host system"
  echo "    upload    Upload the files in the present working directory of the host system to the specified site"
  echo ""
  exit 1
}

bad_site() {
  echo ""
  echo "Unable to perform the requested operation."
  echo ""
  echo "Does the site exist on Crafter?"
  echo ""
  echo "This operation is only supported on Crafter authoring volumes"
  echo "Are you running this on a Crafter delivery volume?"
  exit 2
}

case $1 in
download)
  if [ ! -r "/opt/crafter/data/repos/sites/$2/sandbox" ]; then
    bad_site
  fi
  cp -fr /opt/crafter/data/repos/sites/"$2"/sandbox /data
  ;;
upload)
  if [ ! -w "/opt/crafter/data/repos/sites/$2/sandbox" ]; then
    bad_site
  fi
  cp -fr /data /opt/crafter/data/repos/sites/"$2"/sandbox
  ;;
*)
  usage
  ;;
esac
