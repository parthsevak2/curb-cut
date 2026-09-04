# Devpost — every field, paste-ready

Deadline **7 Sep 2026, 8:00pm EDT**. Figures verified against the deployed org
on 1 September 2026.

Two fields are blocked on tools I cannot run; they are marked **NEEDS YOU** with
a scaffold ready to fill.

---

## Project assets

| Slot | What goes in it |
|---|---|
| **Code** * | `https://github.com/parthsevak2/curb-cut` — flip the repo public before you paste this |
| **Documentation** * | `https://claude.ai/code/artifact/80443669-bf1c-4365-883d-b0d1238b474a` — the walkthrough: eight people, eight channels, every command run |
| **Video** * | Your YouTube/Vimeo unlisted link once recorded |
| Design | `https://claude.ai/code/artifact/13947fab-1a4d-4586-a406-8e9ab39b5c22` — the evidence page |
| Presentation slides | `submission/Curb-Cut.pptx` — upload to Drive, paste the link |
| Prototype | `https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut` — live, anonymous, no login |

---

## Project Name

> Curb Cut

## Problem to solve

> Thirty in a hundred college-educated people in white-collar jobs in the United
> States have a disability. Three point two tell their employer. The
> accommodation is usually free and usually granted — 61% of the ones employers
> priced cost nothing — so the barrier was never money and never willingness. It
> is the asking: find the policy, learn its words, hold a work login, and write a
> sentence about your own body for somebody who will still be your manager on
> Monday. The request form is itself an accessibility barrier.

## Our solution

> An Agentforce agent whose principal is the worker, not the employer. You say
> what is *hard*, never why. You get real options from a sourced library with
> what each typically costs, and a request written in your own words that will
> not send until you clearly say yes. Five front doors — web, voice, email,
> Slack, and a Model Context Protocol server — all sharing one Apex router, so
> the words mean the same thing wherever you arrive. There is no field for a
> diagnosis anywhere in the schema, and if you name a condition anyway it is
> stripped before anything is stored.

---

## Project description (300–500 words)

**427 words.**

> Among college-educated people in white-collar jobs in the United States, 30%
> have a disability under the federal definition. 3.2% disclose it to their
> employer. Of those who did disclose, 83% say it got them better support.
> Disclosure works for five out of six people who try it, and almost nobody
> tries. That is not a population weighing costs and benefits. That is a door
> nobody can get through.
>
> The answer, when people do ask, is usually yes and usually free. Of the 1,425
> employers who gave the Job Accommodation Network cost figures through 2024, 61%
> said the accommodation cost them nothing. The bottleneck was never money and
> never willingness. It is the request itself: find the policy, learn its words,
> hold a work login, fill in the form, and say a sentence about your own body to
> somebody who will still be your manager on Monday.
>
> Curb Cut is an Agentforce agent whose principal is the worker. A person says
> what is hard, never why. They get real options from a sourced library with what
> each typically costs an employer. If they want to ask, a request is written in
> their own words and read back, and nothing is sent until they clearly agree — a
> hedge is refused, and a test proves the refusal. They can send a photo instead
> of typing, or a signed video, which is never machine translated, goes to a human
> interpreter, and is acknowledged in text immediately.
>
> Three things make it different. **You can ask before telling anyone anything** —
> nothing is written while you are anonymous. **There is no field for a diagnosis**
> — not encrypted, not permission-restricted, absent from 61 fields across 9
> objects, and a build check fails if anyone adds one. Because free text is still
> free text, a volunteered condition is stripped before the insert on the one
> write path every channel shares, and the person is told so in the same reply.
> **Nobody is ever routed to a telephone**, because for some of the people this
> serves a phone call is a door that does not open.
>
> It reaches people on five front doors — web, voice, email, Slack, and a Model
> Context Protocol server — all sharing one Apex router, so `OFF` cannot mean one
> thing on a phone and another in an inbox. A person who saves a standing
> disclosure is handed a six-character code and can withdraw it from any channel,
> on a service that holds no account and no phone number for them.
>
> It ships with an internal console, because a promise that a real person will
> pick this up is worthless unless that person has somewhere to stand.

---

## Team Representative

> Parth Sevak

## Did your project address one of the 16 Salesforce Equality Group challenge prompts?

> Yes — Abilityforce. Curb Cut addresses workplace accommodation for employees
> with disabilities, and specifically the disclosure gap: the accommodation
> process is itself the accessibility barrier that keeps people from using it.

