#!/bin/bash
set -e

runOrDebugCrafter() {
  local catalinaMode
  if [ "$1" = 'debug' ]; then
    catalinaMode="jpda run"
  else
    catalinaMode="run"
  fi
  echo "------------------------------------------------------------------------"
  echo "Starting OpenSSH Server"
  echo "------------------------------------------------------------------------"
  sudo sudo service ssh start
  echo "------------------------------------------------------------------------"
  echo "Starting Apache"
  echo "------------------------------------------------------------------------"
  sudo service apache2 start
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
  mariaDbStatus
  elasticsearchStatus
  crafterModuleStatus "Crafter Engine" "$TOMCAT_HTTP_PORT" "" "1"
  crafterModuleStatus "Crafter Studio" "$TOMCAT_HTTP_PORT" "/studio" "2"
  crafterModuleStatus "Crafter Search" "$TOMCAT_HTTP_PORT" "/crafter-search" "1"
  crafterModuleStatus "Crafter Deployer" "$DEPLOYER_PORT" "" "1" "$DEPLOYER_PID"
}

function mariaDbStatus() {
  echo "------------------------------------------------------------------------"
  echo "MariaDB status"
  echo "------------------------------------------------------------------------"
  if [ -s "$MARIADB_PID" ]; then
    echo -e "PID \t"
    cat "$MARIADB_PID"
  else
    echo "MariaDB is not running."
  fi
}

elasticsearchStatus() {
  echo "------------------------------------------------------------------------"
  echo "Elasticsearch status"
  echo "------------------------------------------------------------------------"

  local esStatusOut
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

  local statusOut
  if statusOut=$(curl --silent -f "http://localhost:$2$3/api/$4/monitoring/status?token=defaultManagementToken"); then
    if [ "${5:-X}" != 'X' ]; then
      echo -e "PID\t"
      cat "$5"
    fi
    echo -e "Uptime (in seconds):\t"
    echo "$statusOut" | grep -Eo '"uptime":\d+' | awk -F ":" '{print $2}'
    local versionOut
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

# source=/opt/crafter/bin/crafter-setenv.sh
# shellcheck disable=SC1090
source "${CRAFTER_BIN_DIR}/crafter-setenv.sh"

if [ "$1" = 'run' ]; then
  runOrDebugCrafter "run"
elif [ "$1" = 'debug' ]; then
  runOrDebugCrafter "debug"
elif [ "$1" = 'recovery' ]; then
  echo ""
  echo "------------------------------------------------------------------"
  echo "If restoring from a backup:-"
  echo "  Run the following command to start crafter services"
  echo "  after the instance is successfully restored:"
  echo ""
  echo "    /docker-entrypoint.sh run"
  echo "------------------------------------------------------------------"
  echo ""
  exec /bin/bash
elif [ "$1" = 'status' ]; then
  echo ""
  status
  echo ""
elif [ "$1" = 'version' ]; then
  echo ""
  echo "Crafter Info:"
  echo "-------------"
  curl --silent --show-error http://localhost:8080/studio/api/2/monitoring/version?token=defaultManagementToken
  echo ""
  cd "${CRAFTER_BIN_DIR}/apache-tomcat/lib"
  echo "Server Info:"
  echo "------------"
  exec java -cp catalina.jar org.apache.catalina.util.ServerInfo
  echo ""
elif [ "$1" = 'backup' ]; then
  exec ${CRAFTER_BIN_DIR}/crafter.sh backup
else
  exec "$@"
fi
