#!/usr/bin/env bash
# SOCA Bidirectional Sync: GitHub ↔ Local
# RULE #28 & #31: CLI-First, gh CLI only

set -euo pipefail

REPO_DIR="/Users/arnaudassoumani/SOCA/agent-sandbox-skill"
REMOTE="origin"
BRANCH="main"

cd "$REPO_DIR" || exit 1

echo "🔵 [SYNC] Starting GitHub ↔ Local Sync..."

# 1. Pull from GitHub
echo "📥 Pulling from GitHub..."
git fetch "$REMOTE" --quiet
git --no-pager status --short

if git diff --quiet HEAD "$REMOTE/$BRANCH"; then
  echo "✅ Local is up to date with GitHub"
else
  echo "🔄 Changes detected. Merging from GitHub..."
  git pull "$REMOTE" "$BRANCH" --rebase --quiet || {
    echo "⚠️  Merge conflict detected. Manual intervention required."
    exit 1
  }
  echo "✅ Merged changes from GitHub"
fi

# 2. Push to GitHub (if local changes)
if [[ -n $(git --no-pager status --porcelain) ]]; then
  echo "📤 Local changes detected. Syncing to GitHub..."
  git add -A
  git commit -m "chore: Auto-sync from local [$(date +%Y-%m-%d\ %H:%M:%S)]" --quiet || echo "Nothing to commit"
  git push "$REMOTE" "$BRANCH" --quiet
  echo "✅ Pushed to GitHub"
else
  echo "✅ No local changes to push"
fi

# 3. Update sync timestamp
jq '.last_sync = now | .last_sync_type = "github-local"' .sync-config.json > .sync-config.tmp.json
mv .sync-config.tmp.json .sync-config.json

echo "🟡 [SYNC] GitHub ↔ Local sync complete!"
