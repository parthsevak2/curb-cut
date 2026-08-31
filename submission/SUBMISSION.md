# Devpost submission — Curb Cut

Builder Track, Agentforce for Good: Dreamforce 2026.
Every field below is written to be pasted as-is. Figures verified 31 August 2026.

---

## 1–2 sentence pitch

> Thirty in a hundred white-collar employees have a disability; three tell their
> employer. Curb Cut is an Agentforce agent that belongs to the worker instead of
> the employer, so somebody can find out what they could ask for at work — and
> ask for it — without ever saying what condition they have.

---

## Why is your agent-based solution better than a traditional solution?

> A form can only collect; it cannot answer the question that actually stops
> people, which is "what am I even allowed to ask for" — and it demands a login,
> a vocabulary and a disclosure before it will do anything at all. An agent
> reaches the person on the channel they can already use, answers that question
> from a sourced library before any identity exists, and can refuse a manager
> who asks for a diagnosis, which a form has no way to do.

---

## How did you think about responsible AI and Agent Observability in your build?

> Responsible AI here is subtraction: there is no field for a diagnosis anywhere
> in the schema, the agent may only name accommodations a grounded Apex action
> returned, and nothing reaches an employer without an explicit yes — a hedge is
> refused. Observability is a delivery ledger that records every attempt on every
> channel with a salted hash and never the message, plus 446 structural
> invariants, 105 Apex tests and six auditors that fail the build, including one
> that fails if an error message blames the user or leaves them nowhere to go.

---

## Project description

**The problem.** Among college-educated people in white-collar jobs in the United
States, 30% have a disability under the federal definition. 3.2% disclose it to
their employer. Of those who did disclose, 83% say it got them better support.
Disclosure works for five out of six people who try it, and almost nobody tries.
That is not a population weighing costs and benefits. That is a door nobody can
get through.

The answer, when people do ask, is usually yes and usually free. Of the 1,425
employers who gave the Job Accommodation Network cost figures between 2019 and
2024, 61% said the accommodation cost them nothing; a third reported a one-time
median of $300. The bottleneck was never money and never willingness. It is the
request itself: find the policy, learn its words, hold a work login, fill in the
form, and say a sentence about your own body to somebody who will still be your
manager on Monday.

**Why now.** At an EEOC public hearing in January 2023 the estimate on the record
was that as many as 83% of employers, and up to 99% of the Fortune 500, use some
automated tool to screen or rank candidates. One side of the accommodation
conversation has been automated at scale. The other side is a person on a hard
day with a PDF. Every regulation arriving now governs the machine pointed *at*
the person; none of it hands the person anything. That asymmetry is what makes an
agent the right answer in 2026 rather than a nicer form.

**What it is.** Curb Cut is an Agentforce agent whose principal is the worker.
Four front doors — web, text, voice and email — plus a Model Context Protocol
server so the same grounded library is reachable from whatever assistant somebody
already uses. A person says what is *hard*, never why. They get real options from
a sourced library with what each typically costs. If they want to ask, a request
is written in their words and read back, and nothing is sent until they clearly
agree. They can send a photo instead of typing, or a signed video — which is
never machine translated, is routed to a human interpreter, and is acknowledged
in text immediately so nobody sits watching a screen wondering whether it sent.

**Intended users.** Employees, contractors, and job applicants who have no work
account at all — the group currently expected to disclose a disability to a
stranger before they have even been hired. And, equally, the people who *answer*:
Curb Cut ships an internal console because a promise that a real person will pick
this up is worthless unless that person has somewhere to stand.

**What makes it different.**

*You can ask before you tell anyone anything.* Nothing is written while you are
anonymous. Knowing is allowed; asking is optional.

*There is no field for a diagnosis.* Not encrypted, not permission-restricted —
absent. Diagnosis, condition, disability type, medical note, severity, prognosis
exist nowhere in 59 fields across 9 objects. A manager who asks is refused
because there is genuinely nothing to tell them, and an automated check fails the
build if anyone adds such a field. The internal agent refuses staff in exactly
the same words, and hands the operator the sentence to use on their own manager.

*Nothing is sent without an explicit yes.* "I guess so" is not agreement; the
code that creates a request refuses to run without approval and a test proves the
refusal.

*Nobody is ever routed to a telephone.* For some of the people this serves, a
phone call is a door that does not open. There is exactly one narrow exception —
an emergency escalation for a named squad — which cannot ring the person, because
the system holds no phone number to ring.

**Social impact.** Accommodations are cheap, effective and mostly granted, and
almost nobody requests them. Moving the request from a disclosure to a question
is the whole intervention. The most common unmet need in Canada's 2022 survey was
not equipment — it was modified working hours, which costs nothing and requires
only that somebody say yes.

**Accessibility.** The site is audited on every build against what it actually
serves: 275 checks across six live pages, contrast computed from the design
tokens in both themes, reading level measured (the page somebody uses while
struggling reads at grade 5.8), reflow verified at 320px, every focusable element
covered by a visible focus ring, and every state carried by a word or a shape as
well as a colour. Reader controls for text size and contrast persist and announce
what they did.

---

## Tools used

Agentforce (Agent Script, two agents: one public, one internal), Apex (15
classes, 12 test classes), Lightning Web Components (5), Force.com Sites +
Visualforce for the anonymous public site, Flows-free architecture, Salesforce
Reports and Dashboards, Path, Twilio (SMS + voice relay over TwiML), Salesforce
Email Services, a zero-dependency Model Context Protocol server, and the
Salesforce Agent API for headless invocation. Python and Node for the audit
suite; GitHub Actions for CI.

## Future improvements

Carrier approval for the text channel is with the reviewers. Email replies need a
verified sending domain the project does not own. Twilio status callbacks would
turn "accepted by the platform" into "actually delivered". Outcome tracking would
make precedent counts real — the one figure the agent currently refuses to invent.
And the internal agent reliably refuses medical questions and refuses to invent
accommodations, but does not yet call the library without being asked twice; the
grounded internal surface today is the console component, not the agent.

## Repository

https://github.com/parthsevak2/curb-cut

## Known limitations, stated plainly

Documented in `CRITIQUE.md` and `docs/AGENT-INTERFACES.md` rather than omitted.
No screen-reader user has tested this yet; one session with somebody who uses one
daily would be worth more than the next five features.
