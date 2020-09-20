#!/bin/ash
set -e

if [ "$VERBOSE" = 'yes' ]; then
  CURL_CMD="curl --verbose"
else
  CURL_CMD="curl --silent --show-error"
fi

echo ""
echo "------------------------------------------------------------------------"
echo ""
echo "Clearing Crafter Site Context"
echo "-----------------------------"

echo ""
${CURL_CMD} \
  --location \
  --request GET \
  "http://crafter/api/1/site/context/destroy.json?crafterSite=${SITE}&token=defaultManagementToken"

echo ""
echo ""
echo "Clearing Crafter Site Cache"
echo "---------------------------"

echo ""
${CURL_CMD} \
  --location \
  --request GET \
  "http://crafter/api/1/site/cache/clear.json?crafterSite=${SITE}&token=defaultManagementToken"

echo ""
echo ""
echo "------------------------------------------------------------------------"
echo ""
