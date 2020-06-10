#!/bin/bash
set -e

if [ "$1" = 'run' ]; then
  exec /crafter-entrypoint.sh run
elif [ "$1" = 'debug' ]; then
  exec /crafter-entrypoint.sh debug
elif [ "$1" = 'status' ]; then
  exec /crafter-entrypoint.sh status
elif [ "$1" = 'selfupdate' ]; then
  exec /crafter-entrypoint.sh selfupdate
elif [ "$1" = 'upgrade' ]; then
  exec /crafter-entrypoint.sh upgrade
elif [ "$1" = 'backup' ]; then
  exec /crafter-entrypoint.sh backup
elif [ "$1" = 'restore' ]; then
  if [ -z "$2" ]; then
    echo "The backup file path was not specified"
    exit 1
  fi
  exec /crafter-entrypoint.sh restore "$2"
else
  exec "$@"
fi
