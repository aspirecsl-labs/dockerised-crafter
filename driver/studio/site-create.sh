#!/bin/ash
set -e

WORKING_DIR=${WORKING_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

COOKIE_JAR=${COOKIE_JAR:-/tmp/cookies_$$.txt}
export COOKIE_JAR

if "$WORKING_DIR"/login.sh; then
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
      \"site_id\": \"${SITE}\",
      \"single_branch\": false,
      \“sandbox_branch\”: \“${GIT_BRANCH}\”,
      \"create_as_orphan\": false,
      \"use_remote\": true,
      \"description\": \"${SITE} Magazine\",
      \"authentication_type\": \"basic\",
      \"remote_url\": \"${GIT_URL}\",
      \"remote_username\": \"${GIT_USER}\",
      \"remote_password\": \"${GIT_PASSWORD}\",
      \"create_option\": \"clone\"
    }" \
    "http://crafter:8080/studio/api/1/services/api/1/site/create.json" >/dev/null; then
    echo "${COOKIE_JAR}"
    exit 0
  else
    echo ""
    echo "site creation failed!!!"
    echo ""
    exit 1
  fi
else
  echo ""
  echo "studio login failed!!!"
  echo ""
  exit 1
fi
