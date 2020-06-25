#!/bin/ash
set -e

echo -e "\n------------------------------------------------------------------------"
echo "Crafter Site Creation"
echo "---------------------"

COOKIE_JAR=${COOKIE_JAR:-/tmp/cookies_$$.txt}
export COOKIE_JAR

if /studio/login.sh; then
  payload="{
    \"site_id\": \"${SITE}\",
    \"single_branch\": false,
    \"sandbox_branch\": \"${REPO_BRANCH}\",
    \"create_as_orphan\": false,
    \"use_remote\": true,
    \"description\": \"${SITE} Magazine\",
    \"authentication_type\": \"basic\",
    \"remote_url\": \"${REPO_URL}\",
    \"remote_username\": \"${REPO_USER}\",
    \"remote_password\": \"${REPO_PASSWORD}\",
    \"create_as_orphan\": ${DETACH_REPO},
    \"create_option\": \"clone\"
  }"
  if [ "$VERBOSE" = 'yes' ]; then
    echo -e "\nSite creation payload:\n${payload/${REPO_PASSWORD}/***}"
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
    --header 'X-XSRF-TOKEN: s3cr3tv4lu3' \
    --header 'Cookie: XSRF-TOKEN=s3cr3tv4lu3;' \
    --header 'Content-Type: application/json' \
    --data-raw "$payload" \
    "http://crafter:8080/studio/api/1/services/api/1/site/create.json"); then
    if [ "$result" -gt 399 ]; then
      echo ""
      echo "${SITE} site creation failed with http status $result."
      RTNCD=1
    else
      echo ""
      echo "${SITE} site created successfully."
      RTNCD=0
    fi
  else
    echo ""
    echo "${SITE} site creation failed."
    RTNCD=9
  fi
else
  echo ""
  echo "studio login failed!!!"
  RTNCD=1
fi

echo -e "\n------------------------------------------------------------------------\n"
exit $RTNCD
