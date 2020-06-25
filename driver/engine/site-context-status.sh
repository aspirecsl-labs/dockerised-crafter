#!/bin/ash
set -e

if [ "$VERBOSE" = 'yes' ]; then
  CURL_CMD="curl --verbose"
else
  CURL_CMD="curl --silent --show-error"
fi

echo -e "\n------------------------------------------------------------------------"
echo "Crafter Site Context Status"
echo -e "----------------------------\n"

${CURL_CMD} \
  --location \
  --request GET \
  "http://crafter/api/1/site/context/status?crafterSite=${SITE}&token=defaultManagementToken"
RTNCD=$?

echo -e "\n------------------------------------------------------------------------\n"
exit $RTNCD
