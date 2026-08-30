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

## Next — buildable in this org today

### 1. Image intake on the web  *(spec §3, the fourth modality)*
`ContentVersion` upload from the guest user, attached to the barrier report.
"Here is a photo of my workstation" is often faster and less painful than
describing a chair. Email already accepts image attachments and records the
`Image` modality; the web does not yet.

### 2. Signed-video intake and the interpreter queue
Upload, mark `Interpreter_Needed__c`, acknowledge in text **immediately**, route
to a human. The refusal to machine-translate stays absolute. Today the agent
routes correctly but nothing accepts the upload.

### 3. Standing preferences on the web
`CurbCutStanding` exists, is tested, and is wired to the agent. The web channel
does not expose save/revoke yet, so principle 4 is SMS-only.

### 4. Manager brief as a shareable link
`cost_brief` returns cost, precedent and the interactive-process clock. A manager
should be able to open one page rather than converse. Refusals still apply.

### 5. Reading-level enforcement in CI
Run the agent's own instruction text and canned replies through a Flesch-Kincaid
check and fail the build above grade 8. The system currently *asks* for grade 6
and nothing verifies it.

### 6. Accommodation outcome tracking
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
