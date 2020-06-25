#!/bin/ash
set -e

echo -e "\n------------------------------------------------------------------------"
echo "Crafter Studio Login"
echo "--------------------"

COOKIE_JAR=${COOKIE_JAR:-/tmp/cookies_$$.txt}

payload="{
  \"username\": \"${CRAFTER_USER}\",
  \"password\": \"${CRAFTER_PASSWORD}\"
}"
str_to_replace="\"password\": \"${CRAFTER_PASSWORD}\""
replacement_str="\"password\": \"***\""

if [ "$VERBOSE" = 'yes' ]; then
  echo -e "\nPayload:\n${payload/$str_to_replace/$replacement_str}"
  echo ""
  CURL_CMD="curl --verbose --output /dev/null --write-out %{http_code}"
else
  CURL_CMD="curl --silent --show-error --output /dev/null --write-out %{http_code}"
fi

if result=$($CURL_CMD \
  --location \
  --cookie-jar "${COOKIE_JAR}" \
  --header 'X-XSRF-TOKEN: s3cr3tv4lu3' \
  --header 'Cookie: XSRF-TOKEN=s3cr3tv4lu3;' \
  --header 'Content-Type: application/json' \
  --data-raw "$payload" \
  "http://crafter/studio/api/1/services/api/1/security/login.json"); then
  if [ "$result" -gt 399 ]; then
    echo ""
    echo "Studio login failed with http status $result."
    RTNCD=1
  else
    echo ""
    echo "Studio login successful."
    RTNCD=0
  fi
else
  echo ""
  echo "Studio login failed."
  RTNCD=9
fi

echo -e "\n------------------------------------------------------------------------\n"
exit $RTNCD
