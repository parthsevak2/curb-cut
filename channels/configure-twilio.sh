#!/bin/bash
# Points the Twilio number's Voice and Messaging webhooks at the live tunnel,
# and reports A2P status. Reads credentials from channels/.env, which is
# gitignored and never printed.
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f channels/.env ] || { echo "channels/.env missing — copy channels/.env.example"; exit 1; }
set -a; source channels/.env; set +a
: "${TWILIO_ACCOUNT_SID:?}" "${TWILIO_AUTH_TOKEN:?}" "${TWILIO_NUMBER:?}"
PUBLIC="${1:?usage: configure-twilio.sh https://<tunnel>.trycloudflare.com}"

api() { curl -sS -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN" "$@"; }
BASE="https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID"

echo "== account =="
api "$BASE.json" | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(f\"  {d.get('friendly_name')}  status={d.get('status')}  type={d.get('type')}\")"

echo "== finding the number =="
SID=$(api "$BASE/IncomingPhoneNumbers.json?PhoneNumber=$TWILIO_NUMBER" \
  | python3 -c "import json,sys; l=json.load(sys.stdin)['incoming_phone_numbers']; print(l[0]['sid'] if l else '')")
[ -n "$SID" ] || { echo "  number $TWILIO_NUMBER not found on this account"; exit 1; }
echo "  $TWILIO_NUMBER -> $SID"

echo "== pointing webhooks at $PUBLIC =="
api -X POST "$BASE/IncomingPhoneNumbers/$SID.json" \
  --data-urlencode "VoiceUrl=$PUBLIC/voice" \
  --data-urlencode "VoiceMethod=POST" \
  --data-urlencode "SmsUrl=$PUBLIC/sms" \
  --data-urlencode "SmsMethod=POST" \
  | python3 -c "
import json,sys; d=json.load(sys.stdin)
print('  voice ->', d.get('voice_url'))
print('  sms   ->', d.get('sms_url'))
cap=d.get('capabilities',{})
print('  capabilities:', ', '.join(k for k,v in cap.items() if v))"

echo "== A2P 10DLC (US SMS gate) =="
api "https://messaging.twilio.com/v1/Services" \
  | python3 -c "
import json,sys
d=json.load(sys.stdin); s=d.get('services',[])
print(f'  messaging services: {len(s)}')" 2>/dev/null || echo "  (could not read messaging services)"
api "https://trusthub.twilio.com/v1/CustomerProfiles" \
  | python3 -c "
import json,sys
d=json.load(sys.stdin); p=d.get('results',[])
if not p: print('  no brand registered yet — US SMS will be blocked until approved')
for x in p: print(f\"  {x.get('friendly_name')}: {x.get('status')}\")" 2>/dev/null || echo "  (trusthub not readable)"
