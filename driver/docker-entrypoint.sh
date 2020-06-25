#!/bin/ash
set -e

if [ "$1" = 'version' ]; then
  echo ""
  cat /etc/release
  echo ""
else
  exec "$@"
fi
