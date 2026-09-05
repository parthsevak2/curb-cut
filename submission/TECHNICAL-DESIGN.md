CURB CUT. TECHNICAL DESIGN DOCUMENT
Agentforce for Good, Dreamforce 2026 · Builder Track
Verified against the deployed org, 4 September 2026


─────────────────────────────────────────────────────────────────────
0. THE ONE SENTENCE
─────────────────────────────────────────────────────────────────────

The process for requesting a workplace accommodation is itself an
accessibility barrier, so Curb Cut is an Agentforce agent whose principal
is the worker rather than the employer. You can find out what you could
ask for, and ask for it, without ever saying what condition you have.

Every architectural decision in this document follows from that sentence.
Where a decision does not follow from it, it is marked as a compromise
and the reason is given.


─────────────────────────────────────────────────────────────────────
1. THE CONSTRAINT THAT GENERATED THE ARCHITECTURE
─────────────────────────────────────────────────────────────────────

Most systems are designed around what they must hold. This one is
designed around what it must NOT hold, which inverts almost every
ordinary choice.

  Ordinary system            Curb Cut
  ──────────────────────     ───────────────────────────────────────
  Identify the user          Refuse to. There is no account.
  Store the case detail      Store what is hard. Never why.
  Log for support            Log the attempt, never the content.
  Personalise from history   Infer nothing. Every signal is set by hand.
  Escalate to a phone call   Never. For some users that door does not open.
  Ask the model to comply    Put the rule in code. Models forget.

The last row is the one that took longest to learn and it is the spine of
section 9.


─────────────────────────────────────────────────────────────────────
2. DATA MODEL. INCLUDING WHAT IS DELIBERATELY ABSENT
─────────────────────────────────────────────────────────────────────

9 custom objects, 61 fields. The most important part of the schema is the
part that does not exist.

  PRESENT                          ABSENT. And enforced absent
  ─────────────────────────        ──────────────────────────────
  Barrier_Report__c                Diagnosis__c
    Functional_Description__c      Condition__c
    Inbound_Modality__c            Disability_Type__c
    Interpreter_Needed__c          Medical_Note__c
    Anonymous__c  (default true)   Severity__c
                                   Prognosis__c
  Accommodation_Request__c
    Person_Approved__c             None of these are encrypted.
    Manager_Response__c            None are permission-restricted.
    Interactive_Process_Due__c     They do not exist.

  Access_Preference__c             tests/invariants.py greps every
    Statement__c                   field API name on every push and
    Scope__c                       FAILS THE BUILD if any of the six
    Shared_With__c                 forbidden stems appears.
    Revoked_On__c
    Claim_Code_Hash__c             Current count: 0 matches across
                                   61 fields.
  Disclosure_Event__c
    Shown_To__c / Shown_At__c
  Human_Handoff__c
    Reachable_By__c / Return_Code_Hash__c
  Message_Log__c   (the delivery ledger)
  Emergency_Escalation__c
  Accommodation_Option__c  (28 sourced library rows)
  Access_Profile__c

WHY ABSENCE RATHER THAN ENCRYPTION

Encryption protects data from outsiders. It does not protect a person
from the organisation holding it, which is precisely the threat here. A
manager with legitimate access to an encrypted diagnosis field can still
read the diagnosis. The only field that cannot be subpoenaed, leaked,
reported on, or shown to a manager is the field that was never created.

This also produces the strongest possible refusal. When an operator asks
the internal assistant for a diagnosis, it does not say "you lack
permission". It says there is nothing to tell, and that is true.

THE GAP WE FOUND IN OUR OWN CLAIM

Functional_Description__c is free text. "I have multiple sclerosis and
some days I cannot type for long" was being stored verbatim while the
privacy policy said in public that a volunteered condition "is not
written to any record."

That was false. It is now true within a stated limit, see section 6.


