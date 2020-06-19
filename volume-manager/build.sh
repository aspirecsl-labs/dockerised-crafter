#!/bin/bash
set -e

readProperty() {
  if [[ $# -ne 2 || ! -r $1 ]]; then
    echo "UNDEFINED"
    return 1
  fi
  PROP_VAL=$(awk -F "=" \
    -v PROP_KEY="$2" \
    '{
                   if ($1 == PROP_KEY)
                   {
                     print $2;
                     exit;
                   }
                }' "$1")
  echo "${PROP_VAL:-UNDEFINED}"
  return 0
}

HOME=${HOME:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

IMAGE=$(readProperty "${HOME}/release" "IMAGE")
VERSION=$(readProperty "${HOME}/release" "VERSION")

docker build --tag "${IMAGE}:${VERSION}" .
