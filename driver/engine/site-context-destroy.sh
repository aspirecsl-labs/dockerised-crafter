#!/bin/ash
set -e

curl --silent \
  --show-error \
  --location \
  --request GET \
  "http://crafter:8080/api/1/site/context/crafterSite=${SITE}&token=defaultManagementToken"
