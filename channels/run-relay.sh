#!/bin/bash
# Keeps the text and voice relay reachable: starts a Cloudflare quick tunnel,
# points Twilio at it, then runs the relay in the foreground so launchd can
# restart the whole unit if any part dies. Sleep is prevented for as long as
# this runs (caffeinate), because a laptop that sleeps is a number that goes quiet.
cd "$(dirname "$0")/.." || exit 1   # runs from ~/Library/Application Support/curbcut, outside macOS-protected folders
set -a; source channels/.env; set +a
unset PUBLIC_URL
pkill -f "cloudflared tunnel --url http://localhost:3000" 2>/dev/null
cloudflared tunnel --url http://localhost:3000 > logs/tunnel.log 2>&1 &
TUN=$!
for i in $(seq 1 40); do
  URL=$(grep -o "https://[a-z0-9-]*\.trycloudflare\.com" logs/tunnel.log | head -1)
  [ -n "$URL" ] && break; sleep 1
done
[ -z "$URL" ] && { echo "no tunnel url"; kill $TUN 2>/dev/null; exit 1; }
echo "$URL" > /tmp/curbcut-public-url.txt
bash channels/configure-twilio.sh "$URL" >> logs/twilio-config.log 2>&1
export PUBLIC_URL="$URL"
trap 'kill $TUN 2>/dev/null' EXIT
exec caffeinate -dims node channels/sms-relay.mjs
