#!/bin/bash
set -e

if [ "$1" = 'import-site' ]; then
  echo "Coming soon..."
elif [ "$1" = 'manage-site' ]; then
  echo "Coming soon..."
else
  exec "$@"
fi
