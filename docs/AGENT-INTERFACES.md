# Agent interfaces

Curb Cut is reachable four ways by a person and two ways by a machine. This
file covers the machine surfaces, what each deliberately cannot do, and one
thing that is not built on purpose.

The rule running through all of it: **a capability reachable by another model
must never be able to disclose anything about a person.** A model can be talked
into calling a tool. It cannot be talked into calling one that does not exist,
so the surfaces below are shaped by subtraction.

---

## 1. Headless agent invocation

The agent runs with no user interface at all. `channels/sms-relay.mjs` creates a
`ProductionAgent` session per hashed handle and drives it over the Agent API;
Twilio POSTs a webhook and gets TwiML back. Nothing in that path renders a page,
and the reply needs no Twilio credentials because TwiML is the response body.

```
person → carrier → Twilio → POST /sms → ProductionAgent.preview.send() → TwiML → carrier → person
```

The same code path serves voice, with speech in and speech out, and the same
agent answers. `tests/headless_agent_api.mjs` drives it without any channel at
all, which is how the adversarial suite is scored.

Sessions expire after 30 minutes so a shared phone never inherits somebody
else's conversation.

## 2. Model Context Protocol server

`channels/mcp-server.mjs`. Zero dependencies, JSON-RPC 2.0 over stdio, both
Content-Length framing and newline-delimited JSON so it can be driven from a
shell for testing.

```bash
node channels/mcp-server.mjs
```

Or as a client config entry:

```json
{ "mcpServers": { "curb-cut": { "command": "node",
  "args": ["channels/mcp-server.mjs"], "env": { "SF_ORG_ALIAS": "curbcut" } } } }
```

**Why this exists.** The argument on `/curbcut/why` is that the employer's side
of the conversation is automated and the person's side is not. Building one
agent only half answers that, because it still requires the person to come to
us. Somebody who already lives inside another assistant should be able to ask
"what could I even ask for at work" there, and get a sourced answer.

### The three tools

| Tool | Does | Cannot |
|---|---|---|
| `curbcut_find_options` | Grounded lookup against the sourced library, ranked by name over summary, stemmed so "type" finds "typing" | Return anything not in the library; state a cost that is not published |
| `curbcut_cost_brief` | The JAN evidence with its sample, its denominator and its caveat | Round the caveat off |
| `curbcut_draft_request` | Draft the ask in the person's words | Send it |

### What is deliberately absent

- **There is no send tool.** Not a gated one, not an admin one. Sending requires
  an explicit yes from the person in a conversation they are present for, and a
  tool call made by a model is not that. Without this, a prompt-injected client
  could file an accommodation request in someone's name — a disclosure they did
  not make and cannot take back. An invariant fails the build if a tool name
  ever contains `send`, `submit`, `file_`, `notify` or `email`.
- **There is no tool that accepts a diagnosis.** Input matching
  `diagnos|condition|disabilit|medical|severity|prognos` is refused with an
  explanation, and the refusal says the information was not stored because there
  is nowhere to store it.
- **Cost is stated only when published.** A placeholder zero in the library once
  made this surface answer "typically about $0, once" for a booked ASL
  interpreter. Somebody could have repeated that to their employer and lost the
  argument on a number we invented. Nine library rows were corrected, and both
  an invariant and an Apex test now hold the line.

## 2b. The internal agent, and what is honestly wrong with it

`Curb_Cut_Desk` is a second Agentforce agent, active in the org, sharing the
public agent's grounded library and its refusals but pointed at staff.

**What is verified working.** It refuses to tell a member of staff anything
medical about a person, including when the asker says they are a manager or that
it is urgent. It refuses to name an accommodation from its own knowledge — an
earlier version answered "on-screen keyboards, a scribe, suppliers", none of
which are in the library, and that is fixed. It gives correct guidance on never
routing somebody to a telephone, including the sentence to use with a manager.

Those two refusals are the properties that matter, and they hold.

**What is not working, stated plainly.**

1. Asked what to offer, it says it will check the library and then asks
   permission rather than calling the action. It does not invent, which is the
   safe failure, but it does not finish the job either.
2. One route errors and returns the agent's configured error message.

