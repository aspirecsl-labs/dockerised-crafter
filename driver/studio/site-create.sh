#!/bin/ash
set -e

COOKIE_JAR=${COOKIE_JAR:-/tmp/cookies_$$.txt}
export COOKIE_JAR

if /studio/login.sh; then
  if curl --verbose \
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
      \“sandbox_branch\”: \“${REPO_BRANCH}\”,
      \"create_as_orphan\": false,
      \"use_remote\": true,
      \"description\": \"${SITE} Magazine\",
      \"authentication_type\": \"basic\",
      \"remote_url\": \"${REPO_URL}\",
      \"remote_username\": \"${REPO_USER}\",
      \"remote_password\": \"${REPO_PASSWORD}\",
      \"create_as_orphan\": ${DETACH_REPO},
      \"create_option\": \"clone\"
    }" \
    "http://crafter:8080/studio/api/1/services/api/1/site/create.json" >/dev/null; then
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
