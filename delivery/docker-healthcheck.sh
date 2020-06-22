#!/bin/bash
set -e

if curl -sSLf http://localhost:9202/_cat/nodes?h=uptime,version >/dev/null &&
  curl -sSLf http://localhost:9192/api/1/monitoring/status?token=defaultManagementToken >/dev/null &&
  curl -sSLf http://localhost:9080/api/1/monitoring/status?token=defaultManagementToken >/dev/null &&
  curl -sSLf http://localhost:9080/crafter-search/api/1/monitoring/status?token=defaultManagementToken >/dev/null; then
  exit 0
else
  exit 1
fi
