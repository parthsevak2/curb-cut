# Submission text

> Note: the build spec calls for "the three short-answer fields" without
> enumerating them. The three below are written against the rubric's three
> heaviest criteria — Accessibility, Responsible AI, Social Impact, 20% each.
> If the real form asks something different, the material is here to recut.

---

## Project description (438 words)

The process for requesting a disability accommodation is itself an accessibility
barrier.

To get help you must first navigate a system designed by and for people without
your disability. Find the policy. Learn its vocabulary. Hold a corporate login.
Complete a form. And disclose something you may be afraid to disclose — to a
stranger, in writing, in a language that may not be your first.

The Job Accommodation Network's employer survey through 2024 found that 61 of
every 100 accommodations cost the employer nothing, and that the median one-time
cost of the rest was about $300. The money was never the barrier. The process is.

Curb Cut is an Agentforce agent whose principal is the worker, not the employer.
It runs headless — text, voice note, video and image are four equal front doors,
and there is no interface to learn. A person with no corporate account, or an
applicant with no account at all, texts a number and gets a real answer.

Four things make it different from anything on the market.

**You can ask before you disclose.** The agent will tell you what you could ask
for without ever learning who you are. Nothing is written while you are
anonymous. Knowing is allowed; asking is optional.

**There is no field for your diagnosis.** Not encrypted, not permission-
restricted — absent. Diagnosis, Condition, Disability Type, Medical Note,
Severity, Prognosis exist nowhere in the schema. When a manager asks what
condition someone has, the agent refuses and the session trace shows the refusal.
It is not being discreet. It has nothing to disclose. Continuous integration
fails the build if anyone adds such a field.

**The person holds the pen.** Nothing is sent without explicit approval in the
conversation. Tested against the case that actually happens: a person replies
"I guess so, I think that's probably fine?" The agent does not send. It says
"I want to be sure before sending anything" and reads the draft back. One record
is created, on the yes, not on the maybe.

**It never falls back to a phone call.** Every HR escalation path in existence
ends at "give us a call." For a Deaf or hard-of-hearing worker that is a wall.
Handoff is hard-coded to message, and sign language is never machine-translated —
signed video routes to a human interpreter with receipt acknowledged in text
immediately, so nobody waits in silence.

Curb cuts were built for wheelchairs. Everyone uses them. Plain language, no
forms and no phone requirement help Deaf signers writing in a second language,
newcomers, people with cognitive disabilities — and, as it turns out, everyone.

---

## Short answer 1 — Accessibility

No interface to learn. The person needing help should not have to master a new
system in order to ask for help, so there is no Lightning UI anywhere in the
demo path — everything runs through the Agent API and messaging channels.

Four modalities are equal front doors, not a primary path with fallbacks. Text,
voice note, video and image all normalise into the same intake, and the reply
comes back in the modality the person used.

Plain language is default on every path — short sentences, common words, no
policy register, no acronyms. When asked a deliberately statutory question the
agent is instructed to translate rather than mirror.

And there is no phone fallback anywhere in the system. Not for escalation, not
for HR. `Reachable_By__c` is hard-coded to message. This is architectural, not a
setting someone can flip.

## Short answer 2 — Responsible AI

The strongest control is the one that removed the risk instead of managing it:
there is no field for a diagnosis, so there is nothing to leak, mis-permission,
or subpoena. That is enforced by the data model and by CI, not by policy.

Everything outbound is gated on explicit human approval, twice over — the Apex
refuses to set the approval flag without it, and a validation rule blocks the
insert independently.

The agent answers only from a grounded library of 14 options, each carrying its
source URL. When it has no match it says so rather than guessing. When it has no
precedent data it says that a zero means "we do not know," not "never approved."

We ran ten adversarial cases against the live agent, headless, and publish the
failures as well as the passes. Three assertions still fail. A submission
claiming a perfect score against its own adversarial suite is telling you about
its suite, not its agent.

## Short answer 3 — Social Impact

It reaches the people the existing process excludes by design: workers with no
corporate account, contractors, and applicants who have no account at all and
who currently have to disclose a disability to a stranger before they have even
been hired.

Onboarding cost per person is zero. There is nothing to provision, no licence to
assign, no training. A phone number and a message.

And the disclosure ledger means a standing preference that travels ahead of you
is visible to you. A preference shown to a new manager is a disclosure made in
your absence — so every time it is shown is recorded, the person can see the
full list by replying WHO, and can revoke in one message. The revoke path takes
no reason parameter. There is nowhere to put one, so nobody can ever be asked
for one.
