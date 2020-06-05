#!/bin/bash
set -e

export CRAFTER_HOME=/opt/crafter
export CRAFTER_BIN_DIR=$CRAFTER_HOME/bin
export CRAFTER_BACKUPS_DIR=$CRAFTER_HOME/backups

# shellcheck source=/opt/crafter/bin/crafter-setenv.sh
. "${CRAFTER_BIN_DIR}/crafter-setenv.sh"

if [ "$1" = 'run' ]; then
  exec $CRAFTER_BIN_DIR/apache-tomcat/bin/catalina.sh run
elif [ "$1" = 'debug' ]
then
    exec $CRAFTER_BIN_DIR/apache-tomcat/bin/catalina.sh jpda run
elif [ "$1" = 'backup' ]
then
    exec $CRAFTER_BIN_DIR/crafter.sh backup
elif [ "$1" = 'restore' ]
then
    if [ -z "$2" ]
    then
        echo "The backup path parameter was not specified"
        exit 1
    fi
    exec $CRAFTER_BIN_DIR/crafter.sh restore "$2"
else
  exec "$@"
fi

