---
name: curb-cut-org-setup
description: "Use to INSTALL, CONFIGURE or CHECK Curb Cut, the open-source accommodation-request app, in a Salesforce org with Agentforce. It runs the repository's own scripts: it asks the person only what the org cannot answer, deploys, loads the library, creates the org's signing key, and reports what is left in plain words. Trigger: 'set up Curb Cut', 'install Curb Cut in my org', 'configure Curb Cut', 'is Curb Cut set up', 'check my Curb Cut org'. Do NOT use to change an agent that is already active (save a new version in Agentforce Builder), to connect a Twilio relay (DEPLOY.md step 7 has the steps), or for Salesforce deploys unrelated to Curb Cut."
metadata:
  version: "1.0"
  domains: ["Agentforce", "Accessibility"]
  minApiVersion: "66.0"
  relatedSkills:
    - "dx-org-manage"
    - "platform-metadata-deploy"
  cliTools:
    - tool: ["sf"]
      semver: ">=2.149.0"
    - tool: ["node"]
      semver: ">=18.0.0"
---

## MANDATORY: follow these steps in order, and keep the person in the loop

Curb Cut exists so that asking for help at work costs nothing. Setting it up
should feel the same: ask only what you must, say what you are doing in plain
words, and never leave a step half done without saying so.

**Tool constraint:** use the shell for every `sf`, `node` and `bash` command, and
add `--json` to `sf` commands you need to read. Use the repository's scripts;
do not re-create their logic by hand.

**Never:** ask for, type or print a password, token or login URL; give the site
guest user `Curb_Cut_Access` (it gets `Curb_Cut_Guest` only); deploy agent files
over an active agent; commit the configured labels or agent files back to a
public repository (the invariant suite fails if you do); invent an operator
name, mailbox or phone number.

---

## 1. Be in a Curb Cut checkout

Check that the working directory has `sfdx-project.json` and `scripts/install.sh`.
If not, clone it and work from there:

```bash
git clone https://github.com/parthsevak2/curb-cut && cd curb-cut
```

## 2. Be logged in to the org

Ask which org alias to use if the person has not said. Check it:

```bash
sf org display --target-org <alias> --json
```

If it is not connected, run `sf org login web --alias <alias>` and tell the
person to finish signing in in the browser that opens. Wait for them. Do not
handle the login yourself.

If the org is a production org (not a sandbox, scratch or Developer Edition
org), say so and ask for a clear yes before deploying anything.

## 3. Ask only what the org cannot answer

`scripts/configure.mjs` finds the site's address, the inbound email address and
the agent user in the org by itself. Ask the person, in one short message:

1. **Who runs this deployment**, as people and carriers should read it: an
   organisation and where it is. Offer the org's own name as a default.
2. **Which mailbox the access desk reads.** A shared inbox, never one person's
   own. Every reply that cannot reach a person points there.
3. **A text and voice number from their own Twilio account**, if they have one.
   If not, texting and calling simply stay off and the site does not offer them.

Then write the answers into the checkout (nothing in the org changes here):

```bash
CURB_CUT_OPERATOR="<who runs it>" \
CURB_CUT_SUPPORT_EMAIL="<access desk mailbox>" \
CURB_CUT_SMS_NUMBER="<number, or leave this line out>" \
node scripts/configure.mjs <alias> --yes
```

Show the person its summary: what was found, what was set, which doors are on.

## 4. Install

```bash
bash scripts/install.sh <alias>
```

It deploys the web door and both agents (leaving active agents alone on a
re-run), gives the person running it `Curb_Cut_Access`, loads the library only
if it is empty, runs the Apex tests, creates the org's own signing key, and ends
with the setup check. Add `--skip-tests` only if the person asks. If it stops,
read its one-sentence reason to the person and fix that first; it is safe to
run again.

## 5. Finish what only a person can do

Run the check and read every line:

```bash
node scripts/check-setup.mjs <alias>
```

For each ✗, tell the person the exact next step it prints. Three steps need a
person in Setup, and the check names whichever are left:

- **Einstein Bots terms:** Setup → Einstein Bots → accept.
- **The site:** Setup → Sites → New, home page `CurbCutHome`, and the guest user
  gets the `Curb_Cut_Guest` permission set (never `Curb_Cut_Access`).
- **The agents:** Setup → Agentforce Builder → open Curb Cut, save a version,
  activate it as the agent user. Then the same for Curb Cut Desk.

After the person has done them, pick up what the org now knows (the site's
address, the inbound email address) and send the labels again:

```bash
node scripts/configure.mjs <alias> --yes
sf project deploy start --source-dir force-app/main/default/labels --target-org <alias>
node scripts/check-setup.mjs <alias>
```

## 6. Done

Setup is done when the check prints **"Everything required is in place."**
Tell the person, in plain words: the site's address, which doors are on (web,
email, text and voice), that the access desk works from the Curb Cut console,
and where to read more (`DEPLOY.md`, `docs/ROADMAP.md`). Optional doors the
check marks ○ (the Twilio relay, Slack) are theirs to add later.
