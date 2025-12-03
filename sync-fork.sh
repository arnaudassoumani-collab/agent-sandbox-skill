#!/usr/bin/env bash
# SOCA Fork-Based Sync: Upstream ↔ Fork ↔ Local ↔ Supabase
# RULE #28: CLI-First with gh CLI

set -euo pipefail

REPO_DIR="/Users/arnaudassoumani/SOCA/agent-sandbox-skill"
UPSTREAM_REPO="disler/agent-sandbox-skill"
FORK_OWNER="arnaudassoumani-collab"
BRANCH="main"

cd "$REPO_DIR" || exit 1

echo "🔵 [FORK-SYNC] Setting up fork-based bidirectional sync..."

# 1. Check if we have a fork
FORK_EXISTS=$(gh repo list "$FORK_OWNER" --json name --jq '.[] | select(.name=="agent-sandbox-skill") | .name' || echo "")

if [[ -z "$FORK_EXISTS" ]]; then
  echo "📌 Creating fork of $UPSTREAM_REPO..."
  gh repo fork "$UPSTREAM_REPO" --clone=false --remote=false
  echo "✅ Fork created!"
else
  echo "✅ Fork already exists: $FORK_OWNER/agent-sandbox-skill"
fi

# 2. Configure remotes
echo "🔧 Configuring git remotes..."
git remote remove upstream 2>/dev/null || true
git remote remove origin 2>/dev/null || true

git remote add upstream "https://github.com/$UPSTREAM_REPO.git"
git remote add origin "git@github.com:$FORK_OWNER/agent-sandbox-skill.git"

echo "✅ Remotes configured:"
git remote -v

# 3. Sync workflow: Upstream → Fork → Local
echo ""
echo "🔄 Syncing Upstream → Fork → Local..."

# Fetch from upstream
git fetch upstream --quiet
echo "📥 Fetched from upstream"

# Merge upstream into local
if ! git diff --quiet HEAD upstream/$BRANCH; then
  echo "🔄 Merging upstream changes..."
  git merge upstream/$BRANCH --no-edit --quiet || {
    echo "⚠️  Merge conflict. Manual resolution needed."
    exit 1
  }
  echo "✅ Merged upstream changes"
else
  echo "✅ Already up-to-date with upstream"
fi

# 4. Push to our fork
if [[ -n $(git --no-pager log origin/$BRANCH..$BRANCH 2>/dev/null || echo "new") ]]; then
  echo "📤 Pushing to fork..."
  git push origin "$BRANCH" --quiet
  echo "✅ Pushed to fork"
else
  echo "✅ Fork is up-to-date"
fi

# 5. Handle local changes
if [[ -n $(git --no-pager status --porcelain) ]]; then
  echo ""
  echo "📝 Local changes detected:"
  git --no-pager status --short
  
  read -p "Commit and push local changes? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git add -A
    git commit -m "chore: Local changes - $(date +%Y-%m-%d\ %H:%M:%S)" --quiet
    git push origin "$BRANCH" --quiet
    echo "✅ Local changes pushed to fork"
  fi
fi

# 6. Update sync config
jq '.last_sync = now | .last_sync_type = "fork-sync" | .sync.github.remote = "origin" | .sync.github.fork = "origin" | .sync.github.upstream = "upstream"' .sync-config.json > .sync-config.tmp.json
mv .sync-config.tmp.json .sync-config.json

echo ""
echo "🟡 [FORK-SYNC] Complete!"
echo "   Upstream: $UPSTREAM_REPO"
echo "   Fork: $FORK_OWNER/agent-sandbox-skill"
echo "   Local: $REPO_DIR"
