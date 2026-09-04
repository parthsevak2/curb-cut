# Devpost. Every field, paste-ready

Deadline **7 Sep 2026, 8:00pm EDT**. Figures verified against the deployed org
on 1 September 2026.

Two fields are blocked on tools I cannot run; they are marked **NEEDS YOU** with
a scaffold ready to fill.

---

## Project assets

| Slot | What goes in it |
|---|---|
| **Code** * | `https://github.com/parthsevak2/curb-cut`. Flip the repo public before you paste this |
| **Documentation** * | `https://claude.ai/code/artifact/80443669-bf1c-4365-883d-b0d1238b474a`, the walkthrough: eight people, eight channels, every command run |
| **Video** * | Your YouTube/Vimeo unlisted link once recorded |
| Design | `https://claude.ai/code/artifact/13947fab-1a4d-4586-a406-8e9ab39b5c22`. The evidence page |
| Presentation slides | `submission/Curb-Cut.pptx`. Upload to Drive, paste the link |
| Prototype | `https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut`. Live, anonymous, no login |

---

## Project Name

> Curb Cut

## Problem to solve

> Thirty in a hundred college-educated people in white-collar jobs in the United
> States have a disability. Three point two tell their employer. The
> accommodation is usually free and usually granted. 61% of the ones employers
> priced cost nothing. So the barrier was never money and never willingness. It
> is the asking: find the policy, learn its words, hold a work login, and write a
> sentence about your own body for somebody who will still be your manager on
> Monday. The request form is itself an accessibility barrier.

## Our solution

> An Agentforce agent whose principal is the worker, not the employer. You say
> what is *hard*, never why. You get real options from a sourced library with
> what each typically costs, and a request written in your own words that will
> not send until you clearly say yes. Five front doors. Web, voice, email,
> Slack, and a Model Context Protocol server. All sharing one Apex router, so
> the words mean the same thing wherever you arrive. There is no field for a
> diagnosis anywhere in the schema, and if you name a condition anyway it is
> stripped before anything is stored.

---

## Project description (300–500 words)

**488 words.** Paste the body only, without the quote marks.

> You have already done this. Think of the last time something at work was quietly hard. Bad light, a chair that hurt by three o'clock, a meeting you kept missing half of. You weighed whether to mention it, guessed how it would land, and probably said nothing. Now make that permanent, and make it about your body, with the person who decides what you are worth.

> That is the ordinary version of something that happens to about a third of the workforce. Among college-educated people in white-collar jobs in the United States, 30% have a disability under the federal definition. 3.2% tell their employer. Of the people who did tell, 83% say it got them better support. It works for five out of six who try it, and almost nobody tries. That is not a population weighing costs and benefits. That is a door nobody can get through.

> The answer, when people ask, is usually yes and usually free. Of the 1,425 employers who gave the Job Accommodation Network cost figures through 2024, 61% said the accommodation cost them nothing. The bottleneck was never money and never willingness. It is the request itself: find the policy, learn its words, hold a work login, and write a sentence about your own body for somebody who will still be your manager on Monday. The request form is itself an accessibility barrier.

> Curb Cut is an Agentforce agent whose principal is the worker, not the employer. A person says what is hard, never why. They get real options from a sourced library with what each typically costs. If they want to ask, a request is written in their own words and read back, and nothing sends until they clearly agree. A hedge is refused, and a test proves the refusal. They can send a photo instead of typing, or a signed video, which is never machine translated and goes to a human interpreter.

> Three things make it different. You can ask before telling anyone anything, because nothing is written while you are anonymous. There is no field for a diagnosis: not encrypted, not permission-restricted, absent from 61 fields across 9 objects, and a build check fails if anyone adds one. Because free text is still free text, a volunteered condition is stripped before the insert on the one write path every channel shares, and the person is told so in the same reply. And nobody is ever routed to a telephone, because for some of the people this serves a phone call is a door that does not open.

> It reaches people through five front doors: web, voice, email, Slack, and a Model Context Protocol server, all sharing one Apex router, so OFF cannot mean one thing on a phone and another in an inbox. It ships with an internal console, because a promise that a real person will pick this up is worthless unless that person has somewhere to stand.

---

## Team Representative

> Parth Sevak

## Did your project address one of the 16 Salesforce Equality Group challenge prompts?

> Yes, Abilityforce. Curb Cut addresses workplace accommodation for employees
> with disabilities, and specifically the disclosure gap: the accommodation
> process is itself the accessibility barrier that keeps people from using it.

**NEEDS YOU:** confirm the exact prompt wording from the Equality Group Challenge
page and paste it in, so the answer names their prompt rather than paraphrasing.

---

## Builder Track: What did the Accessibility Expert Skill find?

