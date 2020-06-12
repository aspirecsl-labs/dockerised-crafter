#!/bin/bash
set -e

MAIN_COMMAND=$(basename "$0")
export MAIN_COMMAND

read -r -p "Crafter Version: " CRAFTER_VERSION
export CRAFTER_VERSION

./cam.sh "$@"
