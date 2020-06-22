#!/bin/ash
set -e

curl --silent \
  --show-error \
  --location \
  --request GET \
  "http://${CRAFTER_SERVER}:8080/api/1/site/context/status?token=defaultManagementToken"