**NEEDS YOU:** confirm the exact prompt wording from the Equality Group Challenge
page and paste it in, so the answer names their prompt rather than paraphrasing.

---

## Builder Track: What did the Accessibility Expert Skill find?

**NEEDS YOU — this tool must be run before submitting.** See `RUN-REQUIRED-TOOLS.md`.

Scaffold, so filling it in takes five minutes once you have the output:

> **What it flagged:** _(paste each finding)_
>
> **What we fixed:** _(per finding)_
>
> **What we kept, and why:** _(per finding)_

What we can already put beside their findings — our own accessibility work, all
machine-verified on every build:

- **333 accessibility checks against the six live pages**, not against source.
- **Contrast computed from the design tokens in both themes**, 28 checks. Border
  tokens were raised to `#C8C6BC` / `#87857B` specifically to clear WCAG 1.4.11
  non-text contrast at 3:1 — they had been decorative and failing.
- **Reading level measured, 16 checks.** The page somebody uses while struggling
  reads at grade 5.8. Every message the system says out loud is scored, and the
  build fails above the ceiling.
- **Reflow verified at 320px**; wide content scrolls in its own container.
- **Every focusable element has a visible focus ring**; every state carries a word
  or a shape as well as a colour.
- **Reader controls for text size and contrast persist and announce what they
  did** via a live region — they used to change silently, which is useless to a
  screen-reader user.
- **An auditor fails the build if an error message blames the user or leaves them
  nowhere to go.** That check is the reason several dead ends were found.
- **Deaf, blind, and hard of hearing are deliberately never redacted** from what a
  person writes. They are identity and function, not medical detail, and the
  interpreter routing reads them.

**What we found by driving the live page rather than scanning the source.** A
browser-level pass over the accessibility tree found four defects static analysis
could not see, all now fixed and pinned by new checks:

1. **The claim code never took focus.** Every other async update on `/ask` moves
   focus to its heading. The standing-preference save set the tabindex and then
   never called `focus()` — at the single moment a code is shown once and cannot
   be recovered.
2. **46 unnamed `<section>` elements** across six pages, each announced as an
   anonymous "region". Twelve of them on the home page alone.
3. **A 22px target** on the footer mail link, under WCAG 2.5.8's 24×24 — and it
   is the only way to reach a human by email.
4. **Status regions without `aria-atomic`**, so a rewritten message could be
   announced in fragments.

We also disproved one of our own findings: `:focus-visible` does not match a
programmatic `.focus()`, so a first pass appeared to show 26 controls with no
focus indicator. Driving it with real Tab presses showed the ring exactly as
intended. The test method was wrong, not the site — and we would rather report
that than a defect we did not have.

**The honest gap:** no screen-reader user has tested this. Every claim above is
machine-verified, which is not the same thing. One session with somebody who uses
one daily would be worth more than the next five features.

---

## Builder Track: What did the RAI Self Check find?

**NEEDS YOU — this tool must be run before submitting.** See `RUN-REQUIRED-TOOLS.md`.

> **What it flagged:** _(paste)_
>
> **How we addressed bias, fairness and transparency:** _(per finding)_

What we can already put beside their findings:

**Bias.** The agent may only name accommodations a grounded Apex action returned
from a 24-row sourced library. It cannot improvise one, and if the library has no
good match it says so rather than guessing — a confident wrong suggestion costs
somebody their one ask. It never invents a cost or a precedent count.

**Fairness.** The system holds no protected attribute to be unfair with. There is
no diagnosis, condition, disability type, medical note, severity or prognosis
anywhere in 61 fields across 9 objects, so nothing can be scored, ranked,
segmented or reported on by disability. Nothing is inferred about a person from
their behaviour.

**Transparency.** Every attempt on every channel lands in a delivery ledger — what
was tried, whether it landed — with a salted hash and never the message body. A
person can ask `WHO` and see everyone who has been shown a standing disclosure of
theirs, and `OFF` withdraws it immediately with no reason asked, because there is
nowhere to record a reason and so nobody can be asked for one later.

**Consent.** Nothing reaches an employer without an explicit yes in the
conversation. Two independent locks: the Apex refuses to set `Person_Approved__c`
without approval passed through, and a validation rule blocks the insert without
it.

**What we found ourselves and fixed, rather than waiting to be told:**

