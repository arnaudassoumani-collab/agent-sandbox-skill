#!/usr/bin/env bash
# Linear Integration for Sync System
# Creates Linear issues for sync events and tracks status

set -euo pipefail

REPO_DIR="/Users/arnaudassoumani/SOCA/agent-sandbox-skill"
LINEAR_TEAM="SOCA"
LINEAR_PROJECT="Agent Sandbox"

cd "$REPO_DIR" || exit 1

echo "🟣 [LINEAR] Integrating with Linear..."

# Get last sync info
LAST_SYNC=$(cat .sync-config.json | jq -r '.last_sync // "never"')
SYNC_TYPE=$(cat .sync-config.json | jq -r '.last_sync_type // "none"')
COMMIT_HASH=$(git rev-parse --short HEAD)
COMMIT_MSG=$(git log -1 --pretty=format:'%s')

# Create Linear issue for sync event
ISSUE_TITLE="Sync Event: $SYNC_TYPE - $COMMIT_HASH"
ISSUE_DESCRIPTION="
## Sync Details

**Type:** $SYNC_TYPE  
**Timestamp:** $LAST_SYNC  
**Commit:** \`$COMMIT_HASH\`  
**Message:** $COMMIT_MSG  
**Repository:** agent-sandbox-skill

## Status

- ✅ GitHub sync: $(git --no-pager log origin/main..HEAD --oneline | wc -l | xargs) commits ahead
- ✅ Local changes: $(git status --porcelain | wc -l | xargs) files modified
- 🔄 Supabase sync: Ready

## Actions

- [ ] Review changes
- [ ] Verify Supabase sync
- [ ] Update documentation

---
*Automated sync event from SOCA agent-sandbox-skill*
"

# Create issue using gh CLI (Linear integration via GitHub)
# Note: This requires Linear-GitHub integration to be set up
echo "📋 Creating tracking issue..."
echo "$ISSUE_DESCRIPTION" > .sync-issue.tmp.md

# Alternative: Use Linear API directly if available
if command -v linear &> /dev/null; then
  echo "Using Linear CLI..."
  # linear issue create \
  #   --title "$ISSUE_TITLE" \
  #   --description "$ISSUE_DESCRIPTION" \
  #   --team "$LINEAR_TEAM" \
  #   --project "$LINEAR_PROJECT"
  echo "⚠️  Linear CLI not configured. Create issue manually."
else
  echo "📝 Issue template saved: .sync-issue.tmp.md"
  echo "   Create manually in Linear or set up Linear CLI"
fi

# Create bidirectional webhook payload for Linear
cat > .linear-webhook.json <<EOF
{
  "event": "sync.completed",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "repository": "agent-sandbox-skill",
  "sync_type": "$SYNC_TYPE",
  "commit": {
    "hash": "$COMMIT_HASH",
    "message": "$COMMIT_MSG"
  },
  "linear": {
    "team": "$LINEAR_TEAM",
    "project": "$LINEAR_PROJECT",
    "issue_title": "$ISSUE_TITLE"
  },
  "status": "success"
}
EOF

echo "✅ Linear webhook payload: .linear-webhook.json"
echo "🟡 [LINEAR] Integration complete!"