**Answered with a real run.** Paste `devpost/Q1-accessibility.txt` verbatim,
4,000 characters, at the limit. Full write-up: `docs/A11Y-SA11Y-REPORT.md`.

---

We could not find a Salesforce tool published as "Accessibility Expert Skill", and we asked the organisers rather than imply we ran one. What we did find and run is Salesforce's own accessibility expert tooling: the lwc-experts toolset in the Salesforce DX MCP server (@salesforce/mcp), specifically guide_component_accessibility and run_lwc_accessibility_jest_tests, which stand up Sa11y, its axe-core matcher. If a different tool was intended, the findings below stand on their own.

WHAT WE RAN

Sa11y against all five Lightning Web Components in twelve states: 131 axe checks passed, 0 WCAG violations. We used the 100-rule "extended" preset, not the 64-rule "base" preset Sa11y applies by default. One rule, region, is excluded in one place with the reason beside it: it carries no WCAG tag and fires only because a component mounted alone in a test has no page landmarks.

Before trusting that, we planted an image with no alt text and asserted the matcher throws. It does. A suite that cannot fail proves nothing.

WHAT IT FOUND

1. A video that says nothing to the person who cannot watch it.

axe returned "incomplete", not pass, on video-caption (WCAG 1.2.2) for signed video in the console: it cannot inspect media. A screen reader user could.

The obvious remedy is the forbidden one. That video is usually a Deaf person signing, and auto-captioning it would be a machine putting words in somebody's mouth about their own body and then filing them. Our operator banner said so. But the operator was the only one told: a person reaching the video element got silence, with no explanation of it.

FIXED. Every video now carries an aria-describedby pointing at a note on the page for everyone: "No captions and no transcript, and none will be generated. This is waiting on a human interpreter." That does not satisfy 1.2.2 and we do not claim it does. It replaces an unexplained absence with a stated one, which is the honest position while an interpretation is pending.

2. The emergency form kept the last emergency's words.

The LWC compiler flagged LWC1057: value is not a valid attribute for textarea. A textarea holds its text as a child node, so the binding did nothing, and clearing the field in JavaScript left the words on screen. This is the one place in Curb Cut a telephone number comes out of, used when somebody may be at risk. Stale text there invites the next escalation to be raised on the last one's words.

FIXED, and the element is now cleared alongside the field.

WHAT THE TOOL COULD NOT DECIDE

color-contrast came back "incomplete" in all twelve states, because axe measures contrast by painting to a canvas and jsdom has none. We report that rather than bank it as a pass. Contrast is measured separately, by computing WCAG relative luminance from the stylesheets: 28 checks, all passing. The note added above measures 10.59:1 where 4.5:1 is required.

WHAT WAS ALREADY IN PLACE

333 accessibility checks against the six live pages every build, plus 28 contrast, 16 reading-level and 491 invariant checks. The build fails on any. Earlier browser passes fixed a claim code that never took focus (shown once, unrecoverable, and the screen reader user was the one person not told), 46 unnamed sections announced as anonymous regions, and a 22px target under WCAG 2.5.8.

A FINDING WE DISPROVED

An early browser pass appeared to show 26 controls with no focus indicator. But :focus-visible does not match a programmatic .focus(). Driven with real Tab presses it is 3px solid rgb(11,87,199), as designed. The method was wrong, not the site. We report it because claiming a defect we did not have is worse than missing one.

THE GAP WE HAVE NOT CLOSED

No screen reader user has tested this. Everything above is machine- or browser-verified, which is not the same as somebody using it. One session with a person who uses a screen reader daily is worth more than the next five features, and we say so on the evidence page rather than letting the numbers imply otherwise.

---

## Builder Track: What did the RAI Self Check find?

**Still needs the tool.** No RAI Self Check exists under that name: not in the
org, not on AgentExchange, not among the DX MCP server’s fifteen toolsets. Send
the message in `devpost/ASK-THE-ORGANISERS.txt`. Meanwhile paste
`devpost/Q2-responsible-ai.txt` verbatim, 3,994 characters, which says so in its
first line and then answers in the shape the question asks.

---

We could not find a Salesforce tool published as "RAI Self Check Skill": not in the provisioned org, not on AgentExchange, not locatable under that name. The Salesforce DX MCP server publishes accessibility, security and code-analysis experts, but no responsible-AI self check. We asked the organisers rather than imply we ran one. What follows is our own audit, in the shape the question asks.

Our approach is subtraction, and the honest version is that our own checks caught us breaking our own rules three times.

BIAS

The agent may only name accommodations a grounded Apex action returned from a sourced library of 28 individually cited rows. It cannot improvise one. If the library has no good match it must say so rather than guess, because a confident wrong suggestion costs somebody their single ask. It never invents a cost or a precedent count.