1. Six control words — `HUMAN`, `PERSON`, `OFF`, `WHO`, `CURB CUT` — were printed
   in user-facing copy and routed nowhere. `OFF`, the word that withdraws a
   disclosure, returned "I do not have good information on that" while the sharing
   stayed on. For a product whose thesis is consent, that was the most serious
   defect it could have had. One Apex router now owns them all, and an invariant
   fails the build if copy promises a word no channel answers.
2. The privacy policy said a volunteered condition "is not written to any record."
   It was stored verbatim. Now stripped before the insert, with the claim rewritten
   to state the limit rather than promise an absolute.
3. The adversarial scorer exited 0 with 100% of assertions inconclusive — it
   printed "silence must never read as success" and then did exactly that.

---

## Builder Track: What's your agent's current error rate, and what would "good" look like?

> **Measured, not estimated.** An 11-scenario adversarial suite runs headless
> through the Agent API — no Lightning UI anywhere in the path — and scores 23
> assertions. Across three consecutive runs on the same build it returned
> **21 of 23, every time: an 8.7% assertion failure rate.**
>
> The more useful number is the variance. One assertion fails on every run: the
> agent does not reliably say out loud that it discarded a volunteered condition.
> The second failure **alternates** between two different assertions run to run —
> same build, same prompts, different answers. A single green run would have been a
> misleading thing to report, which is why we ran it three times.
>
> Determinism is where we push the error rate to zero. The condition is stripped
> before storage by Apex on every channel, and on the four channels that compose
> their reply in Apex — web, text, email, Slack — the person is told so **every
> single time**, pinned by a test that exercises all four. The conversational agent
> is the exception: it rewrites what an action returns rather than relaying it. We
> tried a strengthened instruction (published as agent v7), the action returning
> the exact sentence, and the sentence embedded in the action's payload. It still
> says it about half the time. That is a model behaviour, and we state it rather
> than average it away.
>
> **What "good" looks like:** 23 of 23 with zero variance across five runs. Getting
> there means moving anything safety-critical out of the model's narration and into
> code that runs whether or not it remembers — which is the direction every fix in
> this project has taken.
>
> Around the agent, the deterministic surface is already there: **122 Apex tests,
> 491 structural invariants, 333 accessibility checks, 28 contrast checks and 16
> reading-level checks, all passing, all on every build.** Six auditors fail the
> build, including one that fails if an error message blames the user and one that
> fails if anyone adds a field for a diagnosis.

---

## Environmental impact

> We treated an LLM call as the expensive operation it is, and removed it wherever
> a cheaper mechanism gives a better answer.
>
> **The library lookup is not inference.** Ranking accommodations against what
> somebody said is a deterministic Apex stemmer with title-weighted scoring and a
> tie-break — no model, no embeddings, no vector store, no RAG pipeline to keep
> warm. The library is 24 curated, individually sourced rows. A keyword ranker over
> 24 rows is a SOQL query and some string work; the equivalent embedding search
> would cost more energy and give worse-sourced answers.
>
> **Control words never reach a model.** Roughly 70 phrases — `HUMAN`, `OFF`,
> `WHO`, `HELP`, `STOP` and their natural variants — are matched in Apex before any
> inference happens. Someone withdrawing consent gets an instant deterministic
> answer instead of a generation, which is both greener and more reliable.
>
> **Four of six channels answer with no LLM call at all.** Web, email, Slack and
> any external caller go through one Apex REST door that composes its reply in
> code. Only the conversational agent path invokes a model.
>
> **Redaction is a regex, not a classifier.** Stripping a volunteered condition
> runs against a compiled pattern list. A moderation model would have been the
> obvious reach and would have cost an inference on every single message.
>
> **CI runs no inference.** All six auditors are static Python and Node. The
> adversarial suite is the only thing that calls the agent, it is run deliberately
> rather than on every push, and its scorer now exits non-zero on inconclusive
> results so nobody re-runs it hunting for a green.
>
> **Sessions expire.** The relay holds one conversation per hashed handle with a
> 30-minute TTL, so no context is kept alive longer than the conversation.
>
> The design principle underneath all of it: if a rule matters, put it in code. A
> model asked to remember a rule burns energy every time it is asked and still
> forgets. Our own measurements show exactly that — the sentence the agent
> sometimes forgets is the one Apex now says every time, for free.

---

## AI Fluency Track fields

> NA

---

## Org credentials (judges only)

- **Org ID:** `00DgK00000YIJ5SUAX`
- **Instance:** `https://orgfarm-7a04c62cb9.my.salesforce.com`
- **Username / password:** yours to paste — do not put them in the repo.
