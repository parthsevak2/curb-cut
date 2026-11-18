#!/usr/bin/env bash
# One-command Curb Cut install. Usage: bash scripts/install.sh <org-alias> [--skip-tests]
set -euo pipefail

ALIAS=""
SKIP_TESTS=0
for arg in "$@"; do
  case "$arg" in
    --skip-tests) SKIP_TESTS=1 ;;
    -*) echo "I do not know the option $arg. Use: bash scripts/install.sh <org-alias> [--skip-tests]"; exit 2 ;;
    *) [ -z "$ALIAS" ] && ALIAS="$arg" || { echo "Give one org alias only. Use: bash scripts/install.sh <org-alias> [--skip-tests]"; exit 2; } ;;
  esac
done
[ -n "$ALIAS" ] || { echo "Tell me which org to install into. Use: bash scripts/install.sh <org-alias> [--skip-tests]"; exit 2; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

say()  { echo "==> $*"; }
die()  { echo "Stopped: $*" >&2; exit 1; }
# Hide anything that looks like a token or a login URL.
redact() { sed -E 's#force://[^ ]+#[hidden]#g; s#sid=[^ &]+#[hidden]#g; s#https?://[^ ]+#[link hidden]#g'; }

# 1. Tools
command -v sf >/dev/null 2>&1 || die "the Salesforce CLI is not installed. Install it with: npm install -g @salesforce/cli@latest"
command -v node >/dev/null 2>&1 || die "Node is not installed. Install Node 18 or newer, then run this again."
VER="$(sf --version 2>/dev/null | grep -Eo 'cli/[0-9]+\.[0-9]+\.[0-9]+' | head -1 | cut -d/ -f2 || true)"
[ -n "$VER" ] || die "I could not read the Salesforce CLI version. Update it with: npm install -g @salesforce/cli@latest"
MAJOR="${VER%%.*}"; REST="${VER#*.}"; MINOR="${REST%%.*}"
if [ "$MAJOR" -lt 2 ] || { [ "$MAJOR" -eq 2 ] && [ "$MINOR" -lt 149 ]; }; then
  die "your Salesforce CLI is $VER and Curb Cut needs 2.149 or later, because older ones silently drop the agent file. Update it with: npm install -g @salesforce/cli@latest"
fi
say "Salesforce CLI $VER is new enough."

# 2. The org must be logged in and reachable
if ! sf data query --query "SELECT Id FROM Organization LIMIT 1" --target-org "$ALIAS" --json >/dev/null 2>&1; then
  die "I cannot reach the org \"$ALIAS\". Log in with: sf org login web --alias $ALIAS"
fi
say "Org \"$ALIAS\" is reachable."

# Make it yours: a few plain questions, and everything the org can tell us
# filled in for you. No XML to edit. Values already set are kept.
say "Making it yours."
node scripts/configure.mjs "$ALIAS" || die "the setup questions did not finish. Run them on their own with: node scripts/configure.mjs $ALIAS"

# Heads-up only: the agent user must be a real user before you activate.
if grep -rqs "REPLACE-WITH-YOUR" force-app/main/default/aiAuthoringBundles 2>/dev/null; then
  echo "Note: default_agent_user in the two .agent files still holds the placeholder. The deploy will go ahead; set it to a real user in your org before you activate the agents."
fi

# 3. Deploy
# Salesforce refuses to overwrite an agent version that is active. On a first
# install there is none, so everything goes. On a second run, or an upgrade,
# the active agents are left alone and everything else is deployed; agents are
# changed through a new version in Agentforce Builder, never by overwriting.
ACTIVE="$(sf data query --query "SELECT COUNT() FROM BotVersion WHERE Status = 'Active' AND BotDefinition.DeveloperName IN ('Curb_Cut','Curb_Cut_Desk')" --target-org "$ALIAS" --json 2>/dev/null | grep -Eo '"totalSize": *[0-9]+' | grep -Eo '[0-9]+$' || echo 0)"
DIRS=(--source-dir force-app)
if [ "${ACTIVE:-0}" -gt 0 ]; then
  DIRS=()
  for d in force-app/main/default/*/; do
    case "$(basename "$d")" in
      aiAuthoringBundles|genAiPlannerBundles|bots|aiEvaluationDefinitions) ;;
      *) DIRS+=(--source-dir "${d%/}") ;;
    esac
  done
  say "Your Curb Cut agents are already active, so their files are left as they are. Change an agent by saving a new version in Agentforce Builder."
fi
say "Deploying. This can take several minutes."
if ! OUT="$(sf project deploy start "${DIRS[@]}" --target-org "$ALIAS" 2>&1)"; then
  echo "$OUT" | redact | tail -n 40
  die "the deploy did not finish. Read the errors above, fix the first one, and run this again. It is safe to repeat."
fi
say "Deploy finished."

# The deploy creates things the labels can now point at, such as the inbound
# email address. Pick them up, and send the labels again only if they changed.
BEFORE="$(cksum force-app/main/default/labels/CustomLabels.labels-meta.xml)"
node scripts/configure.mjs "$ALIAS" --yes >/dev/null 2>&1 || true
if [ "$BEFORE" != "$(cksum force-app/main/default/labels/CustomLabels.labels-meta.xml)" ]; then
  say "Found new addresses in your org; updating the labels."
  sf project deploy start --source-dir force-app/main/default/labels --target-org "$ALIAS" >/dev/null 2>&1 \
    || die "the labels did not deploy. Run: sf project deploy start --source-dir force-app/main/default/labels --target-org $ALIAS"
fi

# 4. Permission set (the running user only, never a guest)
if OUT="$(sf org assign permset --name Curb_Cut_Access --target-org "$ALIAS" 2>&1)"; then
  say "Curb_Cut_Access is assigned to you."
elif echo "$OUT" | grep -qiE "duplicate|already"; then
  say "Curb_Cut_Access was already assigned to you."
else
  echo "$OUT" | redact | tail -n 10
  die "I could not assign Curb_Cut_Access. Assign it in Setup under Permission Sets, then run this again."
fi

# 5. Seed the library, only if it is empty
COUNT="$(sf data query --query "SELECT COUNT() FROM Accommodation_Option__c" --target-org "$ALIAS" --json 2>/dev/null | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).result.totalSize)}catch{console.log("")}})')"
[ -n "$COUNT" ] || die "I could not read the accommodation library. Check that Curb_Cut_Access is assigned to you, then run this again."
if [ "$COUNT" -eq 0 ]; then
  say "Loading the 36 starter accommodations."
  if ! OUT="$(sf data import bulk --sobject Accommodation_Option__c --file accommodation_options_seed.csv --target-org "$ALIAS" --wait 10 2>&1)"; then
    echo "$OUT" | redact | tail -n 15
    die "the starter accommodations did not load. Run this again; nothing was duplicated."
  fi
else
  say "The library already has $COUNT rows, so I left it alone."
fi

# 6. Tests
if [ "$SKIP_TESTS" -eq 1 ]; then
  say "Skipping Apex tests, as you asked."
else
  say "Running Apex tests."
  if ! sf apex run test --target-org "$ALIAS" --test-level RunLocalTests --result-format human --wait 15 2>&1 | redact | tail -n 25; then
    die "the Apex tests did not pass. Read the failures above, then run this again with --skip-tests once you understand them."
  fi
fi

# 7. Per-org HMAC key, if this version of Curb Cut ships the script
if [ -f scripts/apex/generate-key.apex ]; then
  say "Creating this org's signing key."
  if ! sf apex run --file scripts/apex/generate-key.apex --target-org "$ALIAS" >/dev/null 2>&1; then
    die "the signing key script failed. Run it by hand to see why: sf apex run --file scripts/apex/generate-key.apex --target-org $ALIAS"
  fi
else
  say "No signing key script in this version, so I skipped that step."
fi

# 8. Setup check
echo
say "Checking your setup."
set +e
node scripts/check-setup.mjs "$ALIAS"
CHECK=$?
set -e
echo
if [ "$CHECK" -eq 0 ]; then
  echo "Curb Cut is installed and every check passed."
else
  echo "The install finished. The items marked with a cross need a person: see scripts/README.md for the steps in order. Run node scripts/check-setup.mjs $ALIAS after each one."
fi
exit 0
