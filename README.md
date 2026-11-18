<div align="center">

# Curb Cut ✿

<p>
<strong>Ask for what you need at work, in your own words, without ever saying why.</strong>
<br/>
<span>Free and open source, for any workplace. On the other side, a person answers.</span>
</p>

</div>

<p align="center">
<a href="https://github.com/parthsevak2/curb-cut/tree/main/docs/hackathon"><img src="https://img.shields.io/badge/First%20place-Agentforce%20for%20Good%202026-8a5a00" alt="First place, Builder Track, Agentforce for Good Hackathon, Dreamforce 2026" /></a>
<a href="LICENSE"><img src="https://img.shields.io/badge/licence-Apache%202.0-1f5c50" alt="Licence: Apache 2.0" /></a>
<a href="https://www.npmjs.com/package/curb-cut-mcp"><img src="https://img.shields.io/npm/v/curb-cut-mcp?label=npm%20curb-cut-mcp" alt="curb-cut-mcp on npm, current version" /></a>
<a href="docs/ARCHITECTURE.md"><img src="https://img.shields.io/badge/built%20on-Agentforce%20and%20Apex-1f5c50" alt="Built on Agentforce and Apex" /></a>
</p>

<p align="center">
<a href="https://parthsevak2.github.io/curb-cut/try.html"><strong>Feel it in ten seconds</strong></a> ·
<a href="https://github.com/TrailblazerLabs/Cohort-Applications/discussions/8"><strong>Upvote the pitch</strong></a> ·
<a href="https://youtu.be/yleHLiwWRKA"><strong>Watch the film</strong></a> ·
<a href="DEPLOY.md"><strong>Bring it to your org</strong></a> ·
<a href="https://parthsevak2.github.io/curb-cut/story.html"><strong>Read the story</strong></a>
</p>

<p align="center">
<img src="https://parthsevak2.github.io/curb-cut/story/sentence-draft.png" alt="A dark green card. Two drafts are struck out: I'm fine, and Sorry to bother you, but. Below them, in large letters, the sentence that finally gets written: The lights above my desk give me a headache by the afternoon. Under it, in small letters: Twelve words." width="700" />
</p>

A sixty-dollar lamp can end a year of headaches. So why would anyone sit under
lights that hurt for a year?

Because of what the lamp costs to ask for. Saying that sentence to a manager.
Backing it up with proof. Explaining your body to the person who decides your
career. The lamp costs sixty dollars once. The sentence costs courage every
time, and while it stays unsaid, the headache stays too.

Curb Cut is built for that sentence. You say what is hard, in your own words.
It shows you what other people have asked for in situations like yours, with
what each usually costs and a public source on every option. If you want to
ask, it writes the request in your words, shows you every word, and sends
nothing until you clearly say yes. Nobody asks what you have. There is nowhere
to write it down.

