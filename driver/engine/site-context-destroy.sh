#!/bin/ash
set -e

if [ "$VERBOSE" = 'yes' ]; then
  CURL_CMD="curl --verbose"
else
  CURL_CMD="curl --silent --show-error"
fi

${CURL_CMD} \
  --location \
  --request GET \
  "http://crafter:${PORT}/api/1/site/context/crafterSite=${SITE}&token=defaultManagementToken"

exit $?
