#!/bin/bash
set -e
set -x

if [ "$1" = 'run' ]; then
  exec /crafter-entrypoint.sh run
elif [ "$1" = 'debug' ]; then
  exec /crafter-entrypoint.sh debug
else
  exec "$@"
fi
