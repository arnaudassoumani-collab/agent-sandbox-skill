#!/usr/bin/env bash
# SOCA Sync Installer: Sets up automated bidirectional sync
# Installs launchd service on macOS for background syncing

set -euo pipefail

REPO_DIR="/Users/arnaudassoumani/SOCA/agent-sandbox-skill"
SERVICE_NAME="com.soca.agent-sandbox-sync"
PLIST_PATH="$HOME/Library/LaunchAgents/${SERVICE_NAME}.plist"

echo "🔧 Installing SOCA Bidirectional Sync Service..."

# 1. Create LaunchAgent plist
cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${SERVICE_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${REPO_DIR}/sync-all.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${REPO_DIR}/logs/sync.log</string>
    <key>StandardErrorPath</key>
    <string>${REPO_DIR}/logs/sync-error.log</string>
    <key>WorkingDirectory</key>
    <string>${REPO_DIR}</string>
</dict>
</plist>
EOF

# 2. Create logs directory
mkdir -p "$REPO_DIR/logs"

# 3. Load the service
echo "📦 Loading LaunchAgent..."
launchctl load "$PLIST_PATH" 2>/dev/null || launchctl unload "$PLIST_PATH" && launchctl load "$PLIST_PATH"

echo ""
echo "✅ Installation Complete!"
echo ""
echo "Service installed: ${SERVICE_NAME}"
echo "Sync interval: Every 5 minutes"
echo "Logs: ${REPO_DIR}/logs/"
echo ""
echo "Commands:"
echo "  Start:  launchctl start ${SERVICE_NAME}"
echo "  Stop:   launchctl stop ${SERVICE_NAME}"
echo "  Status: launchctl list | grep soca"
echo "  Logs:   tail -f ${REPO_DIR}/logs/sync.log"
echo ""
echo "Manual sync: cd $REPO_DIR && ./sync-all.sh"
