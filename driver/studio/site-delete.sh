#!/bin/ash
set -e

COOKIE_JAR=${COOKIE_JAR:-/tmp/cookies_$$.txt}
export COOKIE_JAR

if /studio/login.sh; then
  echo ""
  echo "------------------------------------------------------------------------"
  echo "Crafter Site Removal"
  echo "--------------------"
  payload="{
    \"site_id\": \"${SITE}\"
  }"
  if [ "$VERBOSE" = 'yes' ]; then
    echo ""
    echo "Payload:"
    echo "$payload"
    echo ""
    CURL_CMD="curl --verbose"
  else
    CURL_CMD="curl --silent --show-error"
  fi

  echo ""
  JSESSIONID=$(grep <"${COOKIE_JAR}" JSESSIONID | awk '{print $7}')
  echo -n "$SITE site deleted: "
  $CURL_CMD \
    --location \
    --header 'X-XSRF-TOKEN: s3cr3tv4lu3' \
    --header "Cookie: XSRF-TOKEN=s3cr3tv4lu3;JSESSIONID=${JSESSIONID};" \
    --header 'Content-Type: application/json' \
    --data-raw "$payload" \
    "http://crafter/studio/api/1/services/api/1/site/delete-site.json"
  RTNCD=$?
else
  echo ""
  echo "studio login failed!!!"
  RTNCD=1
fi

echo ""
echo ""
echo "------------------------------------------------------------------------"
echo ""
exit $RTNCD
