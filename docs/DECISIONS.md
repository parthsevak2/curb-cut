# Decisions

Each entry: what was decided, and what it cost.

## D1. Absence over encryption
There is no diagnosis field. Encryption protects data that exists; the stronger
control is not to hold it. **Cost:** the agent cannot personalise on condition,
and never will. That is the point.

## D2. Three locks on approval, not one
The model judges the hedge, the Apex refuses unapproved input, and a validation
rule blocks the insert. **Cost:** redundancy. Justified: the model failed this
test during development, and the other two caught it.

## D3. The web and email channels have no model in them
They call the same Apex the agent calls, deterministically. **Cost:** the web
cannot converse freely. **Gain:** the highest-stakes path has nothing to
hallucinate, and the safest channel is the one available to people with the
least.

## D4. Visualforce, because nothing else exists here
`Network`, `ExperienceBundle` and `DigitalExperienceConfig` are unavailable in
this org. **Cost:** an older component model. **Mitigation:** `LightningComponentBundle`
is available whenever Digital Experiences is licensed.

## D5. STOP is the carrier's word, not ours
The agent originally told people to reply `STOP` to revoke a preference. STOP is
a reserved carrier opt-out keyword: the message is intercepted, the person gets a
generic unsubscribe notice, and the preference stays live while they believe they
turned it off. Now `DELETE`, `OFF` and `WHO`. **Cost:** three more words to
learn. **Gain:** revocation actually revokes.

## D6. Whole-word matching in the library
`contains()` matched `long` inside `alongside` and offered visual fire alarms to
someone who could not type. **Cost:** slightly narrower recall. **Gain:** an
irrelevant suggestion tells someone already having a hard week that they were
not heard.

## D7. A narrow `without sharing` reader for the library only
The guest user owns none of the library rows, so sharing returned an empty
library and the agent honestly reported knowing nothing. **Scope:** one class,
one object, no personal data, field-level security still enforced.

## D8. The request survives a broken link
A guest cannot reference a record it may not read, so linking a request to its
barrier report failed the insert. Now retries without the link. **Cost:** some
requests lack provenance. **Gain:** nobody loses their request to a foreign key.

## D9. Email consults but never sends
An email cannot carry in-the-moment approval. Agreeing in writing, days later, is
not the same as choosing in the moment. Email answers and hands off to the web,
where the send button is visible.

## D10, The critique file ships
`CRITIQUE.md` lists what is still broken, in public. A system claiming a perfect
score against its own adversarial suite is telling you about its suite.

## D11. The stated absence, instead of a machine caption
Salesforce's own Sa11y run returned `incomplete` on `video-caption` (WCAG 1.2.2)
for signed video: axe cannot inspect media, so it could not decide. A screen
reader user could. The obvious remedy was the one thing this product promises
never to do, because that video is usually a Deaf person signing and a machine
caption puts words in somebody's mouth about their own body and then files them.
Every video now carries an `aria-describedby` note saying there are no captions,
none are coming, and a human interpreter is what it waits on. **Cost:** this does
not satisfy 1.2.2, and the report says so rather than claiming otherwise.
**Gain:** an unexplained silence becomes a stated one, for the person the silence
was failing.

## D12. The 100-rule preset, and one rule removed in the open
Sa11y's matcher defaults to a 64-rule `base` preset. We assert against the
100-rule `extended` preset instead, and remove exactly one rule: `region`, which
carries no WCAG tag and fires only because a component mounted alone in a test
has no page landmarks around it. It is removed in one file, with the reason
written beside it. **Cost:** one rule genuinely not enforced at component level.
**Gain:** the difference between a suite that is quiet because the code is right
and one that is quiet because the rule was never run. For the same reason
`incomplete` results are reported as undecided rather than counted as passes.

## D13. A disclosure is only a disclosure if somebody can be shown it
The ledger object shipped in week one and `WHO` read from it, but nothing ever
wrote a row. No console view, component or flow showed a standing preference
to anyone, so "travels ahead of you" meant save and revoke, and `WHO` could
only ever answer "Nobody has been shown it yet". True, and useless. Now
`CurbCutShow` is the one place a preference is shown. The viewer says who they
are reading as, and we show only what the person chose for that audience. The
ledger row is written before a word is returned; if the write fails, nothing is
shown. The person can read the ledger back with `WHO` and get a name and a date.
**Cost:** a viewer can name an audience they are not. We record what they
claimed, next to their real name, so the person can see it and ask.
**Gain:** the feature this project is named for exists, and every showing is
something the person can find out about. An invariant now fails the build if
no production class writes the ledger, so it cannot quietly go back to being a
promise.