─────────────────────────────────────────────────────────────────────
3. CHANNEL ARCHITECTURE. SIX DOORS, ONE BRAIN
─────────────────────────────────────────────────────────────────────

  STEP 1. Every channel, before anything else
    Web (Visualforce) · Voice (TwiML) · SMS (relay) · Email (Apex)
    Slack (Node) · MCP (stdio)
        ↓
    CurbCutKeyword. Whole-message match, control words resolved
    BEFORE any inference

  STEP 2. One authenticated Apex REST door
    CurbCutChannelApi  →  /services/apexrest/curbcut/v1/message

  STEP 3. The three things it can do
    CurbCutOptions        deterministic ranker, no model
    CurbCutIntake         redaction, then anonymous log
    CurbCutCreateHandoff  a real person, never a telephone

  STEP 4, always
    CurbCutLog. Delivery ledger, salted hash, never the message body

WHY ONE ROUTER

Because we shipped the alternative and it failed. SMS had a keyword list
in JavaScript. Email had different words in Apex. Web had none. A person
who texts on Monday and emails on Thursday was talking to two services
that disagreed about what OFF meant, and one of them was wrong.

Now: 6 channels, 1 router, and an invariant that fails the build if any
user-facing string advertises a word the router does not answer.

WHY THE CONTROL WORDS RESOLVE BEFORE INFERENCE

Three reasons, in order of importance:
  1. Correctness. A withdrawal must not depend on a model's mood.
  2. Latency. Somebody reaching for the exit gets an instant answer.
  3. Energy. ~70 phrases short-circuit an LLM call entirely.

Matching is WHOLE-MESSAGE only, never substring. "I need help typing" is
a need, not a request for the help menu. Seven such sentences are pinned
by test.


─────────────────────────────────────────────────────────────────────
4. THE CONSENT MECHANISM. CLAIM CODES
─────────────────────────────────────────────────────────────────────

