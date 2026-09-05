#!/bin/bash
# Installs two launchd agents that keep the text and voice relay (with its
# tunnel) and the Slack app running on this Mac: start at login, restart on
# exit, never let the machine sleep while they run. The files are copied to
# ~/Library/Application Support/curbcut because launchd cannot read a repo
# that lives in a macOS-protected folder such as Downloads.
set -e
cd "$(dirname "$0")/.."
APP="$HOME/Library/Application Support/curbcut"
mkdir -p "$APP/logs" "$HOME/Library/LaunchAgents"
rsync -a --delete channels/ "$APP/channels/"; rsync -a --delete node_modules/ "$APP/node_modules/"; cp package.json "$APP/"
NODE=$(dirname "$(command -v node)"); CF=$(dirname "$(command -v cloudflared)"); SFB=$(dirname "$(command -v sf)")
for unit in relay slack; do
  P="$HOME/Library/LaunchAgents/com.curbcut.$unit.plist"
  cat > "$P" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.curbcut.$unit</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$APP/channels/run-$unit.sh</string></array>
  <key>WorkingDirectory</key><string>$APP</string>
  <key>EnvironmentVariables</key><dict><key>PATH</key><string>$NODE:$CF:$SFB:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin</string><key>HOME</key><string>$HOME</string></dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>15</integer>
  <key>StandardOutPath</key><string>$APP/logs/$unit.out.log</string>
  <key>StandardErrorPath</key><string>$APP/logs/$unit.err.log</string>
</dict></plist>
PL
  launchctl bootout "gui/$(id -u)/com.curbcut.$unit" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$P"
  echo "loaded com.curbcut.$unit"
done
echo "Logs: $APP/logs. Public URL: /tmp/curbcut-public-url.txt. Stop with: launchctl bootout gui/\$(id -u)/com.curbcut.relay (and .slack)."
