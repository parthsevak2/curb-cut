# Roadmap

Ordered by how many people it reaches per unit of work, not by how impressive it
sounds. Everything in "Shipped" is verified live; everything below it is honest.

## Shipped

| | Reaches |
|---|---|
| **Web front door** — full journey, no phone, no account | Anyone with a browser: library computer, shared desktop, screen reader |
| **SMS** (pending carrier approval) | Anyone with a basic phone and no smartphone, no data, no app |
| **Voice, speech in and out** | Motor disability, dyslexia, low literacy, blindness — anyone for whom speaking beats typing |
| **Email** | No mobile plan; a shared phone; needing to compose slowly over days |
| **Grounded library, 24 rows, every row cited** | Everyone — it is what stops the system inventing entitlements |
| **Disclosure ledger** | Anyone whose preference travels ahead of them into a new team |
| **Why-now argument** (`/curbcut/why`) | The reader who needs to know why this matters in 2026, not in the abstract |
| **Opt-in programme page** (`/curbcut/messaging`) | Carrier reviewers, and anyone deciding whether to trust a number on a poster |
| **Internal console** — On Duty queues, 5 reports, dashboard, record pages | The person answering. The escape hatch used to open onto nothing |
| **MCP server**, 3 tools, no send tool | Anyone already inside another assistant, who should not have to come here |
| **Agent-to-agent handover contract** | The person whose request reaches an employer's system rather than a human |
| **SMS compliance layer** — disclosure, HELP, STOP, START | Everyone on the text channel; it is what makes the opt-in real |

## Blocked on something outside the code

### Email delivery
The ledger now proves Salesforce **accepts** every reply — `Email / Outbound /
Accepted`, no error text. It never arrives, not even in spam. That places the
loss downstream of Salesforce, and there are only two candidates:

1. **No verified sending domain.** There is no `OrgWideEmailAddress`, and the
   run-as user's domain is unverified, so Deliverability substitutes
   `email@<uniqueId>.sfcustomeremail.com`. Some receivers reject that outright
   rather than filing it.
2. **Org deliverability access level.** If it is *System email only*, Apex mail
   is accepted and discarded, which matches the symptom exactly.

**Fix requires a domain the project does not own**, plus DKIM records on it.
Until then the escalation path carries the load: an undeliverable reply becomes
a `Human_Handoff__c` rather than silence.

**Do not demo email live.** It receives correctly and logs correctly; the reply
leg is not dependable on this org.

## Next — buildable in this org today

### 1. Standing preferences on the web  *(principle 4, and it is currently stranded)*

This is now the largest functional gap in the system, and it was hiding.

`CurbCutStanding` exists, is tested, and is wired to the **agent**, so it is
reachable by voice and — once the carrier clears it — by text. But the web front
door does not go through the agent. `CurbCutWeb` exposes exactly four remote
actions: `consult`, `draft`, `send`, `human`. None of them touch a preference.

So the promise the whole project is named for — explain once, and never explain
it again to the next manager — cannot be used by anyone arriving in a browser.
The org bears this out: **0 `Access_Preference__c` rows and 0
`Disclosure_Event__c` rows exist.** Two objects, a console tab, a disclosure
ledger, and the WHO and OFF keywords are all built and all currently unreachable
from the only channel that needs no phone.

Needs: `save`, `revoke` and `who` remote actions on `CurbCutWeb`, and a section
on `/ask` that offers to remember something after a request is sent. Guest write
access already exists for create; revoke needs care, because the guest user
cannot edit, so revocation has to be modelled as a new record rather than an
update.

### 2. Image intake on the web  *(spec §3, the fourth modality)*
`ContentVersion` upload from the guest user, attached to the barrier report.
"Here is a photo of my workstation" is often faster and less painful than
describing a chair. Email already accepts image attachments and records the
`Image` modality; the web does not yet.

### 3. Signed-video intake and the interpreter queue
Upload, mark `Interpreter_Needed__c`, acknowledge in text **immediately**, route
to a human. The refusal to machine-translate stays absolute. Today the agent
routes correctly but nothing accepts the upload.

### 4. Manager brief as a shareable link
`cost_brief` returns cost, precedent and the interactive-process clock. A manager
should be able to open one page rather than converse. Refusals still apply.

### 5. Finish the ledger, and learn the difference between accepted and delivered
Email, SMS and voice now write to `Message_Log__c`. **The web does not.**
`CurbCutWeb` never calls `CurbCutLog`, so the one channel anybody can use today
is the one channel missing from the answer to "did we reach this person".

Separately, every row currently says `Accepted`, which means a platform took the
message, not that a person received it. Twilio's status callback reports actual
carrier delivery. Until that is wired, the ledger can only prove we tried.

### 6. A React client — a decision, not a task

Asked for repeatedly, and not built. The reasoning is in
[`AGENT-INTERFACES.md`](AGENT-INTERFACES.md): Force.com Sites is the only thing
in this org that serves a page to an anonymous visitor with no login, which is
the entire requirement, and a single-page app would add a build step and a
hosting dependency without changing one thing a person can do.

If it is wanted for the submission rather than for the user, say so and it gets
built as `clients/react/` against the same `@RemoteAction` endpoints — roughly a
day, honest about being a second front end rather than the front end. That is a
legitimate reason. It is just a different reason, and it should be recorded as
one.

### 7. Reading-level enforcement in CI
Run the agent's own instruction text and canned replies through a Flesch-Kincaid
check and fail the build above grade 8. The system currently *asks* for grade 6
and nothing verifies it.

### 8. Accommodation outcome tracking
`Manager_Response__c` and `Decline_Reason__c` exist and nothing reports on them.
Precedent counts are the one figure the agent refuses to invent — and they would
become real the moment decisions are recorded.

## Requires licensing this org does not have

Stated as roadmap because the metadata is genuinely absent. Verified by query.

| | Why it matters | Blocker |
|---|---|---|
| **Slack** | Where a great many disabled workers already are. An accommodation request that never leaves Slack is one fewer context switch on a hard day. | No Slack metadata types in this org |
| **Data Cloud** | Unify accommodation signals across HR systems without ever holding a diagnosis — the aggregate is useful precisely because the individual record is empty | Types present, licensing unverified |
| **Tableau / CRM Analytics** | Which teams have the most unmet needs, without naming anyone. Aggregate-only by construction. | Essentially absent |
| **Experience Cloud / LWR** | A component-based site with richer interaction | `Network` and `DigitalExperienceConfig` unavailable |
| **Salesforce Messaging (MIAW)** | Native web chat instead of a relay | Digital Engagement not licensed |

## Deliberately rejected

Not backlog. Decisions.

- **Automated sign language.** ASL is a complete language with grammar in hands, face and body. Recognition is unsolved and the products claiming otherwise mostly fingerspell. A person interprets; technology holds the door.
- **A diagnosis field, even encrypted.** Encryption protects data that exists. The stronger control is not to have it.
- **Any phone fallback.** Not for escalation, not for HR, not for "urgent" cases.
- **Inferring anything from behaviour.** No profiling, no scoring, no prediction. Every signal is one the person set in their own words.
- **A reason field on revocation.** There is nowhere to record why someone turned a preference off, so nobody can ever be asked.

## The one that is not a feature

**An accessibility audit by people who need it.** Every claim about screen
readers, keyboard use and contrast on the site was tested by the person who
wrote it. One session with one worker who uses a screen reader daily would be
worth more than the next five items on this list.