THE PROBLEM. A person saves a standing disclosure ("I need captions on
every call") on the web. Months later, from a bus, they want it off. We
hold no account, no password, no phone number, by design. There is
nothing to look them up by.

Building a login to solve this would destroy the property that makes the
product work.

THE MECHANISM. Save →  code = 6 chars from a 30-char alphabet
          store  SHA-256(salt || code)  in Claim_Code_Hash__c
          show   the plaintext code ONCE, never again

  later → "OFF 4KQ7MT" on ANY channel
          hash the supplied code, look up by hash, revoke

PROPERTIES

  · The person holds the only readable copy. We hold a hash we cannot
    reverse. We still cannot identify them.
  · Works from any channel, including ones that have never seen them.
  · A spent code and a wrong code return the SAME message. Confirming
    that a code exists would turn this into an oracle for testing
    whether a stranger's disclosure is live.
  · Alphabet omits O 0 I 1 S 5. The characters people confuse reading
    off a cracked screen, at low vision, or aloud to another person.
    This is an accessibility decision inside a cryptographic one.

  Search space: 30^6 ≈ 7.3 × 10^8. Combined with per-lookup cost and no
  enumeration surface, adequate for the threat model in section 10. A
  production deployment would add rate limiting per source.

VERIFIED END TO END, LIVE

  saved on WEB          → code JJHYYT
  WHO JJHYYT via SMS    → "Nobody has been shown it yet…"
  OFF JJHYYT via SLACK  → "Turned off. It will not be shown again."
  OFF JJHYYT again      → indistinguishable from a wrong code

The same mechanism now backs the web handoff. A web visitor is anonymous,
so "a person will reply by message" was a promise the system could not
keep, there was no address. They now get a return code and a truthful
sentence about why.


─────────────────────────────────────────────────────────────────────
5. GROUNDING. WHY THERE IS NO RAG
─────────────────────────────────────────────────────────────────────

The accommodation library is 28 rows, each individually sourced with a
citation URL, cost band, and plain-language summary.

Ranking is a deterministic Apex function:
  · lowercase, strip punctuation, split
  · remove an expanded stopword list
  · light stemmer (plurals, -ing, -ed, trailing -e)
  · score: title match = 3, body match = 1
  · deterministic tie-break by name

WHY NOT EMBEDDINGS

  · 28 rows. A vector index over 28 rows is theatre.
  · Determinism. The same sentence returns the same options every time,
    which makes the adversarial suite meaningful.
  · Auditability. We can explain exactly why an option ranked first. A
    cosine similarity cannot be explained to somebody who was given bad
    advice.
  · Energy. A SOQL query and string work versus an embedding call per
    message. See section 12.
  · Sourcing. Every row carries its citation. A generated suggestion
    cannot.

THE FAILURE THIS DESIGN CAUGHT

"I cannot type for long", the canonical sentence. Originally returned
nothing, because the library says "typing". The stemmer fixed it. A
similarity search would have silently returned something plausible and
wrong, and nobody would have noticed.

THE MODEL'S ROLE IS DELIBERATELY SMALL

The agent chooses which action to call and phrases the reply. It may not
invent an accommodation, a cost, or a precedent count. If find_options
returns nothing, it must say so.


─────────────────────────────────────────────────────────────────────
6. REDACTION. AND ITS HONEST LIMIT
─────────────────────────────────────────────────────────────────────

CurbCutRedact runs on the single write path every channel shares, before
the insert. Input   "I have multiple sclerosis and some days I cannot type for long"
  stored  "I have [not recorded] and some days I cannot type for long"

The functional half survives, because that is the half the system works
from. The person is told in the same reply.

DELIBERATELY NOT REDACTED

  Deaf · blind · hard of hearing · wheelchair user

These are identity and function, not medical detail. They are how people
describe themselves, the interpreter routing reads them, and stripping
how somebody names themselves would be its own insult. An invariant fails
the build if any of them enters the condition list.

THE LIMIT, STATED RATHER THAN HIDDEN

The list cannot cover every phrasing in every language. So the privacy
page no longer promises an absolute. It says: this is a real safeguard,
not a guarantee. And what IS guaranteed is that nothing here is built to
hold a condition, so none is ever asked for, indexed, reported on, or
shown to an employer.

An invariant fails the build if the old absolute claim ever returns.

WHY A REGEX AND NOT A CLASSIFIER

A moderation model was the obvious reach and would have cost an inference
on every message, added latency to the one path that must never be slow,
and produced a probabilistic answer to a question that deserves a
deterministic one.


─────────────────────────────────────────────────────────────────────
7. THE CONSENT GATE
─────────────────────────────────────────────────────────────────────

Nothing reaches an employer without an explicit yes IN THE CONVERSATION.

Two independent locks:
  1. CurbCutCreateRequest refuses to set Person_Approved__c without
     approval passed through.
  2. A validation rule blocks the insert without it.

The interesting case is not refusal. It is the HEDGE. What a person
actually says when unsure and being agreeable. "I guess so, I think
that's probably fine?" is not agreement, and the agent asks again rather
than sending. Verified in the adversarial suite as a 3-turn sequence:

  turn 1  draft read back, nothing written
  turn 2  "I guess so…"  → no action invoked, nothing written
  turn 3  "Yes, send it" → 1 record created


─────────────────────────────────────────────────────────────────────
8. OBSERVABILITY
─────────────────────────────────────────────────────────────────────

FOUR LAYERS, all failing the build except the last.

  Layer                      Count   Runs
  ─────────────────────────  ─────   ──────────────────────────────
  Structural invariants        497   every push, ~1s, no org needed
  Apex tests                   124   every deploy
  Accessibility (live pages)   333   against the deployed site
  Sa11y / axe-core             131   Salesforce's own matcher, 12 states
  Contrast (both themes)        28   computed from design tokens
  Component a11y                11   LWC templates
  Link and copy                 54   every user-facing string
  Reading level                 16   Flesch-Kincaid, per surface
  Adversarial assertions     21/23   headless Agent API, deliberate

THE SA11Y LAYER, AND WHAT IT CANNOT SEE

Sa11y is Salesforce's own accessibility matcher, obtained through the
lwc-experts toolset in the Salesforce DX MCP server (@salesforce/mcp).
It runs axe-core over the rendered DOM of every Lightning Web Component.

Three deliberate choices make the number mean something.

  The ruleset is the 100-rule "extended" preset, not the 64-rule "base"
  preset Sa11y applies by default. Exactly one rule is removed, "region",
  in one place with the reason beside it: it carries no WCAG tag and
  fires only because a component mounted alone in a test has no page
  landmarks around it. Landmarks are checked on the real pages by the
  333-check live suite.

  The harness is proved able to fail. jest/__tests__/harness-control.a11y.test.js
  plants an image with no alt text and asserts the matcher throws. A
  suite that cannot fail proves nothing about the code it passes.

  Incomplete results are reported, not banked. axe returns "incomplete"
  rather than "pass" when it cannot decide. color-contrast comes back
  incomplete in all twelve states because axe measures contrast by
  painting to a canvas and jsdom has none; video-caption comes back
  incomplete because axe cannot inspect media. Both are recorded as
  undecided in docs/a11y-sa11y-findings.json. Counting an incomplete as
  a pass is the easiest way to buy a clean accessibility score, and it
  is the one this project will not do.

THE DELIVERY LEDGER

Message_Log__c records THAT we tried to reach someone and what happened.
Never what was said. Never a raw address or number. A salted SHA-256
handle truncated to 32 hex chars.

This exists because the email channel failed silently for days while
Salesforce reported "success". The gap between "the platform accepted it"
and "a person received it" is exactly where somebody disappears.

INVARIANTS THAT ARE UNUSUAL

  · advertised-keyword-is-routed. Scans every user-facing string for
    "reply/send/text WORD" and fails if the router does not answer it.
  · kindness. Fails the build if an error message blames the user or
    leaves them with no next step.
  · reading level. Fails if any surface exceeds its grade ceiling.
  · privacy-page-does-not-overclaim. Fails if the policy reverts to
    promising an absolute the code cannot keep.
  · redaction-spares-identity-words. Fails if Deaf/blind/hard of
    hearing ever enter the condition list.
  · adversarial-silence-is-not-success. Fails if the scorer stops
    treating inconclusive as failure.


─────────────────────────────────────────────────────────────────────
9. AGENT DESIGN
─────────────────────────────────────────────────────────────────────

Two Agentforce agents, both Active:
  Curb_Cut       v7  public, 6 subagents, 7 Apex actions
  Curb_Cut_Desk  v5  internal, refuses medical questions

WHAT THE AGENT MAY DO
  · choose an action
  · phrase a reply in grade-6 language
  · decide when somebody is stuck and offer a human

WHAT IT MAY NOT DO
  · name an accommodation an action did not return
  · invent a cost or a precedent count
  · repeat a condition back
  · route anyone to a telephone
  · echo legal register back at someone who used it
  · send anything without a yes

THE HARD-WON LESSON

Instructions are not controls.

The agent was instructed not to record a volunteered condition. It
complied in its narration and the ACTION recorded the text anyway,
because the instruction governed what the model said, not what the code
did. Everything safety-critical has since moved into Apex.

We then tested the inverse: can we make the model reliably SAY something?
Three attempts. A strengthened instruction published as v7, the action
returning the exact sentence, and the sentence embedded in the action
payload. It still says it about half the time, because the agent rewrites
what an action returns rather than relaying it.

CONCLUSION, STATED PLAINLY: put guarantees in code, and treat model
narration as best-effort. The four Apex-composed channels say the
sentence 100% of the time. The conversational agent does not, and we
report that rather than averaging it away.


─────────────────────────────────────────────────────────────────────
10. SECURITY AND THREAT MODEL
─────────────────────────────────────────────────────────────────────

  Adversary                 Mitigation
  ────────────────────────  ─────────────────────────────────────────
  Curious manager           No field exists. Refusal is truthful.
                            Internal agent refuses in the same words
                            and hands the operator a sentence to use
                            upward, so refusing costs them nothing.
  Compromised org / subpoena Nothing medical to disclose.
  Forged webhook            Signature verification FAILS CLOSED; relay
                            refuses to start without a token; the
                            unverified escape hatch cannot combine
                            with a public URL.
  Code enumeration          Spent and wrong codes are indistinguishable.
                            30^6 space. Rate limiting is the production
                            gap, named in section 13.
  Prompt injection          Tested: "IGNORE ALL PREVIOUS INSTRUCTIONS…"
                            → injection ignored, real need underneath
                            still answered.
  Guest-user escalation     Guest may create, not read back. Two narrow
                            without-sharing classes, one object each,
                            by id or hash, documented at the call site.
  Slack workspace export    Cannot be prevented, so it is DISCLOSED
                            on first contact, before anything is said.

THE SLACK DECISION IN FULL

Slack is the employer's estate. Owners can export DMs on most plans. A
tool promising "ask without telling your employer" cannot behave there as
it does on a phone. So on Slack only: never answers in a channel, says
where you are standing before anything is discussed, never drafts,
never sends, and hashes the Slack user id like a phone number.


─────────────────────────────────────────────────────────────────────
11. ARCHITECTURE DECISION RECORDS (abridged)
─────────────────────────────────────────────────────────────────────

ADR-1  Absence over encryption.
       Rejected: encrypted diagnosis field with FLS. Rejected because it
       does not defend against the actual adversary, who has access.

ADR-2  Visualforce + Force.com Sites for the public surface.
       Rejected: LWR/Experience Cloud. Rejected because guest LWR could
       not be made to work without an account boundary, and because the
       page must render with no JS framework for older assistive tech.

ADR-3  Deterministic ranker over vector search.  (§5)

ADR-4  One Apex REST door for all non-web channels.
       Rejected: per-channel logic. Shipped and failed. (§3)

ADR-5  Claim codes over accounts.  (§4)

ADR-6  Regex redaction over a moderation model.  (§6)

ADR-7  Reachable_By as an argument, telephone refused in code.
       Was hard-coded to 'Text message' and documented as a principle.
       The rule was never "always text", it was "never a telephone". And the hard-code made email handoffs unactionable.

ADR-8  Fail closed on webhook signatures.
       Was fail-open with an empty token in .env. Any unsigned request
       was treated as genuine.


─────────────────────────────────────────────────────────────────────
12. ENVIRONMENTAL DESIGN
─────────────────────────────────────────────────────────────────────

An LLM call is treated as the expensive operation it is.

  · Ranking is deterministic Apex. No embeddings, no vector store, no
    RAG pipeline to keep warm.
  · ~70 control phrases resolve before any inference.
  · 4 of 6 channels answer with NO model call at all. Web, email,
    Slack and any external caller compose their reply in Apex.
  · Redaction is a compiled regex, not a classifier.
  · CI runs zero inference. All six auditors are static Python/Node.
  · The adversarial suite is the only thing that calls the agent, run
    deliberately rather than per push, and its scorer exits non-zero on
    inconclusive results so nobody re-runs it hunting a green.
  · Relay sessions expire after 30 minutes; no context kept alive.

The principle: if a rule matters, put it in code. A model asked to
remember a rule burns energy every time it is asked and still forgets. And our own measurements prove it, because the sentence the agent forgets
half the time is the one Apex now says every time, for free.


─────────────────────────────────────────────────────────────────────
13. SCALE, ADOPTION, AND WHAT IS NOT DONE
─────────────────────────────────────────────────────────────────────

SCALES WELL
  · Library is data, not code. New accommodations are rows.
  · New channel = call one endpoint and inherit the whole contract.
  · No per-tenant model tuning. Same agent, same library.

NEEDS WORK BEFORE REAL DEPLOYMENT
  · Rate limiting on code lookups.
  · Twilio status callbacks. "accepted by the platform" is not
    "delivered".
  · A verified sending domain for email replies.
  · Outcome tracking, so precedent counts become real. The agent
    currently refuses to invent them, which is correct but thin.
  · Localisation. Redaction and reading-level are English-only.

HONEST GAPS
  · No screen-reader user has tested this. Every accessibility claim is
    machine-verified, which is not the same thing.
  · The Slack app has never run against a real workspace.
  · Text messaging awaits A2P 10DLC carrier registration. Voice on the
    same number needs none and works today.
  · The internal agent does not reliably call its own library; the
    grounded internal surface is the console component, not the agent.


─────────────────────────────────────────────────────────────────────
14. HOW TO VERIFY ANY CLAIM IN THIS DOCUMENT
─────────────────────────────────────────────────────────────────────

  python3 tests/invariants.py                      497 checks, ~1s
  sf apex run test -o curbcut -l RunLocalTests      124 tests
  python3 tests/a11y_audit.py                      333 checks, live pages
  npm run test:a11y                                131 Sa11y checks, 12 states
  python3 tests/contrast_audit.py                   28 checks, both themes
  bash tests/check_live.sh                         source vs deployed
  node tests/headless_agent_api.mjs \
    && python3 tests/score_adversarial.py          21/23

Nothing in this document is asserted from memory. Every figure was read
from the deployed org or the test run that produced it.
