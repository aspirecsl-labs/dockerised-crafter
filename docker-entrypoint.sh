#!/bin/bash
set -e
set -x

if [ "$1" = 'run' ]; then
  /crafter-entrypoint.sh run
elif [ "$1" = 'debug' ]; then
  /crafter-entrypoint.sh debug
else
  exec "$@"
fi
