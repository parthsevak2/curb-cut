# Publishing an agent when `sf agent publish` will not

`sf agent publish` does not work against this org, and the failure is misleading.
This is what it actually does and what to do instead.

## What the failure is

Traced with an undici diagnostics-channel hook:

```
POST https://api.salesforce.com/einstein/ai-agent/v1.1/authoring/scripts        200
POST https://api.salesforce.com/einstein/ai-agent/v1.1/authoring/agents/{id}/versions  401
POST https://api.salesforce.com/einstein/ai-agent/v1.1/authoring/agents/{id}/versions  404
POST https://test.api.salesforce.com/einstein/ai-agent/.../versions            connect timeout
```

The script compiles fine (200). The agent has no authoring record, so creating a
version is refused (401, then 404). The library then falls back to the sandbox
host `test.api.salesforce.com`, which resolves to AWS addresses that do not
answer from here, and the 10-second connect timeout is the only thing the user
ever sees.

So the reported error &mdash; a network timeout &mdash; is a symptom of the
fallback, not the cause. `api.salesforce.com` itself is reachable and returns in
about 100ms.

## What works instead

The published planner is ordinary metadata. Deploy a new version by hand:

```bash
# 1. Retrieve the live planner
sf project retrieve start -o curbcut -m "GenAiPlannerBundle:Curb_Cut_v6" \
  --target-metadata-dir /tmp/planner && (cd /tmp/planner && unzip -q unpackaged.zip)

# 2. Copy it to the next version number and rename every internal reference
#    (file names, directory names, and the text inside them)

# 3. Every developerName carrying an org-generated suffix must be made unique or
#    the deploy fails with "duplicate value found". Suffix them all consistently.

# 4. Deploy the planner
sf project deploy start -o curbcut --metadata-dir /tmp/v7

# 5. Add a matching <botVersions> entry to the Bot, pointing at the new planner,
#    with fresh UUIDs for every messageIdentifier and stepIdentifier

# 6. An active version cannot be edited, so:
sf agent deactivate -o curbcut --api-name Curb_Cut
sf project deploy start -o curbcut --metadata-dir /tmp/botv7
sf agent activate   -o curbcut --api-name Curb_Cut --version 7
```

`sf agent activate` prompts interactively without `--version`; passing the number
explicitly is what makes it scriptable. **Always pass `--version`** &mdash; a
cancelled prompt leaves the agent with no active version at all.

## The trap

The instruction text exists in two places inside the bundle:

- `Curb_Cut_vN.genAiPlannerBundle` &mdash; XML, `genAiPluginInstructions`
- `agentScript/Curb_Cut_vN_definition.agent` &mdash; **base64**

Patching only the XML changes nothing observable. A blanket `sed` across the
bundle silently corrupts the base64 blob instead of editing it. Decode it,
replace the text, re-encode:

```python
import base64
p = 'agentScript/Curb_Cut_v7_definition.agent'
t = base64.b64decode(open(p,'rb').read()).decode('utf-8')
t = t.replace(OLD, NEW)
open(p,'wb').write(base64.b64encode(t.encode('utf-8')))
```

Verify by decoding what the org gives back, and confirm `apex://` still appears
seven times &mdash; if it appears zero times, the blob was corrupted and every
action binding is gone.

## Verify behaviour, not metadata

Retrieved metadata was misleading here in both directions. The only reliable
check is to ask the running agent:

```bash
node tests/headless_agent_api.mjs && python3 tests/score_adversarial.py
```

Run it more than once. Two assertions move between runs on identical builds.
