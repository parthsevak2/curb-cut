# Conformance against curb-cut-build-spec.md

Checked 2026-08-30. Verified against the deployed org, not against source.

## Section 2 — Data model: CONFORMS

All five spec objects exist with every field the spec names. Defaults verified
in the deployed metadata:

    Never_Call__c            default TRUE   (spec: default TRUE)
    Plain_Language_Mode__c   default TRUE   (spec: default TRUE)
    Active__c                default TRUE
    Anonymous__c             default TRUE
    Preferred_Modality__c    default Text   (spec: default Text)
    Inbound_Modality__c      Text / Voice note / Video / Image

**Fields that do not exist — verified zero matches across all field API names:**
`Diagnosis`, `Condition`, `Disability_Type`, `Medical_Note`, `Severity`,
`Prognosis`. The words appear only in object *descriptions*, asserting their own
absence. The full 37-field inventory is in `FIELD-INVENTORY.txt` — spec section 2
calls the field list a submission asset.

Two objects beyond the spec's five: `Disclosure_Event__c` (ledger of every time a
preference was shown, which strengthens principle 3) and `Human_Handoff__c` (the
escape hatch). Both additive.

## Section 4 — Agent design: CONFORMS, after a rewrite

The Agent Script as originally written produced 510 compilation errors and did
not parse. It was ported to the shipped grammar; every instruction carried over
verbatim. The spec's four topics all exist as subagents, plus two the spec
implies but does not enumerate:

    consult, request, standing, decide, interpreter_relay, human_handoff

`start_agent` routes only. No business logic there, per spec.

## Section 3 — Channel abstraction: NOW CONFORMS

Was missing. `Barrier_Report__c` was never written by anything — the intake
object at the head of the data model was write-dead.

`CurbCutIntake` (`apex://CurbCutIntake`) now normalises all four modalities into
a `Barrier_Report__c`, anonymous by default, writing no profile link at all
unless the person identified themselves. Signed video sets
`Interpreter_Needed__c` and nothing else.

**Still outstanding:** no SMS/channel adapter (spec build order, Aug 31), and the
headless Agent API path has not been exercised (spec section 3 Headless
requirement, and the Aug 30 gate).

## Section 4 topic.standing — NOW CONFORMS

Was missing. The subagent only talked; `Access_Preference__c` was never created
and `Revoked_On__c` was never written, so principle 4 was unimplemented.

`CurbCutStanding` now saves and revokes. Revocation stamps `Revoked_On__c`
immediately and **takes no reason parameter** — there is nowhere to put one, so
nobody can be asked for one later. Test `revocationIsImmediateAndAsksNoReason`
asserts the response contains neither "why" nor "reason".

## Section 4 topic.decide — NOW CONFORMS

Was missing its data. The manager brief is the beat the video turns on (section
8) and had no numbers to cite.

`CurbCutCostBrief` returns, in spec order: cost reality (JAN employer survey
through 2024, 61 in 100 at zero cost, median about $300, with source URL), then
precedent from the library, then the interactive-process clock. When precedent
data is absent it says so rather than inventing a number, and never presents a
zero as a precedent count.

## Section 5 — Adversarial suite: AUTHORED, NOT RUN

`tests/curb-cut-adversarial.yaml` now maps 1:1 onto the spec's ten, in spec
order. Four were missing before and are now present: prompt injection (3),
anonymous consult writes no request (5), revocation (6), reading level under
pressure (8).

Converts to valid metadata (10 `<testCase>` blocks). **Cannot be run in this
org** — Testing Center is not licensed and is not reachable by a settings
deploy. See TESTING.md.

Three of the ten are additionally covered by Apex tests that DO run:
case 5 (`anonymousConsultWritesNoRequest`), case 6
(`revocationIsImmediateAndAsksNoReason`), case 10
(`briefSaysSoWhenThereIsNoPrecedentData`).

## Section 7 — Build order

Aug 29 gate (objects exist): **met.**
Aug 30 gate (thin slice works end to end, headless): **not met.** The agent is
published and live, but no conversation has been run against it and nothing has
called it through the Agent API.

## Apex

    24 / 24 tests pass

    CurbCutOptions        89%    CurbCutIntake      88%
    CurbCutDraftRequest  100%    CurbCutCostBrief  100%
    CurbCutCreateRequest  94%    CurbCutStanding    81%
    CurbCutCreateHandoff  78%
