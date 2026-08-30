# Decisions

Each entry: what was decided, and what it cost.

## D1 — Absence over encryption
There is no diagnosis field. Encryption protects data that exists; the stronger
control is not to hold it. **Cost:** the agent cannot personalise on condition,
and never will. That is the point.

## D2 — Three locks on approval, not one
The model judges the hedge, the Apex refuses unapproved input, and a validation
rule blocks the insert. **Cost:** redundancy. Justified: the model failed this
test during development, and the other two caught it.

## D3 — The web and email channels have no model in them
They call the same Apex the agent calls, deterministically. **Cost:** the web
cannot converse freely. **Gain:** the highest-stakes path has nothing to
hallucinate, and the safest channel is the one available to people with the
least.

## D4 — Visualforce, because nothing else exists here
`Network`, `ExperienceBundle` and `DigitalExperienceConfig` are unavailable in
this org. **Cost:** an older component model. **Mitigation:** `LightningComponentBundle`
is available whenever Digital Experiences is licensed.

## D5 — STOP is the carrier's word, not ours
The agent originally told people to reply `STOP` to revoke a preference. STOP is
a reserved carrier opt-out keyword: the message is intercepted, the person gets a
generic unsubscribe notice, and the preference stays live while they believe they
turned it off. Now `DELETE`, `OFF` and `WHO`. **Cost:** three more words to
learn. **Gain:** revocation actually revokes.

## D6 — Whole-word matching in the library
`contains()` matched `long` inside `alongside` and offered visual fire alarms to
someone who could not type. **Cost:** slightly narrower recall. **Gain:** an
irrelevant suggestion tells someone already having a hard week that they were
not heard.

## D7 — A narrow `without sharing` reader for the library only
The guest user owns none of the library rows, so sharing returned an empty
library and the agent honestly reported knowing nothing. **Scope:** one class,
one object, no personal data, field-level security still enforced.

## D8 — The request survives a broken link
A guest cannot reference a record it may not read, so linking a request to its
barrier report failed the insert. Now retries without the link. **Cost:** some
requests lack provenance. **Gain:** nobody loses their request to a foreign key.

## D9 — Email consults but never sends
An email cannot carry in-the-moment approval. Agreeing in writing, days later, is
not the same as choosing in the moment. Email answers and hands off to the web,
where the send button is visible.

## D10 — The critique file ships
`CRITIQUE.md` lists what is still broken, in public. A system claiming a perfect
score against its own adversarial suite is telling you about its suite.