> [!TIP]
> **Feel it before you read another line.** Type one sentence on the
> [try page](https://parthsevak2.github.io/curb-cut/try.html) and the product's
> own ranking answers, entirely in your browser. No account, no server, and
> nothing you type leaves the page.

## 💡 The asking is the barrier

The process for requesting a disability accommodation is itself an
accessibility barrier. To get help you must first find the policy, learn its
vocabulary, hold a corporate login, complete a form, and disclose something you
may be afraid to disclose, to a stranger, in writing, in a language that may
not be your first.

Cost usually is not what stands in the way.

| What the numbers say | Source |
|---|---|
| Of the **1,425** employers who gave cost figures, **61 of every 100** accommodations cost them nothing. Median one-time cost of the rest: **$300**. | [JAN employer survey](https://askjan.org/topics/costs.cfm), 5,406 employers responded, Jan 2019 to Dec 2024 |
| Across **655** large employers in 2025 the median share of staff who told their employer about a disability was **3.5%**, and it did not rise. By 2026, **98%** of them report accommodation programmes. | [Disability:IN 2025 Disability Index](https://disabilityin.org/resource/2025-disability-index-report/) and [2026 results](https://www.disabilityin.org/articles-and-updates/2026-disability-index-results-and-insights) |
| In 2025, **22.8%** of Americans with a disability were employed against 65.2% without, and **30%** of those working were part time against 17%. | [US BLS, People with a Disability 2025](https://www.bls.gov/news.release/disabl.nr0.htm), released 3 March 2026 |
| **More than a third** of employed Canadians with a disability had an accommodation need **go unmet** in 2022. | [Statistics Canada](https://www.statcan.gc.ca/o1/en/plus/7142-more-canadians-disabilities-workforce-unmet-accommodation-needs-among-barriers-equity), Canadian Survey on Disability |
| The **GC Workplace Accessibility Passport** already implements "ask once, not forever", and only for federal public servants. | [Government of Canada](https://www.canada.ca/en/government/publicservice/wellness-inclusion-diversity-public-service/diversity-inclusion-public-service/accessibility-public-service/government-canada-workplace-accessibility-passport.html) |

The programmes exist. The help is usually cheap. The sentence still goes
unsaid. Every figure above, with its denominator and its caveat, is in
[docs/EVIDENCE.md](docs/EVIDENCE.md).

## 🚪 Every door ends at a human

<p align="center">
<img src="https://parthsevak2.github.io/curb-cut/story/doors-six.png" alt="Six doors in a row, drawn in white line on dark green and labelled web, a text, a call, email, Slack and human. The last door stands open with warm light pouring out. The caption reads: Say human on any channel and a person picks it up." width="700" />
</p>

The people this serves most often have no company login at all: the crew in
the field, the cleaner on the early shift, the contractor on the road. So no
door is the real one. The web door needs no login, no account and no name.
A text or a call works from the most basic phone there is, and the number can
live on a poster in the break room. There is an email door, a Slack DM that
starts by telling the truth about what workspace owners can export, and a set
of tools for the AI assistant a person already uses.

| What makes asking hard | What Curb Cut does about it |
|---|---|
| You are afraid of what you would have to disclose | There is no diagnosis field. It is not hidden or encrypted. It is absent, and the build fails if one ever appears. You say what is hard, never why. |
| You do not know what is normal to ask for | Every option comes from a small public library, with its usual cost and a source. When nothing matches, it says so instead of guessing. |
| You worry something will be sent before you are ready | The draft appears in full, in your words. Nothing sends without a clear yes, and a hedge is not a yes. |
| A phone ringing at the wrong moment could expose you | The phone line answers when you call and never calls back. |
| You have no login, or no computer | Web with no login, a text, a call, email, a Slack DM, or your own assistant. All of them are equal. |
| You would rather talk to a person | Say **human** on any door and a person picks it up, from a queue ordered by who has waited longest. |

![The try page answering the sentence about the lights. Under the heading What others have asked for, four options appear: adjustable or task lighting, usually about 60 dollars; turning off fluorescent lights nearby, usually no cost to the employer; moving away from overhead fluorescent lighting, usually no cost; and a step-free route from the door to your desk. Each one carries a link to its source, the Job Accommodation Network. A note below says the page stops before sending on purpose.](https://parthsevak2.github.io/curb-cut/story/options-with-sources.png)

If you want to feel why the phone door matters, imagine your glasses broke at
lunch. By two o'clock the spreadsheet is fog and every email is a guess. Then
you go looking for help, and the form that could help is on the screen you
cannot read. For millions of people it is like this every day. So Curb Cut
answers a phone, and the fog stops mattering.

<details>
<summary>Watch a page turn to fog (a short looping animation, kept closed for anyone who prefers no motion)</summary>

![A short animation. The Curb Cut ask page, with the heading Tell me what's hard right now, slowly blurs until none of it can be read, the way a page looks to someone whose glasses have just broken.](https://parthsevak2.github.io/curb-cut/story/fog-motion.gif)

</details>

### How it is put together

An Agentforce agent, written in Agent Script, holds the conversation, because
conversation is what a language model is good at. Deterministic Apex decides
what is stored and what is sent, so none of the promises above depend on a
model's mood. Curb Cut runs inside the employer's own Salesforce org, and its
principal is still **the worker, not the employer**.

The four principles it is built on:

1. **The agent's principal is the worker.** Nothing leaves that the person did not personally approve.
2. **No channel is the real one.** Text, voice, email and web are equal front doors.
3. **Ask before you disclose.** A real answer without identifying yourself or naming anything about your body.
4. **Ask once, not forever.** Standing preferences travel ahead of you.

[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) shows how it fits together, with
diagrams, and [docs/CHANNELS.md](docs/CHANNELS.md) says what each door can and
cannot do.

## 🏆 It is real, and it is checked

Curb Cut won **first place in the Builder Track of the Agentforce for Good
Hackathon at Dreamforce 2026**, among 43 projects from 11 countries. The
judges also said it was hard to tell what was live product and what was
presentation. That criticism was a gift. Every film now marks real footage
LIVE and anything staged CONTEXT, and the
[try page](https://parthsevak2.github.io/curb-cut/try.html) exists so that you
do not have to trust footage at all.

**The film** is 4 minutes 59 seconds, captioned, with every door shown live:
[watch it on YouTube](https://youtu.be/yleHLiwWRKA).

The promises are kept by the build, not by good intentions. You can check the
first of them yourself in about a second, with no Salesforce org:

```
git clone https://github.com/parthsevak2/curb-cut
cd curb-cut
python3 tests/invariants.py     # 627 structural checks, offline, about a second
```

Those are the 627 structural invariants, the rules the build refuses to break.
The rest of the checking, today:

| What is checked | Count today |
|---|---|
| Apex tests | 194 |
| Accessibility checks against the live pages | 509 |
| Sa11y tests, accessibility-tree checks, and controls walked by keyboard | 19, 34 and 34 |
| Contrast, reading-level, and link and copy checks | 28, 17 and 71 |
| Responsible-AI checks | 21, of which 18 pass and 3 are honestly undecided |
| Adversarial assertions, across 11 conversations | 23 of 23 |
| Agentforce evaluation in the org | 16 cases |

The adversarial conversations include a vague answer that must not be taken
for a yes, a prompt injection, a manager demanding a roster, and a diagnosis
volunteered mid-chat that the system must decline to keep. The commands behind
every number are under [Verification](#verification) below.

## 🤝 Who it is for

**If you are a worker.** You do not need a login, a name or a reason. One
sentence about what is hard is enough. You see what others have asked for, you
read every word of your request before it goes anywhere, and you can say
**human** at any point.

**If you answer on the access desk.** Every promise about reaching a person is
worthless unless that person has somewhere to stand. The console gives you
three queues in the order they should be worked: who is waiting for a person,
which requests are awaiting a decision, and who needs an interpreter. Nothing
in it shows a diagnosis, because there is no field for one.

**If you run an organisation.** Curb Cut installs into the Salesforce org you
already have, so everything it stores stays under your own roof. The code is
free under Apache 2.0. What it truly needs is one person willing to be on the
other end.

**If you are a nonprofit.** Under the workplace words, Curb Cut is a pattern:
someone says what is hard, from any phone, sees real options with sources,
sends nothing without a clear yes, and always reaches a human. The
accommodation library is one file with a source on every row. Swap it, and the
same machinery could fit a food bank's request line, a shelter's intake, or a
school's door for parents.

## 🏡 Bring it to your org

Once the Salesforce CLI is logged in to your org, one command does the typing.
It asks a few plain questions, finds the rest in the org, and there is no XML
to edit.

```
git clone https://github.com/parthsevak2/curb-cut
cd curb-cut
sf org login web --alias curbcut
bash scripts/install.sh curbcut
```

Then, any time you want to know where you stand, in plain words:

```
node scripts/check-setup.mjs curbcut
```

The check prints a tick or a cross for each item and the exact next step for
every cross. A few steps need a person, and it names them: accepting the
Einstein Bots terms, creating the site, and activating the agents.

> [!NOTE]
> Curb Cut needs a Salesforce org with Agentforce, and Salesforce CLI 2.149 or
> later. The open-source code is free; the platform under it is not. The web
> and email doors need nothing outside Salesforce. Text and voice also need
> your own Twilio number and a small relay ([channels/](channels/)), and Slack
> needs the app created in your workspace from the manifest. Six Custom Labels
> carry your deployment's identity, and `node scripts/configure.mjs` sets them
> for you. Text, voice and email appear on your site only once your deployment
> has connected its own number or address.

The whole guide is one page: [DEPLOY.md](DEPLOY.md). The scripts are described
in [scripts/README.md](scripts/README.md), and a print-ready poster for the
break room is at
[poster.html](https://parthsevak2.github.io/curb-cut/poster.html).

## 🧭 Use it from your AI assistant

Most people who need this are already inside some assistant, so Curb Cut comes
to them. It is an MCP server with five tools, and none of them can send a
request to an employer. A tool that was never given a send button cannot be
talked into pressing one.

```
npx curb-cut-mcp
```

Or add it to your MCP client's configuration:

```json
{
  "mcpServers": {
    "curb-cut": {
      "command": "npx",
      "args": ["-y", "curb-cut-mcp"],
      "env": { "SF_ORG_ALIAS": "curbcut" }
    }
  }
}
```

| Tool | What it does |
|---|---|
| `curbcut_find_options` | Given what a person says is hard, returns adjustments they could ask for, with usual cost and a source. Returns nothing rather than guessing. |
| `curbcut_cost_brief` | Published evidence on what accommodations cost employers, with the survey, the sample and the denominator. |
| `curbcut_draft_request` | Drafts the ask in the person's own words, describing what would help and never why. It cannot send. |
| `curbcut_reach_human` | Hands the person to a named human handler on the channel they are already using. Never routes anyone to a phone call. |
| `curbcut_nominate` | Nominates a workplace that should have Curb Cut. Stores the workplace name and nothing about the person. |

The cost brief and the draft work on their own. The other three read from a
Salesforce org with Curb Cut deployed, through the Salesforce CLI. Details are
in the [MCP server's own README](channels/mcp-npm/README.md) and
[docs/AGENT-INTERFACES.md](docs/AGENT-INTERFACES.md).

## 🌱 Help it grow

Curb Cut is tended the way a mango tree is: by hand, season after season, with
nothing to sell. That is what keeps it free. It also means the only way it
reaches the people it was built for is a person like you passing it along.

> [!IMPORTANT]
> **The kindest thing you can do today takes one minute.** Curb Cut is pitched
> to the Salesforce Trailblazer Labs Builder in Residence cohort, and community
> upvotes help decide who is selected. Open
> [the Curb Cut pitch on the Trailblazer Labs board](https://github.com/TrailblazerLabs/Cohort-Applications/discussions/8)
> and press the upvote arrow on the post. You need a free GitHub account, and
> nothing else.

Other ways to help, all of them welcome:

- **Nominate a workplace.** Send `NOMINATE` and a workplace name on any door. The name is written down so a person can reach out and offer this. Nothing about you is kept.
- **Star this repository**, so the next person who needs it can find it.
- **Break it and say where it broke.** [Open an issue](https://github.com/parthsevak2/curb-cut/issues). Many of the checks in this repository were born exactly that way. What felt wrong is as welcome as what felt right.
- **Contribute.** Start with [CONTRIBUTING.md](CONTRIBUTING.md) and the [code of conduct](CODE_OF_CONDUCT.md).
- **Read and share the story**, about ten minutes: [Curb Cut, the sidewalk, and the stage](https://parthsevak2.github.io/curb-cut/story.html). The landing page with the films is [parthsevak2.github.io/curb-cut](https://parthsevak2.github.io/curb-cut/).

## 📚 Reference

Everything below is for the reader who wants to look under the floorboards.

### What is deliberately not built

- **No automated sign language.** ASL is a complete language; recognition is unsolved. Signed video routes to a human, with immediate text acknowledgement so nobody waits in silence.
- **No diagnosis field.** It isn't encrypted or restricted. It's absent. CI fails the build if anyone adds one.
- **No phone fallback, ever.** `Reachable_By__c` accepts a message channel or email, and the code refuses a telephone number.
- **No inference.** Nothing is profiled or predicted. Every signal is one the person set.

### Verification

Nothing below is asserted from memory. Each number is the output of the command
beside it, last run 17 November 2026, and `tests/sync_counts.py` rewrites the published counts from the
invariant suite's own output so they cannot drift.

```
194 Apex tests                 sf apex run test -o curbcut -l RunLocalTests
627 structural invariants      python3 tests/invariants.py            ~1s, no org
509 accessibility checks       python3 tests/a11y_audit.py            against the live pages
 19 Sa11y tests                npm run test:a11y                      Salesforce's own axe-core matcher, 0 violations
 34 accessibility-tree checks  node tests/ax_tree_audit.mjs           what a screen reader is handed
 34 controls by keyboard       node tests/keyboard_walk.mjs           real Tab presses; set CURB_CUT_SITE
 21 responsible-AI checks      python3 tests/rai_self_check.py        against Salesforce's five guidelines
 28 contrast checks            python3 tests/contrast_audit.py        both themes, from the tokens
 17 reading-level checks       python3 tests/reading_level_audit.py
 71 link and copy checks       python3 tests/link_and_copy_audit.py
23/23 adversarial assertions   node tests/headless_agent_api.mjs && python3 tests/score_adversarial.py
```

Two of those suites break their own checks on purpose and assert each one goes
red (`--selftest`). A suite that cannot fail proves nothing about the code it
passes. The adversarial suite once scored 21 of 23, and both failures were
published with their transcripts rather than averaged away; the agent's
refusal wording and the scorer have since converged, and the suite passes
whole. The habit stands: a miss gets reported, never smoothed.

<details>
<summary><strong>Shipped recently</strong></summary>

- A one-command install, `bash scripts/install.sh`, and a setup check in plain words, `node scripts/check-setup.mjs`.
- Codes and handles are made under each org's own HMAC key.
- Uploads are checked for what they are.
- Return codes bring a person back to the same handler.
- Delivery receipts.
- Text, voice and email are offered only once the deployment connects its own number or address.
- Six labels, set by `node scripts/configure.mjs`.

The full history is in [CHANGELOG.md](CHANGELOG.md), and what is still open is in [KNOWN-ISSUES.md](KNOWN-ISSUES.md).

</details>

<details>
<summary><strong>The live deployment</strong>, every surface and its state on 17 November 2026</summary>

Curb Cut runs in an org of its own. Every web row below was checked from a
logged-out machine on 17 November 2026, and the agents were read from the org
the same day. Your install has its own address on every row; to feel the
product with no org at all, use the
[try page](https://parthsevak2.github.io/curb-cut/try.html).

| Surface | Address | State, 17 November 2026 |
|---|---|---|
| Web | https://curbcut-dev-ed.develop.my.salesforce-sites.com/curbcut | live |
| Ask (the whole flow, no phone) | `/curbcut/ask` | live |
| Privacy | `/curbcut/privacy` | live |
| Terms | `/curbcut/terms` | live |
| Why now | `/curbcut/why` | live |
| Messaging programme | `/curbcut/messaging` | live |
| Docs | `/curbcut/docs` | live |
| SMS | a Twilio number the deployment owns | built; this showcase has not connected a number, and each organisation brings its own |
| Voice | the same Twilio number | built, speech in and out; offered once a number is connected |
| Email | inbound service `CurbCutInbound`, address in Setup → Email Services | receiving; replies need a verified sending domain |
| Slack | `node channels/slack-app.mjs`, Socket Mode, DM only, never sends | runs beside the org; manifest in `channels/slack-manifest.json` |
| Agent | `Curb_Cut` v1, `Curb_Cut_Desk` v1 | both active |
| Console (internal) | `/lightning/app/Curb_Cut_Console`, home tab `/lightning/n/Curb_Cut_Home`, org login needed | live |
| MCP server | `npx curb-cut-mcp`, or `node channels/mcp-server.mjs` | 5 tools; none can send a request |
| Any relay or assistant | `POST /services/apexrest/curbcut/v1/message/` | one door every channel above shares |

What judges tested in September 2026 ran in the hackathon's own org, now
retired; that record lives in [docs/hackathon/](docs/hackathon/).

</details>

<details>
<summary><strong>The console</strong>, where the person on the other end stands</summary>

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

</details>

<details>
<summary><strong>More films</strong></summary>

- The film, 4 minutes 59 seconds, captioned, with every channel shown live: [watch the film on YouTube](https://youtu.be/yleHLiwWRKA)
- A 26-second recording of trying the ask page: [watch the 26-second recording](https://drive.google.com/file/d/13NApu8rq3MpJjuGG2yzKuJ2P02tKWwGx/view)
- A three-minute cut: [watch the three-minute cut](https://drive.google.com/file/d/1Loqum6Kbk1noQazJDKrrVEnHzoU3biMD/view)

</details>

<details>
<summary><strong>Repository map</strong></summary>

| Path | What |
|---|---|
| `force-app/main/default/objects/` | 10 objects, 64 fields, 33 list views, and no field for a diagnosis |
| `force-app/main/default/classes/` | 20 Apex classes + 16 test classes |
| `force-app/main/default/lwc/` | 5 Lightning Web Components, each with a Sa11y suite beside it |
| `force-app/main/default/aiAuthoringBundles/` | two Agent Scripts: `Curb_Cut` public, `Curb_Cut_Desk` internal |
| `force-app/main/default/pages/` `components/` `sites/` | the public site, seven pages, anonymous |
| `force-app/main/default/emailservices/` | inbound email channel |
| `force-app/main/default/applications/` `tabs/` `flexipages/` | the internal console |
| `force-app/main/default/reports/` `dashboards/` | five reports and the overview dashboard, no names anywhere |
| `channels/` | SMS + voice relay, Slack app (Socket Mode), MCP server, Twilio configuration |
| `scripts/` | the one-command install, the label setup and the plain-words setup check |
| `tests/` | every suite above, plus `lwc_audit.py`, `screen_reader_walk.mjs` (which writes docs/SCREEN-READER-WALK.md) and `count_claims.py`, the one list of every place a count is published |
| `deck/` | the deck as source; the built copy lives in `docs/hackathon/` |
| `docs/hackathon/` | the September 2026 hackathon record: judge guides, reflections, deck, stills |
| `legal/` | privacy and terms source |
| `docs/` | architecture, BRD, evidence, audience, decisions, the two audit reports |

Start with [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), then
[`CRITIQUE.md`](CRITIQUE.md), which is where the honest list of what is still
weak lives.

</details>

<details>
<summary><strong>Documentation</strong>, every document and what it is for</summary>

| Document | Purpose |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | How it fits together, with diagrams |
| [`docs/BRD.md`](docs/BRD.md) | Business requirements and traceability |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | What is next, and what was rejected |
| [`docs/DECISIONS.md`](docs/DECISIONS.md) | Every significant call and why |
| [`docs/EVIDENCE.md`](docs/EVIDENCE.md) | Every public figure, with source, denominator and caveat |
| [`docs/AGENT-INTERFACES.md`](docs/AGENT-INTERFACES.md) | Headless, MCP, agent-to-agent, and the profile we will not build |
| [`docs/CHANNELS.md`](docs/CHANNELS.md) | Every door, and what each one can and cannot do |
| [`docs/TECHNICAL-DESIGN.md`](docs/TECHNICAL-DESIGN.md) | The full technical design |
| [`docs/AGENT-VERSIONING.md`](docs/AGENT-VERSIONING.md) | How agent versions are published and activated |
| [`SECURITY.md`](SECURITY.md) | Reporting, and the hardening still ahead, named |
| [`KNOWN-ISSUES.md`](KNOWN-ISSUES.md) | What is open today, then the history |
| [`CHANGELOG.md`](CHANGELOG.md) | What changed, release by release |
| [`CRITIQUE.md`](CRITIQUE.md) | Self-critique, 30 August 2026, kept as written |
| [`FINDINGS.md`](FINDINGS.md) | The first adversarial runs, kept as written |
| [`CI.md`](CI.md) | Pipeline and invariants |
| [`DEPLOY.md`](DEPLOY.md) | Deployment |

</details>

## Licence

Apache 2.0. The accommodation library ships in the repo with a source citation
on every row. Use it, fork it, run it in your own org, and make it your own.

---

The name comes from the sidewalk ramps wheelchair users fought for. They were
built for a few people, and now everyone rolls through them: parents with
strollers, travellers with suitcases, delivery workers with carts. Build for
the people who get left out, and it gets better for everyone.

Built with love by Parth Sevak. Welland, Ontario, Canada.
Agentforce for Good, Dreamforce 2026 · Builder Track · Abilityforce.

<p align="center">
<strong>Curb Cut ✿</strong>
<br/>
<span>A small flower for what grows where a curb is cut.</span>
<br/>
<a href="https://parthsevak2.github.io/curb-cut/try.html">Say one sentence on the try page</a> ·
<a href="https://github.com/TrailblazerLabs/Cohort-Applications/discussions/8">Upvote the pitch on the Trailblazer Labs board</a>
</p>
