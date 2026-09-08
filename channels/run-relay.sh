#!/bin/bash
# Keeps the text and voice relay reachable: starts a Cloudflare quick tunnel,
# points Twilio at it, then runs the relay in the foreground so launchd can
# restart the whole unit if any part dies. Sleep is prevented for as long as
# this runs (caffeinate), because a laptop that sleeps is a number that goes quiet.
cd "$(dirname "$0")/.." || exit 1   # runs from ~/Library/Application Support/curbcut, outside macOS-protected folders
set -a; source channels/.env; set +a
unset PUBLIC_URL
pkill -f "cloudflared tunnel --url http://localhost:3000" 2>/dev/null

# Open a quick tunnel. cloudflared's own error text mentions api.trycloudflare.com,
# so only a hostname that is not "api" counts, and only once the tunnel says it is up.
URL=""
for attempt in 1 2 3 4 5; do
  : > logs/tunnel.log
  cloudflared tunnel --url http://localhost:3000 >> logs/tunnel.log 2>&1 &
  TUN=$!
  for i in $(seq 1 40); do
    URL=$(grep -o "https://[a-z0-9-]*\.trycloudflare\.com" logs/tunnel.log | grep -v "^https://api\." | head -1)
    [ -n "$URL" ] && break
    if grep -q "failed to request quick Tunnel" logs/tunnel.log || ! kill -0 $TUN 2>/dev/null; then break; fi
    sleep 1
  done
  [ -n "$URL" ] && break
  echo "tunnel attempt $attempt failed" >> logs/relay.err.log
  kill $TUN 2>/dev/null; sleep 10
done
[ -z "$URL" ] && { echo "no tunnel url after 5 attempts"; exit 1; }
echo "$URL" > /tmp/curbcut-public-url.txt
bash channels/configure-twilio.sh "$URL" >> logs/twilio-config.log 2>&1
export PUBLIC_URL="$URL"

# Watchdog: the public URL must answer with this relay's own health line, and the
# tunnel process must still be alive. A quick tunnel's hostname can take several
# minutes to appear in DNS, so nothing is judged for the first six minutes; after
# that, three misses in a row (about two minutes) and the unit leaves, and launchd
# restarts the whole thing with a fresh tunnel and re-points Twilio.
healthy() { curl -sf -m 15 "$URL/health" 2>/dev/null | grep -q "curbcut-relay ok" && kill -0 $TUN 2>/dev/null; }
( sleep 360; misses=0; while true; do sleep 40; if healthy; then misses=0; else misses=$((misses+1)); fi
  if [ $misses -ge 3 ]; then echo "$(date -u +%FT%TZ) watchdog: $URL not answering as the relay, restarting" >> logs/relay.err.log; pkill -P $$ 2>/dev/null; kill -TERM $$ 2>/dev/null; fi; done ) &
trap 'kill $TUN 2>/dev/null' EXIT
exec caffeinate -dims node channels/sms-relay.mjs
