#!/bin/ash
set -e

SITE_SANDBOX_DIR="/opt/crafter/data/repos/sites/$SITE/sandbox"

if [ "$VERBOSE" = 'yes' ]; then
  CURL_CMD="curl --verbose"
else
  CURL_CMD="curl --silent --show-error"
fi

echo ""
echo "------------------------------------------------------------------------"
echo ""
cd "$SITE_SANDBOX_DIR"
co_branch=$(git branch --show-current)
if git ls-remote --exit-code --heads origin "$co_branch" >/dev/null; then
  echo "Pulling Changes From Remote"
  echo "---------------------------"
  git pull
  echo ""
fi

echo "Refreshing Crafter Site Context"
echo "-------------------------------"

echo ""
${CURL_CMD} \
  --location \
  --request GET \
  "http://crafter/api/1/site/context/rebuild.json?crafterSite=${SITE}&token=defaultManagementToken"
RTNCD=$?

echo ""
echo ""
echo "Refreshing GraphQL Schema For Crafter Site"
echo "------------------------------------------"

echo ""
${CURL_CMD} \
  --location \
  --request GET \
  "http://crafter/api/1/site/context/graphql/rebuild.json?crafterSite=${SITE}&token=defaultManagementToken"
RTNCD=$?

echo ""
echo ""
echo "------------------------------------------------------------------------"
echo ""
exit $RTNCD
