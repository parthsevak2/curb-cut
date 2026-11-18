# Install scripts

Three small scripts that take the typing out of [DEPLOY.md](../DEPLOY.md).

## configure.mjs

    node scripts/configure.mjs <org-alias>            # asks only what it cannot find out
    node scripts/configure.mjs <org-alias> --dry-run  # shows what it would write

Makes Curb Cut yours without editing XML. It reads your org (queries only) to
find your organisation's name, your site's address, the inbound email address
Salesforce generated and your agent user, asks plain questions for the rest,
and writes the answers into your checkout: the six labels and the agent user.
Text and voice stay off unless you give a number from your own Twilio account.
Run it again any time; values already set are kept. Without a terminal it
takes `CURB_CUT_OPERATOR`, `CURB_CUT_SUPPORT_EMAIL`, `CURB_CUT_SMS_NUMBER` and
`CURB_CUT_AGENT_USER` from the environment.

Your values belong in your copy only: the invariant suite fails a commit that
carries them, so one organisation's addresses can never end up on everybody's
site.

## install.sh

    bash scripts/install.sh <org-alias> [--skip-tests]

It checks your Salesforce CLI is 2.149 or later and that the org alias is
logged in, runs `configure.mjs`, then deploys `force-app` (leaving active
agents alone on a re-run), assigns `Curb_Cut_Access` to you, loads
the 36 starter accommodations (only if the library is empty, so it never
duplicates rows), runs the Apex tests, creates the org's signing key when
`scripts/apex/generate-key.apex` exists, and finishes with the setup check.

It is safe to run twice. Every failure says in one sentence what to do next.
It never prints tokens or login links.

## check-setup.mjs

    node scripts/check-setup.mjs <org-alias>

Read-only. It needs Node 18 or newer and the Salesforce CLI, nothing else. It
prints one line per check, a tick or a cross, and the exact next step for each
cross. It exits non-zero if anything required is missing. It checks the CLI
version, the org, the objects, the 36 library rows, your permission set, both
agents and their active versions, the site and its guest permissions, the six
labels (and whether text, voice and email are switched on), the email service, and the signing key when the repo has one.

Text, voice and Slack are reported as optional. The labels for the text number
are optional until you add texting.

## What no script can do

These need a person, in this order. The check tells you which are still open.

1. Log in: `sf org login web --alias <org-alias>`.
2. Turn on Einstein and accept the Einstein Bots terms in Setup. This cannot be
   checked from the CLI. If activating an agent fails with `fetch failed`, this
   is why.
3. Put your own values in the labels file
   (`force-app/main/default/labels/CustomLabels.labels-meta.xml`), the
   `errorRoutingAddress` in the email service file, and a real
   `default_agent_user` in both `.agent` files. Then run the install.
4. Create the Force.com Site in Setup, with home page `CurbCutHome`, and give
   its guest user `Curb_Cut_Guest` (never `Curb_Cut_Access`). Put its URL in the
   `CurbCut_Site_URL` label and deploy the labels again.
5. Activate both agents in Agentforce Builder: **Curb Cut** and **Curb Cut Desk**.
6. Turn on Agentforce Session Tracing, publish the email address Salesforce
   generates for `CurbCutInbound`, and assign the console app to whoever
   answers.

## How long it takes

DEPLOY.md gives no time, so neither do we. The deploy and the tests are the
slow, hands-off part and depend on your org. The human-only steps depend on how
quickly your admin can reach Setup and your Einstein terms. Run the check after
each step and it will tell you what is left.