We caught this failing in exactly the way it was designed not to. "I get migraines from the office lighting" returned "special chair or back support", because 'office' appeared in that summary and one weak overlap was enough to qualify. There was no lighting accommodation in the library at all. Two fixes: four lighting rows added, and the ranker now weighs how much a word DISTINGUISHES, not merely whether it appears.

FAIRNESS

The system holds no protected attribute to be unfair with. There is no field for a diagnosis, condition, disability type, medical note, severity or prognosis in 61 fields across 9 objects. Not encrypted, not permission-restricted, absent. A build check fails if anyone adds one. Nothing can be scored, ranked, segmented or reported on by disability, and nothing is inferred from behaviour. Every signal is one the person set, in their own words.

Encryption would not achieve this. It defends against outsiders; the adversary here is the organisation holding the data. A manager with legitimate access to an encrypted diagnosis field can still read it. The only field that cannot be leaked, subpoenaed or shown to a manager is the one that was never created.

TRANSPARENCY

Every attempt on every channel lands in a delivery ledger: what was tried and whether it landed, with a salted hash and never the message body. A person can send WHO and see everyone shown a standing disclosure of theirs. OFF withdraws it immediately with no reason asked, because there is nowhere to record a reason and so nobody can ever be asked for one later.

CONSENT

Nothing reaches an employer without an explicit yes in the conversation, held by two independent locks: the Apex refuses to set the approval flag without approval passed through, and a validation rule blocks the insert. The interesting case is not refusal but the hedge: "I guess so, I think that's probably fine?" is not agreement.

THE THREE THINGS WE FOUND OURSELVES

1. Six control words were printed in our user-facing copy and routed nowhere. HUMAN returned an ASL interpreter card. OFF, the word that withdraws a disclosure, returned "I do not have good information on that" while the sharing stayed live. For a product whose thesis is consent, a withdrawal that silently fails was the most serious defect it could have had.

2. Our privacy policy said in public that a volunteered condition "is not written to any record". It was stored verbatim. Conditions are now stripped before the insert on the one write path every channel shares, and the claim is rewritten to state its limit rather than promise an absolute a word list cannot keep.

3. Our adversarial scorer exited zero with 100% of assertions inconclusive. It printed "silence must never read as success", then did exactly that at the exit-code level.

Each now has a check that fails the build if it returns.

THE LESSON WE WOULD PASS ON

Instructions are not controls. We told the agent not to record a volunteered condition; it complied in its narration while the action recorded the text anyway. Everything safety-critical now lives in code that runs whether or not a model remembers.

---

## Builder Track: What's your agent's current error rate, and what would "good" look like?

> **Measured, not estimated.** An 11-scenario adversarial suite runs headless
> through the Agent API, no Lightning UI anywhere in the path, and scores 23
> assertions. Across three consecutive runs on the same build it returned
> **21 of 23, every time: an 8.7% assertion failure rate.**
>
> The more useful number is the variance. One assertion fails on every run: the
> agent does not reliably say out loud that it discarded a volunteered condition.
> The second failure **alternates** between two different assertions run to run, > same build, same prompts, different answers. A single green run would have been a
> misleading thing to report, which is why we ran it three times.
>
> Determinism is where we push the error rate to zero. The condition is stripped
> before storage by Apex on every channel, and on the four channels that compose
> their reply in Apex, web, text, email, Slack. The person is told so **every
> single time**, pinned by a test that exercises all four. The conversational agent
> is the exception: it rewrites what an action returns rather than relaying it. We
> tried a strengthened instruction (published as agent v7), the action returning
> the exact sentence, and the sentence embedded in the action's payload. It still
> says it about half the time. That is a model behaviour, and we state it rather
> than average it away.
>
> **What "good" looks like:** 23 of 23 with zero variance across five runs. Getting
> there means moving anything safety-critical out of the model's narration and into
> code that runs whether or not it remembers. Which is the direction every fix in
> this project has taken.
>
> Around the agent, the deterministic surface is already there: **124 Apex tests,
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
> tie-break. No model, no embeddings, no vector store, no RAG pipeline to keep
> warm. The library is 28 curated, individually sourced rows. A keyword ranker over
> 28 rows is a SOQL query and some string work; the equivalent embedding search
> would cost more energy and give worse-sourced answers.
>
> **Control words never reach a model.** Roughly 70 phrases. `HUMAN`, `OFF`,
> `WHO`, `HELP`, `STOP` and their natural variants. Are matched in Apex before any
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
> forgets. Our own measurements show exactly that. The sentence the agent
> sometimes forgets is the one Apex now says every time, for free.

---

## AI Fluency Track fields

> NA

---

## Org credentials (judges only)

- **Org ID:** `00DgK00000YIJ5SUAX`
- **Instance:** `https://orgfarm-7a04c62cb9.my.salesforce.com`
- **Username / password:** yours to paste, do not put them in the repo.
