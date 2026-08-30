#!/bin/bash
# Version-agnostic: finds the newest published planner and reports what is live.
cd "$(dirname "$0")/.."
P=$(sf org list metadata --metadata-type GenAiPlannerBundle --target-org curbcut 2>/dev/null \
    | grep -oE 'Curb_Cut_v[0-9]+' | sort -t v -k2 -n | tail -1)
echo "newest published planner: ${P:-NONE FOUND}"
[ -z "$P" ] && exit 1
rm -rf .check
sf project retrieve start --metadata "GenAiPlannerBundle:$P" --target-org curbcut --output-dir .check >/dev/null 2>&1
python3 - "$P" <<'PY'
import base64,re,sys
p=sys.argv[1]
live=base64.b64decode(open(f'.check/genAiPlannerBundles/{p}/agentScript/{p}_definition.agent','rb').read()).decode('utf-8','replace')
src=open('force-app/main/default/aiAuthoringBundles/Curb_Cut/Curb_Cut.agent').read()
lt=sorted(set(re.findall(r'apex://[A-Za-z]+',live))); st=sorted(set(re.findall(r'apex://[A-Za-z]+',src)))
print(f"live actions   : {len(lt)}  (source has {len(st)})")
miss=[x for x in st if x not in lt]
print("missing        :", miss or "none")
# the routing fix is only live once the widened descriptions are present
print("routing fix live:", "YES" if "Any reply that follows a draft belongs here" in live else "NO - republish needed")
PY
rm -rf .check
