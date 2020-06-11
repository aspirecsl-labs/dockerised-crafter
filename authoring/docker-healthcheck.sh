#!/bin/bash
set -e
# set -x

curl -sSLf http://localhost:8080 >/dev/null || exit 1
