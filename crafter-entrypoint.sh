#!/bin/bash
set -e
set -x

runOrDebugCrafter() {
  if [ "$1" = 'debug' ]; then
    deployerMode="debug"
    catalinaMode="jpda run"
    export ES_JAVA_OPTS="$ES_JAVA_OPTS -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=4004"
  else
    deployerMode="start"
    catalinaMode="run"
  fi
  echo "------------------------------------------------------------------------"
  echo "Starting Deployer"
  echo "------------------------------------------------------------------------"
  "$DEPLOYER_HOME"/deployer.sh $deployerMode
  echo "------------------------------------------------------------------------"
  echo "Starting Elasticsearch"
  echo "------------------------------------------------------------------------"
  "$ES_HOME"/elasticsearch -d -p "$ES_PID"
  echo "------------------------------------------------------------------------"
  echo "Starting Tomcat"
  echo "------------------------------------------------------------------------"
  "$CRAFTER_BIN_DIR"/apache-tomcat/bin/catalina.sh $catalinaMode
}

status() {
  elasticsearchStatus
  crafterModuleStatus "Crafter Deployer" "$DEPLOYER_PORT" "" "1" "$DEPLOYER_PID"
  crafterModuleStatus "Crafter Engine" "$TOMCAT_HTTP_PORT" "" "1" "$CATALINA_PID"
  crafterModuleStatus "Crafter Studio" "$TOMCAT_HTTP_PORT" "/studio" "2" "$CATALINA_PID"
  crafterModuleStatus "Crafter Search" "$TOMCAT_HTTP_PORT" "/crafter-search" "1" "$CATALINA_PID"
}

elasticsearchStatus() {
  echo "------------------------------------------------------------------------"
  echo "Elasticsearch status"
  echo "------------------------------------------------------------------------"

  if esStatusOut=$(curl --silent -f "http://localhost:$ES_PORT/_cat/nodes?h=uptime,version"); then
    echo -e "PID\t"
    cat "$ES_PID"
    echo -e "uptime:\t"
    echo "$esStatusOut" | awk '{print $1}'
    echo -e "Elasticsearch Version:\t"
    echo "$esStatusOut" | awk '{print $2}'
  else
    echo -e "\033[38;5;196m"
    echo "Elasticsearch is not running or is unreachable on port $ES_PORT"
    echo -e "\033[0m"
  fi
}

crafterModuleStatus() {
  echo "------------------------------------------------------------------------"
  echo "$1 status"
  echo "------------------------------------------------------------------------"

  if statusOut=$(curl --silent -f "http://localhost:$2$3/api/$4/monitoring/status?token=defaultManagementToken"); then
    echo -e "PID\t"
    cat "$5"
    echo -e "Uptime (in seconds):\t"
    echo "$statusOut" | grep -Eo '"uptime":\d+' | awk -F ":" '{print $2}'
    if versionOut=$(curl --silent -f "http://localhost:$2$3/api/$4/monitoring/version?token=defaultManagementToken"); then
      echo -e "Version:\t"
      echo -n "$(echo "$versionOut" | grep -Eo '"packageVersion":"[^"]+"' | awk -F ":" '{print $2}')"
      echo -n " "
      echo "$versionOut" | grep -Eo '"packageBuild":"[^"]+"' | awk -F ":" '{print $2}'
    fi
  else
    echo -e "\033[38;5;196m"
    echo "$1 is not running or is unreachable on port $2"
    echo -e "\033[0m"
  fi
}

export CRAFTER_HOME=/opt/crafter
export CRAFTER_BIN_DIR=$CRAFTER_HOME/bin
export CRAFTER_BACKUPS_DIR=$CRAFTER_HOME/backups

# shellcheck source=/opt/crafter/bin/crafter-setenv.sh
. "${CRAFTER_BIN_DIR}/crafter-setenv.sh"

if [ "$1" = 'run' ]; then
  runOrDebugCrafter "run"
elif [ "$1" = 'debug' ]; then
  runOrDebugCrafter "debug"
elif [ "$1" = 'status' ]; then
  status
elif [ "$1" = 'selfupdate' ]; then
  echo "Coming soon..."
elif [ "$1" = 'upgrade' ]; then
  echo "Coming soon..."
elif [ "$1" = 'backup' ]; then
  $CRAFTER_BIN_DIR/crafter.sh backup
elif [ "$1" = 'restore' ]; then
  if [ -z "$2" ]; then
    echo "The backup file path was not specified"
    exit 1
  fi
  $CRAFTER_BIN_DIR/crafter.sh restore "$2"
else
  "$@"
fi