Five rounds of narrowing the routing rules, labelling the subagents, and
removing an action gate that could never open did not move either behaviour. I
was wrong about the gate being the cause. Rather than keep tuning prompts
through a ten-step publish loop, the state is recorded here so nobody
demonstrates a path that does not work.

**So the grounded internal surface is the component, not the agent.**
`CurbCutAssist` on the handoff record calls `CurbCutOptions` directly, is
deterministic, has ten tests on it, and provably cannot hallucinate about a
disabled person. The agent is live and supplementary until the two behaviours
above are fixed.

## 3. Agent-to-agent handover

`CurbCutHandover.payloadFor(requestId)`, also invocable from a flow.

An accommodation request eventually leaves this system and reaches something on
the employer's side, and increasingly that something is another agent. Handover
is where privacy promises usually die quietly, because serialising everything is
easier than deciding what to send.

The payload is an **allow-list**, not a filter, so a field added to the schema
next year cannot leak by default. The failure mode of a deny-list is silence;
the failure mode of an allow-list is a missing field somebody notices.

```json
{
  "contract": "curb-cut/handover",
  "contract_version": "1.0.0",
  "reference": "AR-00007",
  "what_is_hard": "Typing hurts after a while",
  "consent": {
    "given_by": "the person this is about",
    "given_at": "2026-08-30 16:19:10",
    "mechanism": "explicit yes in the conversation; a hedge was not accepted",
    "revocable": true
  },
  "timing": { "interactive_process_due": "2026-09-09", "status": "Pending" },
  "reply_on": { "channel": "Text", "interpreter_needed": false, "never_by_telephone": true },
  "absent": { "diagnosis": "no such field exists in this system", "...": "..." },
  "must_not_ask": [
    "Do not ask this person, or anyone, for a diagnosis or medical documentation in order to process this request.",
    "Do not treat the absence of medical detail as an incomplete submission.",
    "Do not reply by telephone. Reply on the channel named in reply_on."
  ]
}
```

Three things make this different from a normal integration payload.

1. **It refuses without consent.** Not "omits a flag" — refuses to produce
   anything. Consent is enforced twice: a validation rule means an unapproved
   request cannot exist in the database at all, and the builder checks again.
   A test proves the first layer makes the second unreachable, which is what
   defence in depth is supposed to look like.
2. **It carries an `absent` block.** An agent that does not know something will
   ask. Saying plainly that these fields do not exist anywhere is the only way
   to stop a follow-up question that the person would then have to field.
3. **It carries `must_not_ask`.** This is an instruction to the recipient, not a
   description of us. We cannot enforce it. We can refuse to be the reason
   nobody said it.

It also refuses to send an empty request. Spending someone's ask on a payload
with none of their words in it is worse than sending nothing.

## 4. The web front door, and why it is not React

`/curbcut/ask` is Visualforce with `@RemoteAction`. Force.com Sites is the only
mechanism in this org that serves a page to an anonymous visitor with no login,
which is the entire requirement — a person without a work account has to be able
to use this. Experience Cloud and LWR both wanted a login story we do not want,
and a React SPA would add a build step and a hosting dependency without changing
one thing a person can do on the page. The reasoning is in
[`DECISIONS.md`](DECISIONS.md).

Where React would genuinely help is an employer-side console, and that is not
what is short in this problem. The headless expansion that matters is the MCP
server above: it puts the library where people already are, rather than building
a nicer version of asking them to come here.

## 5. Data Cloud, and the profile we will not build

The honest answer, stated as a design position rather than a gap.

**What belongs in a unified data layer:** the accommodation library, which is
public reference data with a source URL on every row; and channel telemetry from
`Message_Log__c`, which holds a salted hash, no content and no address, and
exists so that a channel failing silently gets noticed.

**What does not, ever:** a unified profile of a disabled person. A Customer
360-style identity graph that resolves someone across SMS, email, web and voice
into one durable profile is precisely the artifact this system is built to make
impossible. Conversations are anonymous by default; the handle is a salted hash;
`Person_Handle__c` is documented as "never the raw number". Identity resolution
would undo all of it in a single well-intentioned pipeline.

The place where a disability data lake gets built is never the place where
somebody decided to harm disabled people. It is the place where somebody wanted
a dashboard. This project would rather have a worse dashboard.
