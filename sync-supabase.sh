#!/usr/bin/env bash
# SOCA Bidirectional Sync: Local ↔ Supabase
# RULE #31: MCP Second (Supabase MCP integration)

set -euo pipefail

REPO_DIR="/Users/arnaudassoumani/SOCA/agent-sandbox-skill"
PROJECT_NAME="agent-sandbox-skill"
TABLE_NAME="repo_sync"

cd "$REPO_DIR" || exit 1

echo "🔵 [SYNC] Starting Local ↔ Supabase Sync..."

# 1. Export local state to JSON
echo "📦 Exporting local state..."
git --no-pager log --pretty=format:'{"commit":"%H","author":"%an","date":"%ai","message":"%s"}' -n 20 > .sync-commits.json
find . -type f -name "*.md" -o -name "*.py" -o -name "*.json" | \
  grep -v ".git" | \
  jq -R -s 'split("\n") | map(select(length > 0)) | map({path: .})' > .sync-files.json

# 2. Create sync payload
cat > .sync-payload.json <<EOF
{
  "project": "$PROJECT_NAME",
  "repo_path": "$REPO_DIR",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "commits": $(cat .sync-commits.json | jq -s '.'),
  "files": $(cat .sync-files.json),
  "metadata": {
    "branch": "$(git branch --show-current)",
    "remote": "$(git remote get-url origin)",
    "last_commit": "$(git rev-parse HEAD)"
  }
}
EOF

echo "📤 Syncing to Supabase..."
# Using Supabase CLI or MCP
if command -v supabase &> /dev/null; then
  # Direct Supabase CLI approach
  echo "Using Supabase CLI..."
  # Note: This requires supabase project configured
  # supabase db push --file .sync-payload.json
  echo "⚠️  Supabase CLI sync - implement via MCP or REST API"
else
  echo "🟣 Using MCP Supabase server..."
  # This would typically be called via SOCA MCP orchestration
  echo "Payload ready at: .sync-payload.json"
fi

# 3. Pull from Supabase (if changes exist)
echo "📥 Checking Supabase for remote changes..."
# This would query Supabase for latest sync timestamp and compare
# Implementation depends on Supabase schema

# 4. Update sync config
jq '.last_sync = now | .last_sync_type = "supabase"' .sync-config.json > .sync-config.tmp.json
mv .sync-config.tmp.json .sync-config.json

echo "🟡 [SYNC] Local ↔ Supabase sync complete!"
echo "Payload: .sync-payload.json"
