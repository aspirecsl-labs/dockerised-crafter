#!/bin/bash
set -e

if curl -sSLf http://localhost:9201/_cat/nodes?h=uptime,version >/dev/null &&
  curl -sSLf http://localhost:9191/api/1/monitoring/status?token=defaultManagementToken >/dev/null &&
  curl -sSLf http://localhost:8080/api/1/monitoring/status?token=defaultManagementToken >/dev/null &&
  curl -sSLf http://localhost:8080/studio/api/2/monitoring/status?token=defaultManagementToken >/dev/null &&
  curl -sSLf http://localhost:8080/crafter-search/api/1/monitoring/status?token=defaultManagementToken >/dev/null; then
  exit 0
else
  exit 1
fi
