#!/bin/ash
set -e

COOKIE_JAR=${COOKIE_JAR:-/tmp/cookies_$$.txt}

if curl --verbose \
  --location \
  --request POST \
  --cookie-jar "${COOKIE_JAR}" \
  --cookie "${COOKIE_JAR}" \
  --junk-session-cookies \
  --header 'X-XSRF-TOKEN: s3cr3tv4lu3' \
  --header 'Cookie: XSRF-TOKEN=s3cr3tv4lu3;' \
  --header 'Content-Type: application/json' \
  --data-raw '{ "username": "admin", "password": "admin" }' \
  "http://crafter:8080/studio/api/1/services/api/1/security/login.json" >/dev/null; then
  exit 0
else
  exit 1
fi
