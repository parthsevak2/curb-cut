# Roadmap

Ordered by how many people it reaches per unit of work, not by how impressive it
sounds. Everything in "Shipped" is in this repository and held by the checks in the
README's Verification block; everything below it names the gap in the code.

## Shipped

| | Reaches |
|---|---|
| **Web front door**. The whole ask, start to finish, no phone, no account | Anyone with a browser: library computer, shared desktop, screen reader |
| **SMS**. Each deployment registers its own number with the carriers before it sends | Anyone with a basic phone and no smartphone, no data, no app |
| **Voice, speech in and out** | Motor disability, dyslexia, low literacy, blindness. Anyone for whom speaking beats typing |
| **Email** | No mobile plan; a shared phone; needing to compose slowly over days |
| **Grounded library, 36 rows, every row cited** | Everyone. It is what stops the system inventing entitlements |
| **Disclosure ledger** | Anyone whose preference travels ahead of them into a new team |
| **Explain once, on the web**. Save a preference, see who saw it, turn it off, with a claim code and no account | The person arriving in a browser, the one this promise used to leave out |
| **Photo and signed-video intake on the web**. A video marks an interpreter as needed and goes to a person; nothing is machine-translated | Anyone for whom a photo of a workstation beats describing a chair; Deaf signers |
| **Every door writes the ledger**, the web included | Anyone asking "did we reach this person" |
| **NOMINATE on every door**. A workplace name and the door it came through, nothing about who sent it | The worker who wants this where they work and would rather not be the one to ask |
| **Why-now argument** (`/curbcut/why`) | The reader who needs to know why this matters in 2026, not in the abstract |
| **Opt-in programme page** (`/curbcut/messaging`) | Carrier reviewers, and anyone deciding whether to trust a number on a poster |
| **Internal console**. On Duty queues, 5 reports, dashboard, record pages | The person answering. The escape hatch used to open onto nothing |
| **MCP server**, 5 tools, none of which can send a request; `npx curb-cut-mcp`, listed in the official MCP Registry | Anyone already inside another assistant, who should not have to come here |
| **Slack DM**, Socket Mode, from the manifest in `channels/` | People who already live in Slack; one fewer context switch on a hard day |
| **Agent-to-agent handover contract** | The person whose request reaches an employer's system rather than a human |
| **SMS compliance layer**. Disclosure, HELP, STOP, START | Everyone on the text channel; it is what makes the opt-in real |
| **Reading-level gate in CI**, per surface: pages, text replies, Apex messages | Everyone. Plain language is checked, not hoped for |
| **Delivered, not only accepted**. The carrier's own answer lands in the ledger beside every text, and the console never counts a delivered message as one that did not arrive | Anyone asking "did it reach them", not only "did we send it" |
| **Codes under the org's own key**. Claim codes, return codes and ledger handles are HMAC-SHA256 under a key unique to each org, with codes already issued still working | Everyone holding a code; an export of the org no longer gives them away |
| **Uploads checked for what they are**. Real photo and video headers only, matching what the person chose, five per request | The person on the other end, who opens what arrives |
| **One-command install and a setup check** (`scripts/`). It asks a few plain questions, finds the rest in the org, and leaves active agents alone on a re-run | The admin installing it, told in plain words what is left |
| **Return codes that bring you back**. On the web, by text or by email, a code takes the person back to the same handler, who is told they came back | The anonymous visitor who was promised they would not have to explain it again |
| **What was hard reaches the handler**, from every door including an AI assistant, with any condition removed first | The person answering, and the person who never has to say it twice |
| **Doors offered only when they exist**. Text, voice and email appear on the site and in replies only once the deployment has its own number and inbound address | Everyone; nobody is pointed at a door that does not answer |
| **The whole adversarial suite, inside the org**. Sixteen evaluation cases cover every conversation the headless harness drives; the build fails if one goes missing | Every adopter, who can re-prove the refusals in their own org |

## Blocked on something outside the code

### Email delivery
Found on the hackathon org in September 2026, and true of any org without a
verified sending domain.

The ledger now proves Salesforce **accepts** every reply, `Email / Outbound /
Accepted`, no error text. It never arrives, not even in spam. That places the
loss downstream of Salesforce, and there are only two candidates:

1. **No verified sending domain.** There is no `OrgWideEmailAddress`, and the
   run-as user's domain is unverified, so Deliverability substitutes
   `email@<uniqueId>.sfcustomeremail.com`. Some receivers reject that outright
   rather than filing it.
2. **Org deliverability access level.** If it is *System email only*, Apex mail
   is accepted and discarded, which matches the symptom exactly.

**The fix is a verified sending domain with DKIM records**, which each deployment brings.
Until then the escalation path carries the load: an undeliverable reply becomes
a `Human_Handoff__c` rather than silence.

**Until a deployment has that domain, do not promise email replies.** Receiving
and logging work; the reply leg depends on the domain.

## Next

Each item names what is missing in the code today, so the gap can be checked
rather than taken on trust.

### 1. The hardening still ahead
- The audience on a standing preference ("Manager only", "Meeting hosts") is
  enforced by row-level security, not only honoured on trust and recorded by
  the ledger.
- Handoffs have no closed state, so any return code can resume one however
  old, and nothing yet slows down somebody guessing codes.
- A visitor who opens a new request for every upload is not yet rate-limited,
  and a site-wide cap would hand an attacker a way to shut the door on
  everyone. It needs a better answer than a counter.

