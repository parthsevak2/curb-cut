# Business requirements

## Problem

Requesting a workplace accommodation requires navigating a process designed by
and for people without the disability in question. The cost of the accommodation
is rarely the obstacle; the cost of asking is.

| Finding | Figure | Source |
|---|---|---|
| Accommodations costing the employer nothing | 61 of 100 | JAN, 5,406 employers, 2019–2024 |
| Median one-time cost of the rest | $300 | JAN |
| Employed Canadians with a disability whose need went **unmet** | more than a third | Statistics Canada, 2022 |
| Most common need | modified work hours (16.3%) | Statistics Canada, 2022 |

The Government of Canada's Workplace Accessibility Passport already solves the
repetition problem — for federal public servants only.

## Who this is for

| Group | Currently excluded because |
|---|---|
| Employees with a disability | Must find policy, learn its vocabulary, and disclose to a stranger |
| Workers with no corporate account | Contractors, shift workers, franchise staff — no login, no intranet |
| **Applicants** | Expected to disclose a disability before being hired |
| Deaf and hard-of-hearing workers | Every escalation path ends at "give us a call" |
| Managers | Must decide without cost reality or precedent, and are asked for information they should never receive |

## Requirements and traceability

Every requirement maps to something that can be checked.

| # | Requirement | Where it lives | How it is verified |
|---|---|---|---|
| R1 | No diagnosis, condition, disability type, medical note, severity or prognosis may be stored | Schema — no such field | `invariants.py` fails the build |
| R2 | Nothing is sent onward without explicit approval | `CurbCutCreateRequest` + `Requires_Person_Approval` | Apex tests; adversarial case 11 |
| R3 | A hedge is not approval | Agent Script `request` subagent | Adversarial case 11, traced |
| R4 | No path may end at a phone call | `Reachable_By__c` hard-coded | Apex test; adversarial case 4 |
| R5 | A person may get a real answer anonymously | `Anonymous__c` default true; no profile link | `CurbCutWebTest`, `CurbCutSpecTest` |
| R6 | The agent may only describe options from the grounded library | `CurbCutOptions`, every row cited | Adversarial cases 3, 10 |
| R7 | Absent precedent must be stated, never invented | `CurbCutCostBrief` | `briefSaysSoWhenThereIsNoPrecedentData` |
| R8 | Signed video is never machine translated | `interpreter_relay` subagent | Adversarial case 9 |
| R9 | Revocation is immediate and needs no reason | `CurbCutStanding` takes no reason parameter | `revocationIsImmediateAndAsksNoReason` |
| R10 | Every disclosure is visible to the person it concerns | `Disclosure_Event__c` | Schema; `WHO` keyword |
| R11 | All four modalities are equal front doors | `Inbound_Modality__c`; SMS, voice, web, email | `everyModalityIsAcceptedAndUnknownFallsBackToText` |
| R12 | Plain language, roughly grade 6 | System instructions | Adversarial case 8 — **not yet automated** |
| R13 | Raw phone numbers are never stored | Salted SHA-256 in the relay | Code review; logs carry a hash prefix only |
| R14 | The guest user can see nothing about a person | `Curb_Cut_Guest` permission set | `invariants.py` guest checks |

## Out of scope, deliberately

Automated sign language. A diagnosis field of any kind. Any phone fallback.
Behavioural inference or profiling. A reason field on revocation.

Rationale in [`ROADMAP.md`](ROADMAP.md#deliberately-rejected).

## Success measures

| Measure | Target | Now |
|---|---|---|
| Requests created without explicit approval | 0 | 0, verified |
| Fabricated accommodations, costs or precedents | 0 | 0 since whole-word matching fix |
| Paths terminating at a phone call | 0 | 0 |
| Modalities accepted | 4 | 3 live (text, voice, email); image partial |
| Adversarial assertions passing | all | 23 / 23 |
| Apex coverage | ≥ 75% | 89% |

## Constraints

- Trial org, expires 7 Oct 2026. No Experience Cloud, Slack or Tableau licensing.
- US A2P 10DLC registration gates SMS; voice, web and email are unaffected.
- Sole Proprietor A2P brand: one long code, 3,000 segments per day.
