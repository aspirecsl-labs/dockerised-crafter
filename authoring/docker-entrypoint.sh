#!/bin/bash
set -e

runOrDebugCrafter() {
  if [ "$1" = 'debug' ]; then
    catalinaMode="jpda run"
  else
    catalinaMode="run"
  fi
  echo "------------------------------------------------------------------------"
  echo "Starting Deployer"
  echo "------------------------------------------------------------------------"
  "$DEPLOYER_HOME"/deployer.sh start
  echo "------------------------------------------------------------------------"
  echo "Starting Elasticsearch"
  echo "------------------------------------------------------------------------"
  "$ES_HOME"/elasticsearch -d -p "$ES_PID"
  echo "------------------------------------------------------------------------"
  echo "Starting Tomcat"
  echo "------------------------------------------------------------------------"
  exec "$CRAFTER_BIN_DIR"/apache-tomcat/bin/catalina.sh $catalinaMode
}

status() {
  elasticsearchStatus
  crafterModuleStatus "Crafter Engine" "$TOMCAT_HTTP_PORT" "" "1"
  crafterModuleStatus "Crafter Studio" "$TOMCAT_HTTP_PORT" "/studio" "2"
  crafterModuleStatus "Crafter Search" "$TOMCAT_HTTP_PORT" "/crafter-search" "1"
  crafterModuleStatus "Crafter Deployer" "$DEPLOYER_PORT" "" "1" "$DEPLOYER_PID"
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
    if [ "${5:-X}" != 'X' ]; then
      echo -e "PID\t"
      cat "$5"
    fi
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

# reset permissions on volumes originating from the volume container
sudo chown -R crafter:crafter $CRAFTER_HOME/data
sudo chown -R crafter:crafter $CRAFTER_HOME/backups

# shellcheck source=/opt/crafter/bin/crafter-setenv.sh
source "${CRAFTER_BIN_DIR}/crafter-setenv.sh"

if [ "$1" = 'run' ]; then
  runOrDebugCrafter "run"
elif [ "$1" = 'debug' ]; then
  runOrDebugCrafter "debug"
elif [ "$1" = 'status' ]; then
  echo -e "\n"
  status
  echo -e "\n"
elif [ "$1" = 'version' ]; then
  echo -e "\n"
  echo "Crafter Info:"
  echo "-------------"
  cat /etc/release
  echo -e "\n"
  cd "${CRAFTER_BIN_DIR}/apache-tomcat/lib"
  echo "Server Info:"
  echo "------------"
  exec java -cp catalina.jar org.apache.catalina.util.ServerInfo
  echo -e "\n"
elif [ "$1" = 'backup' ]; then
  exec /crafter-entrypoint.sh backup
elif [ "$1" = 'restore' ]; then
  if [ -z "$2" ]; then
    echo -e "\nThe backup file name was not specified"
    echo -e "Try again by specifying a backup file name from the following list:-\n"
    cd "$CRAFTER_BACKUPS_DIR"
    ls -ltr crafter-authoring-backup*
    echo -e "\n"
    exit 1
  fi
  exec /crafter-entrypoint.sh restore "$2"
else
  exec "$@"
fi
