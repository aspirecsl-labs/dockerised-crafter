#!/bin/ash
set -e

WORKING_DIR=${WORKING_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

if COOKIE_JAR=$("$WORKING_DIR"/login.sh); then
  if curl --silent \
    --show-error \
    --location \
    --request POST \
    --cookie-jar "${COOKIE_JAR}" \
    --cookie "${COOKIE_JAR}" \
    --junk-session-cookies \
    --header 'X-XSRF-TOKEN: s3cr3tv4lu3' \
    --header 'Cookie: XSRF-TOKEN=s3cr3tv4lu3;' \
    --header 'Content-Type: application/json' \
    --data-raw \
    "{
      \"site_id\": \"${SITE_ID}\",
      \"single_branch\": false,
      \“sandbox_branch\”: \“${SANDBOX_BRANCH}\”,
      \"create_as_orphan\": false,
      \"use_remote\": true,
      \"description\": \"${SITE_DESC}\",
      \"authentication_type\": \"basic\",
      \"remote_url\": \"${GIT_URL}\",
      \"remote_username\": \"${GIT_USER}\",
      \"remote_password\": \"${GIT_PASSWORD}\",
      \"create_option\": \"clone\"
    }" \
    "http://${CRAFTER_SERVER}:8080/studio/api/1/services/api/1/site/create.json" >/dev/null; then
    echo "${COOKIE_JAR}"
    exit 0
  else
    exit 1
  fi
else
  exit 1
fi
