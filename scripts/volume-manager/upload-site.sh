#!/bin/ash
set -e

usage() {
  echo ""
  echo "Usage: ${CMD_PREFIX:-$(basename "$0")} site-name"
  echo ""
  echo "Transfers site data between a Crafter volume container and the host system"
  echo ""
  echo "Commands:"
  echo "    download  Download the specified site to the present working directory of the host system"
  echo "    upload    Upload the files in the present working directory of the host system to the specified site"
  echo ""
  exit 1
}

if [ $# -ne 2 ]; then
  usage
fi

docker run $1
