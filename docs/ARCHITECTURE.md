# Architecture

## The shape of it

```mermaid
flowchart LR
  subgraph People
    P1["Person<br/>phone"]
    P2["Person<br/>no phone"]
    P3["Person<br/>email only"]
    M["Manager"]
  end

  subgraph Channels
    SMS["SMS<br/>Twilio"]
    VOICE["Voice<br/>Twilio, speech in/out"]
    WEB["Web<br/>/curbcut/ask"]
    EMAIL["Email<br/>inbound service"]
  end

  subgraph Brain
    AGENT["Agentforce agent<br/>6 subagents, Agent Script"]
    DET["Deterministic path<br/>no model in the loop"]
  end

  subgraph Actions["Apex actions"]
    A1["find_options"]
    A2["log_barrier"]
    A3["draft_request"]
    A4["create_request"]
    A5["create_handoff"]
    A6["standing_preference"]
    A7["cost_brief"]
  end

  subgraph Data
    LIB[("Accommodation_Option__c<br/>28 rows, every row cited")]
    BR[("Barrier_Report__c<br/>what is hard, never why")]
    AR[("Accommodation_Request__c<br/>only on explicit approval")]
    PREF[("Access_Preference__c")]
    DISC[("Disclosure_Event__c<br/>who saw what, when")]
    HH[("Human_Handoff__c<br/>message only, never phone")]
  end

  P1 --> SMS --> AGENT
  P1 --> VOICE --> AGENT
  P2 --> WEB --> DET
  P3 --> EMAIL --> DET
  M --> AGENT

  AGENT --> A1 & A2 & A3 & A4 & A5 & A6 & A7
  DET --> A1 & A2 & A3 & A4 & A5

  A1 --> LIB
  A2 --> BR
  A3 -.->|writes nothing| AR
  A4 --> AR
  A5 --> HH
  A6 --> PREF & DISC
  A7 --> LIB
```

**The web and email channels deliberately bypass the model.** They call exactly
the same Apex actions the agent calls, in the same order, against the same
library. For the highest-stakes step, creating a request. There is nothing to
hallucinate, and the approval gate is code rather than judgement. Someone on a
library computer gets the *safest* version of the system, not the flakiest.

## The approval gate

The claim the whole project rests on. Three independent locks:

```mermaid
sequenceDiagram
  participant Person
  participant Agent
  participant Apex as CurbCutCreateRequest
  participant Rule as Requires_Person_Approval
  participant DB

  Person->>Agent: I want captions in all my meetings
  Agent->>Apex: draft_request
  Apex-->>Agent: draft text (writes nothing)
  Agent-->>Person: reads the draft back
  Person->>Agent: "I guess so, probably fine?"
  Note over Agent: LOCK 1. The model judges<br/>a hedge is not a yes
  Agent-->>Person: I want to be sure before sending anything
  Person->>Agent: Yes, send it
  Agent->>Apex: create_request(approved = true)
  Note over Apex: LOCK 2. Refuses unless<br/>approval passed through
  Apex->>Rule: insert
  Note over Rule: LOCK 3. Validation rule blocks<br/>insert without Person_Approved__c
  Rule->>DB: 1 record
  DB-->>Person: Sent. You will hear back by 9 Sep.
```

Verified against the database, not the prose: **exactly one record, created on
the genuine yes and not on the hedge**, reproducible across runs.

## The absence

```mermaid
flowchart TB
  subgraph Exists["Recorded"]
    E1["What is hard<br/>functional description"]
    E2["Hashed phone number<br/>raw number never stored"]
    E3["Preferences, in their words"]
    E4["Disclosure ledger"]
  end
  subgraph Absent["No field exists"]
    X1["Diagnosis"]
    X2["Condition"]
    X3["Disability type"]
    X4["Medical note"]
    X5["Severity"]
    X6["Prognosis"]
  end
  CI["tests/invariants.py<br/>fails the build if one is added"] -.enforces.-> Absent
```

A manager who asks is refused. Not because the agent is discreet, but because
there is nothing to tell them.

## Platform constraints, honestly

Established by querying the org, not assumed:

| Capability | State | Consequence |
|---|---|---|
| `Network`, `ExperienceBundle`, `DigitalExperienceConfig` | **not available** | Experience Cloud and LWR cannot exist here. Force.com Sites + Visualforce is the only public-site mechanism. |
| `LightningComponentBundle` | available | LWC is the upgrade path if Digital Experiences is ever licensed. |
| `EmailServicesFunction` | available | email channel built. |
| `CustomSite`, `ApexPage`, `StaticResource` | available | the site as it stands. |
| Slack metadata | **none** | Slack cannot be built in this org. Roadmap only. |
| Tableau | essentially absent | roadmap only. |
| Data Cloud types | present, licensing unverified | roadmap only. |

Visualforce was not a preference. It was the only mechanism available.

## Guest-user security

The site guest user is the most exposed identity in the system.

- Holds **read and create only**. The platform maximum for a guest, and enforced by a CI invariant.
- Holds **no View All** on anything.
- Has **no access at all** to `Access_Profile__c` or `Disclosure_Event__c`, it can never see anything about a person.
- Reads the public library through a narrow `without sharing` class that touches one object containing no personal information, with field-level security still enforced.
