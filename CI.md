# CI/CD

Three layers, fastest first. Each one exists because something actually broke.

## 1. Invariants — no org, ~1 second, runs on every push and PR

    python3 tests/invariants.py        # 102 checks

Also wired as a pre-commit hook, so a violation never reaches a commit:

    git config core.hooksPath .githooks

| Invariant | The incident behind it |
|---|---|
| No field names a medical concept | The absence is the thesis. CI now enforces what the schema promises. |
| Every field is in the permission set | The agent could not see the grounded library for an afternoon and invented accommodations instead. |
| `viewAllRecords` only on `Accommodation_Option__c` | Fixing that outage by granting read-all everywhere would have exposed every person's data. |
| Lookups resolve inside the package | A dangling `referenceTo` fails the deploy at the worst moment. |
| Validation rules use real picklist values | `ISPICKVAL(..., "Declined")` silently rots if the value is renamed. |
| Every `apex://` target exists | The agent referenced four actions that had no implementation. |
| `start_agent` has an `instructions` block | Without it a bare "yes" fell to `topic_selector` and the request was never created. |
| Seed CSV is LF and matches field API names | CRLF: `LineEnding is invalid on user data`. |
| `sourceApiVersion >= 66.0` | `AiAuthoringBundle` does not exist below it, and the agent is silently dropped. |

Prove they bite before trusting them:

    # add a field named Diagnosis__c, then:
    python3 tests/invariants.py        # -> FAIL no-diagnosis-field

## 2. Org checks — every push to main and every internal PR

Deploy **dry-run only** (CI never mutates the org), all 24 Apex tests with
coverage, and `sf agent validate` — which compiles the Agent Script server-side.
There is no offline compiler, so this is the only syntax gate that exists.

Skips itself cleanly when `SFDX_AUTH_URL` is absent, so forks still get a
meaningful green run.

## 3. Adversarial suite — opt-in

Actions → CI → Run workflow → tick **run_adversarial**. Talks to the live agent
through the Agent API and costs real calls, so it is never automatic.
Transcripts upload as an artifact and are kept 30 days.

## Setting the secret

    sf org auth show-sfdx-auth-url --target-org curbcut --no-prompt --json \
      | python3 -c "import json,sys,subprocess; u=json.load(sys.stdin)['result']['sfdxAuthUrl']; \
        subprocess.run(['pbcopy'],input=u.encode()); print('copied,',len(u),'chars, starts',u[:8])"

Copies to the clipboard and prints only a shape check, never the value itself.
You should see `starts force://` and roughly 145 characters.

Paste into **Settings → Secrets and variables → Actions → New repository secret**,
named `SFDX_AUTH_URL`. Then clear the clipboard: `printf '' | pbcopy`

`sf org display --verbose` does **not** work for this. Newer CLI versions redact
the URL and return the literal text `[REDACTED] Use 'sf org auth
show-sfdx-auth-url' to view`, which saves cleanly as a secret and then fails
authentication with no obvious cause.

That URL is a credential. Put it in the secret store, never in a file, never in
a commit, never in chat.

## What is deliberately not automated

Publishing. `sf agent publish` returns 404 on this org's authoring endpoint and
falls back to an unreachable host, so activation is a human step in Agentforce
Builder. When you commit a version there, the dialog defaults to **New User** —
choosing it creates an agent user with no permission set, and every action then
fails silently while the agent keeps talking. Always pick **Select User**.
