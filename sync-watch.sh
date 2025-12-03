#!/usr/bin/env bash
# SOCA Watch Mode: Continuous bidirectional sync
# Watches for file changes and triggers sync automatically

set -euo pipefail

REPO_DIR="/Users/arnaudassoumani/SOCA/agent-sandbox-skill"
WATCH_INTERVAL=60  # seconds
SYNC_INTERVAL=300  # 5 minutes

cd "$REPO_DIR" || exit 1

echo "👁️  [WATCH] Starting continuous sync watcher..."
echo "   Interval: ${WATCH_INTERVAL}s check, ${SYNC_INTERVAL}s full sync"

LAST_SYNC=$(date +%s)

while true; do
  CURRENT_TIME=$(date +%s)
  TIME_SINCE_SYNC=$((CURRENT_TIME - LAST_SYNC))
  
  # Check for local changes
  if [[ -n $(git status --porcelain) ]]; then
    echo "🔄 Local changes detected. Triggering sync..."
    bash sync-github-local.sh
    LAST_SYNC=$(date +%s)
  fi
  
  # Periodic full sync
  if [[ $TIME_SINCE_SYNC -ge $SYNC_INTERVAL ]]; then
    echo "⏰ Periodic sync triggered..."
    bash sync-all.sh
    LAST_SYNC=$(date +%s)
  fi
  
  sleep "$WATCH_INTERVAL"
done