### 2. Manager brief as a shareable link
`cost_brief` returns cost, precedent and the interactive-process clock, but only
to an agent or an assistant. A manager should be able to open one page rather
than converse. Refusals still apply.

### 3. Outcome reporting
`Manager_Response__c` and `Decline_Reason__c` exist, and a console queue filters
pending decisions, but nothing yet reports on decided outcomes or reasons.
Precedent counts are the one figure the agent refuses to invent, and they become
real the moment decisions are recorded.

### 4. Reading level for the agent's own words
CI holds pages, text replies and Apex messages to per-surface ceilings. The
agent's instructions and canned messages in `aiAuthoringBundles/` are not yet
read by that gate.

### 5. The same cards in Slackbot, Claude and Agentforce, from the org's own server
Salesforce's Headless Experience Layer (beta, November 2026) renders one widget
in Agentforce, Slackbot, Claude and ChatGPT, served by a custom MCP server the
org itself hosts. That fits this project's trust model exactly: no third party
sits between a worker and their org, which is the reason a Slack Marketplace
listing is rejected below. Three widgets would carry it: the options card (each
option with its cost and source), the draft card (every word, and nothing sent
until the person says yes), and the handoff card for the person answering.
Two properties line up with rules already here. Widget buttons post a message
rather than call Apex, so the explicit yes still happens in the conversation.
And tools are marked `readOnly` or `destructive`, so Slackbot asks before
anything that writes.

The honest limit: Slackbot and Claude reach the org as a signed-in Salesforce
user. That suits the access desk, who are Salesforce users already, and staff
who sign in anyway. Everyone else keeps the doors that need no login at all.

### 6. A React client. A decision, not a task

Asked for repeatedly, and not built. The reasoning is in
[`AGENT-INTERFACES.md`](AGENT-INTERFACES.md): Force.com Sites is the only thing
in this org that serves a page to an anonymous visitor with no login, which is
the entire requirement, and a single-page app would add a build step and a
hosting dependency without changing one thing a person can do.

If it is wanted for the submission rather than for the user, say so and it gets
built as `clients/react/` against the same `@RemoteAction` endpoints. Roughly a
day, honest about being a second front end rather than the front end. That is a
legitimate reason. It is just a different reason, and it should be recorded as
one.

## Requires licensing this org does not have

Stated as roadmap because the metadata is genuinely absent. Verified by query.

| | Why it matters | Blocker |
|---|---|---|
| **Native Slack metadata** | The Slack door already works through the small Node app in `channels/`; native metadata would let an org run it with nothing beside it | No Slack metadata types in this org |
| **Data 360** (formerly Data Cloud) | Unify accommodation signals across HR systems without ever holding a diagnosis. The aggregate is useful precisely because the individual record is empty | Types present, licensing unverified |
| **Tableau / CRM Analytics** | Which teams have the most unmet needs, without naming anyone. Aggregate-only by construction. | Essentially absent |
| **Experience Cloud / LWR** | A component-based site with richer interaction | `Network` and `DigitalExperienceConfig` unavailable |
| **Salesforce Messaging (MIAW)** | Native web chat instead of a relay | Digital Engagement not licensed |

## Deliberately rejected

Not backlog. Decisions.

- **Automated sign language.** ASL is a complete language with grammar in hands, face and body. Recognition is unsolved and the products claiming otherwise mostly fingerspell. A person interprets; technology holds the door.
- **A diagnosis field, even encrypted.** Encryption protects data that exists. The stronger control is not to have it.
- **Any phone fallback.** Not for escalation, not for HR, not for "urgent" cases.
- **Inferring anything from behaviour.** No profiling, no scoring, no prediction. Every signal is one the person set in their own words.
- **A reason field on revocation.** There is nowhere to record why someone turned a preference off, so nobody can ever be asked.

## The one that is not a feature

**An accessibility audit by people who need it.** Every claim about screen
readers, keyboard use and contrast on the site was tested by the person who
wrote it. One session with one worker who uses a screen reader daily would be
worth more than the next five items on this list.

## Distribution

| Channel | State |
|---|---|
| **The try-it page** | Live at [parthsevak2.github.io/curb-cut/try.html](https://parthsevak2.github.io/curb-cut/try.html): the Apex ranking ported line for line, running in the visitor's browser over the same 36-option library, with no server and no network call. Four invariants hold it to the seed data, and it outlives any demo org |
| **The break-room poster** | Live at [poster.html](https://parthsevak2.github.io/curb-cut/poster.html): print-ready, customised entirely from the address bar (`?num=`&`site=`), with a QR code to the try-it page for the curious. The break room is where the people without laptops are |
| **Install from the repo** | Live: deploy the org metadata, create the Slack app from `channels/slack-manifest.json` in your own workspace in about two minutes |
| **Trailblazer Labs, Builder in Residence** | Pitched 17 November 2026: [TrailblazerLabs/Cohort-Applications#8](https://github.com/TrailblazerLabs/Cohort-Applications/discussions/8). Upvotes there are how the community signals demand. The natural home: an open-source asset an org installs into its own Salesforce, so the org owns the deployment |
| **npm and the MCP Registry** | Live: `npx curb-cut-mcp`, listed as `io.github.parthsevak2/curb-cut-mcp`. Any MCP client can look things up and draft; none can send |
| **Slack Marketplace listing** | Deliberately not yet. A listed Slack app must be one hosted service that many workspaces install, which would put a third party between a worker and their org's Salesforce, exactly the trust model this project refuses. If demand appears, the honest shape is an OAuth installer that still points every workspace at that org's own relay, and that is real engineering to do carefully, not a checkbox |

