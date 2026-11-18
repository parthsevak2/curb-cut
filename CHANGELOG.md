# Changelog

What changed, by date. The git history has every step; this is the shape of it.

## Unreleased

- **The docs say what the code does.** The roadmap's Shipped list now carries
  what had shipped while it still read as "next": explain-once on the web, photo
  and signed-video intake, the web ledger, NOMINATE, the reading-level gate, and
  the MCP server's five tools. Every "next" item names its gap in the code.
- **Every published count checks itself.** `tests/count_claims.py` is the one
  list of every place the invariant count is quoted; the suite fails the build
  if any is stale and `tests/sync_counts.py` fixes them all in one step.
- **The deploy guide gives the public guest user `Curb_Cut_Guest`**, read and
  create only, instead of the full access set. An invariant now holds that line.
- `KNOWN-ISSUES.md` opens with what is open today; the August record follows it
  as history. `CRITIQUE.md` and `FINDINGS.md` say plainly that they are dated.
- `channels/README.md`: every door's relay, what it needs, and how to run it.
- **Delivery receipts.** Each text asks Twilio for the carrier's outcome; a
  signed callback writes `Delivered` or `Undelivered` to the ledger, and the
  console's views and report treat a delivered message as one that arrived.
- **Codes under the org's own key.** Claim codes, return codes and ledger
  handles are HMAC-SHA256 under a per-org key in a protected setting granted
  nowhere; codes issued before the key still work. The salts are out of source.
- **Uploads checked for what they are**: real photo and video headers only,
  matching the kind chosen, five per request.
- **One command to install** (`scripts/install.sh`) and **a setup check**
  (`scripts/check-setup.mjs`) that names, in plain words, anything left to do.
  A re-run leaves active agents alone.
- **The whole adversarial suite in the org.** The evaluation grew from ten
  cases to sixteen, covering every conversation the headless harness drives,
  and now names its agent version the way Salesforce expects (`v1`), so it
  deploys.
- The README's live deployment table is checked against the org and the public
  site, and the audits default to the live address.
- **Return codes keep their promise.** "Send it here, by text, or by email, and
  you land straight back with the same person" was told to people for weeks
  while nothing looked a code up. Every door now tries a code first, takes the
  person back to the same handoff, tells the handler they came back, and works
  for codes issued before and after the org's key.
- **What someone said reaches the person picking them up.** A handoff used to
  accept what was hard and then drop it. The words now go through the same
  intake as everything else, condition removed, and the handoff links to them,
  including when an AI assistant hands somebody over.
- **A door is only offered once it exists.** The site and every reply offer
  texting, calling and email only once the deployment has its own number and
  inbound address. The showcase stops pointing people at a retired hackathon
  number, and a fresh install never shows a placeholder.
- **The relays key every handle.** The text, voice and Slack relays hash phone
  numbers and Slack ids with HMAC-SHA256 under the deployment's own secret, and
  refuse to start without one; each used to fall back to a salt written in this
  public repository. Handles change once, so a person may see the one-time
  disclosure again.
- `docs/ARCHITECTURE.md` shows every door, including Slack, the MCP server and
  the shared REST door.
- **Set it up by asking.** A Claude Code plugin (`plugins/curb-cut`) carries a
  setup skill in Salesforce's own skill format and the MCP server. Say "set up
  Curb Cut in my org" and it runs the install, asking only what the org cannot
  answer. The roadmap gains three directions from what Salesforce shipped this
  autumn: Curb Cut's manners as AI Skills, Canadian French through Agentforce
  Voice, and requests that cannot die in an inbox.
- **Six labels, set by answering questions.** `scripts/configure.mjs` reads the
  org for the site address, the inbound email address and the agent user, asks
  for the rest, and writes the labels; the install runs it. The site's email
  link and the operator's name used to be hard-coded to one deployment.

## October 2026

- The MCP server answers `initialize`, `tools/list`, the cost brief and the
  draft before it has an org, and opens the org connection only when a tool
  needs one. Package `curb-cut-mcp` 1.0.1.
- The try page keeps its promise to the letter: nothing typed leaves the page,
  and an invariant fails the build if a network call or an online voice appears.

## September 2026

- **First place, Builder Track, Agentforce for Good Hackathon, Dreamforce 2026.**
- Text messaging live with the compliance layer (disclosure, HELP, STOP, START);
  voice with speech in and out; Slack live in a real workspace.
- Standing preferences shown only to the audience the person chose, with every
  showing recorded; the web trail and revocation gated on the claim code, never
  a record Id; the voice and SMS webhooks fail closed.
- Relicensed from MIT to Apache 2.0. Deployment identity moved into four Custom
  Labels. A repository a stranger can adopt: deploy guide, security policy,
  contributing guide, code of conduct, issue templates.
- Curb Cut moved from the hackathon org into an org of its own. The hackathon
  record moved to `docs/hackathon/`, dated.
- The landing page, the try page (the product's ranking, running entirely in the
  visitor's browser), the break-room poster, and the story.
- NOMINATE on every door. The MCP server published to npm and listed in the
  official MCP Registry.

## August 2026

- The first build: an Agentforce agent whose principal is the worker, the
  grounded and cited accommodation library, and no field for a diagnosis.
- Doors: web with no login, SMS, voice, email. The delivery ledger, the console
  for the person answering, the internal Desk agent, the emergency exception.
- Image and signed-video intake with an interpreter queue.
- Every incident encoded as an invariant that fails the build; accessibility,
  reading-level and adversarial suites.
