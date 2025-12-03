# Agent Sandbox Skill - Bidirectional Sync

🔵 **GitHub ↔ Local ↔ Supabase Sync System**

This repository is equipped with a comprehensive bidirectional sync system following SOCA RULE #28 & #31 (CLI-First, MCP Second).

## 🔄 Sync Architecture

```
GitHub (Origin)
    ↕️  [git CLI]
Local Repository
    ↕️  [Supabase MCP]
Supabase Database
```

## 🚀 Quick Start

### Manual Sync
```bash
# Full bidirectional sync (GitHub ↔ Local ↔ Supabase)
./sync-all.sh

# GitHub ↔ Local only
./sync-github-local.sh

# Local ↔ Supabase only
./sync-supabase.sh
```

### Automated Sync
```bash
# Install background service (runs every 5 minutes)
./install-sync-service.sh

# Watch mode (continuous monitoring)
./sync-watch.sh
```

## 📋 Sync Configuration

Edit `.sync-config.json` to customize:
- Sync intervals
- Conflict resolution strategy
- Enabled/disabled sync targets
- Watch patterns

## 🗄️ Supabase Setup

1. **Create Supabase Project** (if not exists)
```bash
supabase init
supabase start
```

2. **Apply Schema**
```bash
supabase db reset --db-url <your-supabase-url>
# Or manually execute supabase-schema.sql in your Supabase SQL editor
```

3. **Configure MCP** (see SOCA/mcp/supabase/)
```json
{
  "supabase": {
    "url": "your-project-url",
    "key": "your-anon-key"
  }
}
```

## 📊 Sync Flow

### GitHub → Local
1. Fetch changes from origin
2. Check for conflicts
3. Merge with rebase
4. Update local files

### Local → GitHub
1. Detect local changes (git status)
2. Stage all changes
3. Auto-commit with timestamp
4. Push to origin

### Local ↔ Supabase
1. Export git metadata (commits, branches)
2. Index tracked files
3. Send payload to Supabase via MCP
4. Listen for remote changes (real-time subscription)
5. Apply remote changes locally

## 🔐 Security

- All syncs use CLI-first approach (RULE #28)
- Credentials via 1Password integration
- No hardcoded secrets (use `.env` template)
- Sandbox isolation (L1 COPILOT level)

## 📁 File Structure

```
agent-sandbox-skill/
├── .sync-config.json         # Sync configuration
├── sync-all.sh               # Full bidirectional sync
├── sync-github-local.sh      # GitHub ↔ Local
├── sync-supabase.sh          # Local ↔ Supabase
├── sync-watch.sh             # Continuous monitoring
├── install-sync-service.sh   # Background service installer
├── supabase-schema.sql       # Database schema
└── logs/                     # Sync logs
    ├── sync.log
    └── sync-error.log
```

## 🎯 Use Cases

1. **Multi-Device Development**: Keep code synced across machines via GitHub
2. **Backup & Recovery**: Supabase as secondary storage layer
3. **Team Collaboration**: Real-time sync notifications
4. **Audit Trail**: Complete history in Supabase tables
5. **Linear Integration**: Sync status tracked in Linear (via webhooks)

## 🔔 Monitoring

```bash
# View sync logs
tail -f logs/sync.log

# Check service status
launchctl list | grep soca

# Verify last sync
cat .sync-config.json | jq '.last_sync, .last_sync_type'
```

## 🛠️ Troubleshooting

**Merge Conflicts**
- Manual intervention required
- Resolve in your editor, then re-run sync

**Supabase Connection Issues**
- Check MCP server status: `docker ps | grep supabase-mcp`
- Verify credentials in `.env`

**Sync Service Not Running**
- Reload: `launchctl unload ~/Library/LaunchAgents/com.soca.agent-sandbox-sync.plist && launchctl load ~/Library/LaunchAgents/com.soca.agent-sandbox-sync.plist`

---

**SOCA-STAMP**  
type: sync-system  
related: ["CONSTITUTION.md", "AGENTS.md", "SOCAcore.md"]
