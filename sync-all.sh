#!/usr/bin/env bash
# SOCA Full Bidirectional Sync: GitHub ↔ Local ↔ Supabase
# RULE #28 & #31: CLI-First orchestration

set -euo pipefail

REPO_DIR="/Users/arnaudassoumani/SOCA/agent-sandbox-skill"
cd "$REPO_DIR" || exit 1

echo "🟡 [SYNC-ALL] Starting Full Bidirectional Sync..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Phase 1: GitHub ↔ Local
echo ""
echo "Phase 1: GitHub ↔ Local"
bash sync-github-local.sh || {
  echo "❌ GitHub sync failed"
  exit 1
}

# Phase 2: Local ↔ Supabase
echo ""
echo "Phase 2: Local ↔ Supabase"
bash sync-supabase.sh || {
  echo "❌ Supabase sync failed"
  exit 1
}

# Phase 3: Verification
echo ""
echo "Phase 3: Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Show current state
echo "📊 Current State:"
echo "  Git Status: $(git --no-pager status --short | wc -l) pending changes"
echo "  Last Commit: $(git log -1 --pretty=format:'%h - %s')"
echo "  Branch: $(git branch --show-current)"
echo "  Remote: $(git remote get-url origin)"

# Show sync config
echo ""
echo "🔧 Sync Config:"
cat .sync-config.json | jq '{last_sync, last_sync_type, sync}'

echo ""
echo "🟢 [SYNC-ALL] All syncs complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
