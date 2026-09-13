#!/bin/bash
# Keeps the text and voice relay reachable: starts a Cloudflare quick tunnel,
# points Twilio at it, then runs the relay in the foreground so launchd can
# restart the whole unit if any part dies. Sleep is prevented for as long as
# this runs (caffeinate), because a laptop that sleeps is a number that goes quiet.
cd "$(dirname "$0")/.." || exit 1   # runs from ~/Library/Application Support/curbcut, outside macOS-protected folders
set -a; source channels/.env; set +a
unset PUBLIC_URL
# QUIC to Cloudflare's edge dropped its control stream dozens of times an hour on
# some networks; HTTP/2 over port 443 holds and passes most venue firewalls.
# cloudflared reads this variable for its (hidden) --protocol flag.
export TUNNEL_TRANSPORT_PROTOCOL=http2
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
  echo "$(date -u +%FT%TZ) tunnel attempt $attempt failed" >> logs/relay.err.log
  kill $TUN 2>/dev/null; sleep 10
done
[ -z "$URL" ] && { echo "no tunnel url after 5 attempts"; exit 1; }
echo "$URL" > /tmp/curbcut-public-url.txt

# Point Twilio at it. A single network reset here once left the number aimed at a
# dead tunnel while everything else looked healthy, so this retries, and if Twilio
# still has not taken the new address the unit leaves and launchd starts over.
pointed=""
for attempt in 1 2 3 4 5; do
  if bash channels/configure-twilio.sh "$URL" >> logs/twilio-config.log 2>&1; then pointed=1; break; fi
  echo "$(date -u +%FT%TZ) twilio re-point attempt $attempt failed" >> logs/relay.err.log
  sleep $((attempt * 15))
done
[ -z "$pointed" ] && { echo "could not point Twilio at $URL"; kill $TUN 2>/dev/null; exit 1; }
export PUBLIC_URL="$URL"

# Watchdog. A quick tunnel's hostname can take minutes to appear in DNS, so nothing
# is judged for the first six minutes. After that the public URL must answer with
# this relay's own health line while the tunnel process lives. A tunnel that flaps
# used to reset a plain miss counter for most of an hour, so the rule is a window:
# three misses in the last six checks and the unit leaves, and launchd restarts it
# with a fresh tunnel. Every tenth check also asks Twilio where the number points
# and re-points it if it is aimed anywhere else.
healthy() { curl -sf -m 15 "$URL/health" 2>/dev/null | grep -q "curbcut-relay ok" && kill -0 $TUN 2>/dev/null; }
twilio_points_here() {
  curl -sf -m 20 -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN" \
    "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/IncomingPhoneNumbers.json?PhoneNumber=${TWILIO_NUMBER/+/%2B}" \
  | python3 -c "import json,sys; l=json.load(sys.stdin)['incoming_phone_numbers']; sys.exit(0 if l and l[0]['voice_url']==sys.argv[1]+'/voice' and l[0]['sms_url']==sys.argv[1]+'/sms' else 1)" "$URL"
}
( sleep 360; hist=""; n=0
  while true; do
    sleep 40; n=$((n+1))
    if healthy; then hist="${hist}1"; else hist="${hist}0"; fi
    hist=$(printf "%s" "$hist" | tail -c 6)
    misses=$(printf "%s" "$hist" | tr -cd 0 | wc -c | tr -d ' ')
    if [ "$misses" -ge 3 ]; then
      echo "$(date -u +%FT%TZ) watchdog: $URL missed $misses of the last ${#hist} checks, restarting" >> logs/relay.err.log
      pkill -P $$ 2>/dev/null; kill -TERM $$ 2>/dev/null; exit 0
    fi
    if [ $((n % 10)) -eq 0 ] && ! twilio_points_here; then
      echo "$(date -u +%FT%TZ) watchdog: Twilio is not pointed at $URL, re-pointing" >> logs/relay.err.log
      bash channels/configure-twilio.sh "$URL" >> logs/twilio-config.log 2>&1 \
        || echo "$(date -u +%FT%TZ) watchdog: re-point failed, trying again in about seven minutes" >> logs/relay.err.log
    fi
  done ) &
trap 'kill $TUN 2>/dev/null' EXIT
exec caffeinate -dims node channels/sms-relay.mjs
