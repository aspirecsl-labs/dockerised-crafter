#!/bin/ash
set -e

COOKIE_JAR=${COOKIE_JAR:-/tmp/cookies_$$.txt}

payload="{
  \"username\": \"admin\",
  \"password\": \"admin\"
}"
if [ "$VERBOSE" = 'yes' ]; then
  echo -e "Payload:\n$payload"
  echo ""
  echo "Cookie Jar: ${COOKIE_JAR}"
  echo -e "\n"
  CURL_CMD="curl --verbose --output /dev/null --write-out %{http_code}"
else
  CURL_CMD="curl --silent --show-error --output /dev/null --write-out %{http_code}"
fi

if result=$($CURL_CMD \
  --location \
  --cookie-jar "${COOKIE_JAR}" \
  --cookie "${COOKIE_JAR}" \
  --junk-session-cookies \
  --header 'X-XSRF-TOKEN: s3cr3tv4lu3' \
  --header 'Cookie: XSRF-TOKEN=s3cr3tv4lu3;' \
  --header 'Content-Type: application/json' \
  --data-raw "$payload" \
  "http://crafter:8080/studio/api/1/services/api/1/security/login.json"); then
  if [ "$result" -gt 399 ]; then
    echo ""
    echo "Studio login failed with http status $result."
    exit 1
  else
    echo ""
    echo "Studio login successful."
    exit 0
  fi
else
  echo ""
  echo "Studio login failed."
  exit 9
fi
