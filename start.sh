#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <instance-name>"
  exit 1
fi

NAME="$1"
ENV_FILE=".env.${NAME}"

if [ ! -f "$ENV_FILE" ]; then
  echo "No $ENV_FILE found — generating..."
  ./generate-env.sh "$NAME"
  exit 0
fi

docker compose --env-file "$ENV_FILE" up -d
