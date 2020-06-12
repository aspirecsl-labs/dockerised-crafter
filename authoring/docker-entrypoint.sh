#!/bin/bash
set -e
# set -x

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
  exec "$CRAFTER_BIN_DIR"/apache-tomcat/bin/catalina.sh $catalinaMode
}

status() {
  elasticsearchStatus
  crafterModuleStatus "Crafter Deployer" "$DEPLOYER_PORT" "" "1" "$DEPLOYER_PID"
  crafterModuleStatus "Crafter Engine" "$TOMCAT_HTTP_PORT" "" "1"
  crafterModuleStatus "Crafter Studio" "$TOMCAT_HTTP_PORT" "/studio" "2"
  crafterModuleStatus "Crafter Search" "$TOMCAT_HTTP_PORT" "/crafter-search" "1"
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

shutdown() {
  echo "------------------------------------------------------------------------"
  echo "Stopping Tomcat"
  echo "------------------------------------------------------------------------"
  "$CRAFTER_BIN_DIR"/apache-tomcat/bin/shutdown.sh 10 -force
  cd "$DEPLOYER_HOME"
  echo "------------------------------------------------------------------------"
  echo "Stopping Deployer"
  echo "------------------------------------------------------------------------"
  "$DEPLOYER_HOME"/deployer.sh stop
  cd "$CRAFTER_BIN_DIR"
  echo "------------------------------------------------------------------------"
  echo "Stopping Elasticsearch"
  echo "------------------------------------------------------------------------"
  pkill -15 -F "$ES_PID"
  sleep 3
  if pgrep -F "$ES_PID" >/dev/null; then
    pkill -9 -F "$ES_PID"
  fi
}

trap shutdown EXIT

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
elif [ "$1" = 'upgrade' ]; then
  echo "Coming soon..."
elif [ "$1" = 'backup' ]; then
  $CRAFTER_BIN_DIR/crafter.sh backup
elif [ "$1" = 'restore' ]; then
  backup_to_apply=/opt/crafter/backups/backup.apply
  if [ -s "$backup_to_apply" ]; then
    ts=$(date +%Y%m%d-%H%M%S)
    backup_applied=/opt/crafter/backups/backup.applied."$ts"
    if $CRAFTER_BIN_DIR/crafter.sh restore $backup_to_apply; then
      mv -f $backup_to_apply "$backup_applied"
    else
      echo -e "\Backup restoration failed!!!\n" >&2
    fi
  else
    echo -e "\nNo backup.apply file found!!!\n" >&2
    exit 1
  fi
else
  exec "$@"
fi
