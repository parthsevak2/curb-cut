# Curb Cut

Curb Cut lets any worker ask for a workplace accommodation in their own words,
on the web with no login, by text or a call from a basic phone, by email, in a
Slack DM, or through their own assistant, without ever disclosing a diagnosis.
An Agentforce agent holds the conversation; deterministic Apex decides what is
stored and sent; a person on the access desk answers. First place, Builder
Track, Agentforce for Good Hackathon, Dreamforce 2026.

```
git clone https://github.com/parthsevak2/curb-cut
cd curb-cut
python3 tests/invariants.py     # 521 structural checks, offline, about a second
```

**Feel it before you read anything:** type one sentence at
[parthsevak2.github.io/curb-cut/try.html](https://parthsevak2.github.io/curb-cut/try.html)
and watch the product's own ranking answer, entirely in your browser. The
landing page with the films is
[parthsevak2.github.io/curb-cut](https://parthsevak2.github.io/curb-cut/), and
a print-ready break-room poster is
[poster.html](https://parthsevak2.github.io/curb-cut/poster.html).

To install it into your own Salesforce org, follow [DEPLOY.md](DEPLOY.md).
It needs Agentforce enabled; text and voice also need your own Twilio number
and a small relay ([channels/](channels/)), and Slack needs the app created in
your workspace from the manifest. Four Custom Labels carry your deployment's
number, site URL and support address.

## Why it exists

**The process for requesting a disability accommodation is itself an accessibility barrier.**

To get help you must first navigate a system designed by and for people without
your disability. Find the policy. Learn its vocabulary. Hold a corporate login.
Complete a form. And disclose something you may be afraid to disclose, to a
stranger, in writing, in a language that may not be your first.

Cost usually isn't the barrier.

The film, 4 minutes 59 seconds, with every channel shown live: <https://youtu.be/yleHLiwWRKA>. A 26-second recording of trying the ask page: <https://drive.google.com/file/d/13NApu8rq3MpJjuGG2yzKuJ2P02tKWwGx/view>. A three-minute cut: <https://drive.google.com/file/d/1Loqum6Kbk1noQazJDKrrVEnHzoU3biMD/view>

| Evidence | Source |
|---|---|
| Across **655** large employers in 2025 the median share of staff who told their employer about a disability was **3.5%**, and it did not rise. By 2026, **98%** of them report accommodation programmes. | [Disability:IN 2025 Disability Index](https://disabilityin.org/resource/2025-disability-index-report/) and [2026 results](https://www.disabilityin.org/articles-and-updates/2026-disability-index-results-and-insights) |
| In 2025, **22.8%** of Americans with a disability were employed against 65.2% without, and **30%** of those working were part time against 17%. | [US BLS, People with a Disability 2025](https://www.bls.gov/news.release/disabl.nr0.htm), released 3 March 2026 |
| **61 of every 100** accommodations cost the employer nothing. Median one-time cost of the rest: **$300**. | [JAN employer survey](https://askjan.org/topics/costs.cfm), 5,406 employers, Jan 2019 to Dec 2024 |
| **More than a third** of employed Canadians with a disability had an accommodation need **go unmet** in 2022. | [Statistics Canada](https://www.statcan.gc.ca/o1/en/plus/7142-more-canadians-disabilities-workforce-unmet-accommodation-needs-among-barriers-equity), Canadian Survey on Disability |
| The **GC Workplace Accessibility Passport** already implements "ask once, not forever", and only for federal public servants. | [Government of Canada](https://www.canada.ca/en/government/publicservice/wellness-inclusion-diversity-public-service/diversity-inclusion-public-service/accessibility-public-service/government-canada-workplace-accessibility-passport.html) |

Curb Cut is an Agentforce agent whose principal is **the worker, not the employer**.

---

## The demo deployment, September 2026

The hackathon deployment below is kept as a record of what judges tested. The
demo org and its number retire with the hackathon; your install has its own
addresses on every row.

| Surface | Address | State |
|---|---|---|
| Web | https://orgfarm-e0d3137fa0-dev-ed.develop.my.salesforce-sites.com/curbcut | live |
| Ask (the whole flow, no phone) | `/curbcut/ask` | live |
| Privacy | `/curbcut/privacy` | live |
| Terms | `/curbcut/terms` | live |
| SMS | a Twilio number the deployment owns | live, through a relay we run beside the org |
| Voice | the same Twilio number | built, speech in and out |
| Email | inbound service `CurbCutInbound`, address in Setup → Email Services | live |
| Slack | `node channels/slack-app.mjs`, Socket Mode, DM only, never sends | live in a real workspace; manifest in `channels/slack-manifest.json` |
| Agent | `Curb_Cut` v7, `Curb_Cut_Desk` v5 | both active |
| Console (internal) | `/lightning/app/Curb_Cut_Console`, home tab `/lightning/n/Curb_Cut_Home`, org login needed | live |
| Why now | `/curbcut/why` | live |
| Messaging programme | `/curbcut/messaging` | live |
| MCP server | `node channels/mcp-server.mjs` | 4 tools, none of which can send |
| Any relay or assistant | `POST /services/apexrest/curbcut/v1/message/` | one door every channel above shares |

The console is the half of this that nobody demos. Every promise the assistant
makes about a person reaching a human being is worthless unless a human being
has somewhere to stand. `Human_Handoff__c` was creating records that said
"a person is picking this up" with no surface for that person.

| Console surface | What it is for |
|---|---|
| **On Duty** (app home) | Three queues in the order they should be worked, with standing orders above them |
| Waiting for a person | Someone asked for a human and is currently getting silence |
| Awaiting a decision | Approved requests an employer has not answered, nearest deadline first |
| Needs an interpreter | Signed video, waiting on a person, never machine translated |
| Curb Cut Overview (dashboard) | Where the system is failing people, in five panels |
| Record feeds | Two people often work one request, so the conversation lives on the record |

Nothing in the console shows a diagnosis, because there is no field for one.
An operator who is asked what a person has can only answer that nobody knows
and nobody can find out.

## The four principles

1. **The agent's principal is the worker.** Nothing leaves that the person did not personally approve.
2. **No channel is the real one.** Text, voice, email and web are equal front doors.
3. **Ask before you disclose.** A real answer without identifying yourself or naming anything about your body.
4. **Ask once, not forever.** Standing preferences travel ahead of you.

## What is deliberately not built

- **No automated sign language.** ASL is a complete language; recognition is unsolved. Signed video routes to a human, with immediate text acknowledgement so nobody waits in silence.
- **No diagnosis field.** It isn't encrypted or restricted. It's absent. CI fails the build if anyone adds one.
- **No phone fallback, ever.** `Reachable_By__c` accepts a message channel or email, and the code refuses a telephone number.
- **No inference.** Nothing is profiled or predicted. Every signal is one the person set.

## Verification

Nothing below is asserted from memory. Each number is the output of the command
beside it, and `tests/sync_counts.py` rewrites the published counts from the
invariant suite's own output so they cannot drift.

```
129 Apex tests                 sf apex run test -o curbcut -l RunLocalTests
521 structural invariants      python3 tests/invariants.py            ~1s, no org
517 accessibility checks       python3 tests/a11y_audit.py            against the live pages
122 Sa11y checks               npm run test:a11y                      Salesforce's own axe-core matcher
 34 accessibility-tree checks  node tests/ax_tree_audit.mjs           what a screen reader is handed
 34 controls by keyboard       node tests/keyboard_walk.mjs           real Tab presses; set CURB_CUT_SITE
 21 responsible-AI checks      python3 tests/rai_self_check.py        against Salesforce's five guidelines
 28 contrast checks            python3 tests/contrast_audit.py        both themes, from the tokens
 16 reading-level checks       python3 tests/reading_level_audit.py
 76 link and copy checks       python3 tests/link_and_copy_audit.py
23/23 adversarial assertions   node tests/headless_agent_api.mjs && python3 tests/score_adversarial.py
```

Two of those suites break their own checks on purpose and assert each one goes
red (`--selftest`). A suite that cannot fail proves nothing about the code it
passes. The adversarial suite once scored 21 of 23, and both failures were
published with their transcripts rather than averaged away; the agent's
refusal wording and the scorer have since converged, and the suite passes
whole. The habit stands: a miss gets reported, never smoothed.

## Repository map

| Path | What |
|---|---|
| `force-app/main/default/objects/` | 9 objects, 61 fields, 31 list views, and no field for a diagnosis |
| `force-app/main/default/classes/` | 19 Apex classes + 15 test classes |
| `force-app/main/default/lwc/` | 5 Lightning Web Components, each with a Sa11y suite beside it |
| `force-app/main/default/aiAuthoringBundles/` | two Agent Scripts: `Curb_Cut` public, `Curb_Cut_Desk` internal |
| `force-app/main/default/pages/` `components/` `sites/` | the public site, six pages, anonymous |
| `force-app/main/default/emailservices/` | inbound email channel |
| `force-app/main/default/applications/` `tabs/` `flexipages/` | the internal console |
| `force-app/main/default/reports/` `dashboards/` | five reports and the overview dashboard, no names anywhere |
| `channels/` | SMS + voice relay, Slack app (Socket Mode), MCP server, Twilio configuration |
| `tests/` | the twelve suites above, plus `screen_reader_walk.mjs`, which writes docs/SCREEN-READER-WALK.md |
| `deck/` | the deck as source; the built copy lives in `docs/hackathon/` |
| `docs/hackathon/` | the September 2026 hackathon record: judge guides, reflections, deck, stills |
| `legal/` | privacy and terms source |
| `docs/` | architecture, BRD, evidence, audience, decisions, the two audit reports |

Start with [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), then
[`CRITIQUE.md`](CRITIQUE.md), which is where the honest list of what is still
weak lives.

## Documentation

| Document | Purpose |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | How it fits together, with diagrams |
| [`docs/BRD.md`](docs/BRD.md) | Business requirements and traceability |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | What is next, and what was rejected |
| [`docs/DECISIONS.md`](docs/DECISIONS.md) | Every significant call and why |
| [`docs/EVIDENCE.md`](docs/EVIDENCE.md) | Every public figure, with source, denominator and caveat |
| [`docs/AGENT-INTERFACES.md`](docs/AGENT-INTERFACES.md) | Headless, MCP, agent-to-agent, and the profile we will not build |
| [`CRITIQUE.md`](CRITIQUE.md) | What is still wrong |
| [`FINDINGS.md`](FINDINGS.md) | Adversarial run results |
| [`CI.md`](CI.md) | Pipeline and invariants |
| [`DEPLOY.md`](DEPLOY.md) | Deployment |

---

Built by Parth Sevak. Welland, Ontario, Canada.
Agentforce for Good, Dreamforce 2026 · Builder Track · Abilityforce.

## License

Apache 2.0. The accommodation library ships in the repo with a source citation
on every row. Use it, fork it, run it in your own org.
