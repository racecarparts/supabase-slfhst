#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <instance-name> [--destroy]"
  echo ""
  echo "  --destroy   Remove containers and volumes (wipes all data)"
  exit 1
fi

NAME="$1"
ENV_FILE=".env.${NAME}"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found."
  exit 1
fi

if [ "${2:-}" = "--destroy" ]; then
  docker compose --env-file "$ENV_FILE" down -v
  # Bind mount dirs are not removed by down -v — wipe via a throwaway container
  # to avoid needing sudo (postgres data is owned by container uid)
  docker run --rm \
    -v "$(pwd)/volumes/db/data:/data/db" \
    -v "$(pwd)/volumes/storage:/data/storage" \
    alpine sh -c "rm -rf /data/db/* /data/db/.[!.]* /data/storage/* /data/storage/.[!.]*"
else
  docker compose --env-file "$ENV_FILE" down
fi
