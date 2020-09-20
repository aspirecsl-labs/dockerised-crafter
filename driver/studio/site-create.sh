#!/bin/ash
set -e

COOKIE_JAR=${COOKIE_JAR:-/tmp/cookies_$$.txt}
export COOKIE_JAR

SITE_SANDBOX_DIR="/opt/crafter/data/repos/sites/$SITE/sandbox"

if /studio/login.sh; then
  echo ""
  echo "------------------------------------------------------------------------"
  echo "Crafter Site Creation"
  echo "---------------------"
  payload="{
    \"site_id\": \"${SITE}\",
    \"single_branch\": false,
    \"sandbox_branch\": \"${SANDBOX_BRANCH}\",
    \"use_remote\": true,
    \"description\": \"${SITE} Magazine\",
    \"authentication_type\": \"basic\",
    \"remote_url\": \"${REPO_URL}\",
    \"remote_branch\": \"${REPO_BRANCH}\",
    \"remote_username\": \"${REPO_USER}\",
    \"remote_password\": \"${REPO_PASSWORD}\",
    \"create_option\": \"clone\"
  }"
  if [ "$VERBOSE" = 'yes' ]; then
    echo ""
    echo "Payload:"
    echo "${payload/${REPO_PASSWORD}/***}"
    echo ""
    CURL_CMD="curl --verbose --output /dev/null --write-out %{http_code}"
  else
    CURL_CMD="curl --silent --show-error --output /dev/null --write-out %{http_code}"
  fi

  JSESSIONID=$(grep <"${COOKIE_JAR}" JSESSIONID | awk '{print $7}')
  if result=$($CURL_CMD \
    --location \
    --header 'X-XSRF-TOKEN: s3cr3tv4lu3' \
    --header "Cookie: XSRF-TOKEN=s3cr3tv4lu3;JSESSIONID=${JSESSIONID};" \
    --header 'Content-Type: application/json' \
    --data-raw "$payload" \
    "http://crafter/studio/api/1/services/api/1/site/create.json"); then
    if [ "$result" -gt 399 ]; then
      echo ""
      echo "${SITE} site creation failed with http status $result."
      RTNCD=1
    else
      echo ""
      echo "${SITE} site created successfully."
      RTNCD=0
    fi
    URL_COMPLIANT_REPO_PASSWORD=${REPO_PASSWORD/@/%40}
    REPO_URL_WITH_CREDS=${REPO_URL/https:\/\//https:\/\/$REPO_USER:$URL_COMPLIANT_REPO_PASSWORD@}
    cd "$SITE_SANDBOX_DIR"
    git config user.email "crafter@dockerised.com"
    git config user.name "Crafter Dockerised"
    git remote set-url origin "$REPO_URL_WITH_CREDS"
    echo ""
    echo "${SITE} sandbox git settings:"
    echo ""
    git remote show origin | sed "s/$URL_COMPLIANT_REPO_PASSWORD/***/g"
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

echo ""
echo "------------------------------------------------------------------------"
echo ""
exit $RTNCD
