#!/bin/ash
set -e

COOKIE_JAR=${COOKIE_JAR:-/tmp/cookies_$$.txt}
export COOKIE_JAR

if /studio/login.sh; then
  echo ""
  echo "------------------------------------------------------------------------"
  echo "Crafter Site Info"
  echo "-----------------"
  if [ "$VERBOSE" = 'yes' ]; then
    CURL_CMD="curl --verbose"
  else
    CURL_CMD="curl --silent --show-error"
  fi

  echo ""
  JSESSIONID=$(grep <"${COOKIE_JAR}" JSESSIONID | awk '{print $7}')
  $CURL_CMD \
    --location \
    --header 'X-XSRF-TOKEN: s3cr3tv4lu3' \
    --header "Cookie: XSRF-TOKEN=s3cr3tv4lu3;JSESSIONID=${JSESSIONID};" \
    "http://crafter/studio/api/1/services/api/1/site/get.json?site_id=${SITE}"
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
