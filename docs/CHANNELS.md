# Channels

Four front doors, one library, one set of rules. This page exists because for
most of this project's life that sentence was not true.

## What was wrong

Every channel printed the same promises in its copy. None of them routed the
words those promises named.

| Somebody sent | What they wanted | What they actually got |
|---|---|---|
| `HUMAN` | a real person | "ASL interpreter booked in advance" |
| `PERSON` | a real person | "Face the person when speaking" |
| `OFF` | withdraw a disclosure | "I do not have good information on that". And the sharing stayed on |
| `WHO` | who has seen it | the same dead end |
| `CURB CUT` | the poster opt-in, the first thing anyone ever sends | fed to the library as if it described a barrier |

Six words, advertised across three channels, none routed. Every one of them
passed the full test suite, because nothing checked that a promise made in a
string was kept by a router.

The worst of these is `OFF`. It is the word that withdraws a standing
disclosure. Somebody taking back what their employer can see was told the
system did not understand them, and the disclosure remained live. For a product
whose entire thesis is consent, a withdrawal that silently fails is the most
serious defect it could have had.

## What routes now

`CurbCutKeyword` is the only place these rules live. Every channel asks it
before anything else, so the words mean the same thing whichever door somebody
came in by.

| Word | Does | Needs a code |
|---|---|---|
| `HUMAN` `PERSON` `SOMEONE` and 30-odd natural variants | creates a real handoff to a named handler, on the channel they are already using | no |
| `OFF` | turns off a standing disclosure, immediately, no reason asked | yes |
| `WHO` | lists everyone who has been shown it | yes |
| `HELP` `CURB CUT` | says what this is and how to get a person | no |
| `STOP` `START` | carrier-reserved; answered by the relay, never by the agent | no |

Matching is whole-message only. "I need help typing" is a need, not a request
for the help menu, and a test asserts that seven such sentences still reach the
library untouched.

`YES`, `CHANGE` and `DELETE` are deliberately *not* here. They only mean
anything while a draft is on the table, so the agent owns them. If the router
claimed `YES`, somebody agreeing to send their request would instead be
resubscribed to text messages.

## The code

`OFF` and `WHO` need to know which preference. On the web the page holds an id.
On a phone we hold nothing, no name, no number, no account, by design.

So when somebody saves a standing preference they are given a six-character
code, shown once. We keep a salted hash; they keep the code. It is the only
readable copy, and it is what lets a person turn off a disclosure from a text
message on a channel where we genuinely cannot look them up.

Codes avoid `O` `0` `I` `1` `S` `5`. The characters people confuse when
reading them off a cracked screen, at low vision, or aloud to somebody else.

A wrong code and an already-spent code return **the same** answer. Confirming
that a code exists would turn this into a way to test whether somebody else's
code is live.

The same mechanism now backs the web handoff. A web visitor is anonymous, so
the old message. "a person is picking this up, they will reply by message", was a promise the system could not keep: there was no address to reply to. They
now get a code and a truthful sentence about why.

## Parity

| | Web | SMS | Voice | Email | Slack | MCP |
|---|---|---|---|---|---|---|
| Grounded library | yes | yes | yes | yes | yes | yes |
| Control words | yes | yes | yes, spoken | yes | yes | `reach_human` |
| Draft a request | yes | yes | not verified | no | no | yes |
| Send a request | yes | yes | not verified | no | no | never |
| Photo / signed video | yes | no | no | photo | no | no |
| Delivery ledger | yes | yes | yes | yes | yes | via Apex |
| Works with no account | yes | yes | yes | yes | no | n/a |

Email and Slack deliberately do not send. Agreeing to something in writing days
later is not the same as choosing it in the moment, so the send button stays
where the person can see exactly what it will do.

## Voice

For most of this project's life the voice column above was blank, and the
blank was hiding a bug. `/voice` handed every transcript to the agent. `/sms`
asked the router first. So "one set of words on every door" was true for text
and false for the one door that works today without carrier registration. A
caller who said "human" got a model. A caller who said "off" was told there
was no good information on that, and the sharing stayed on.

Now the relay normalises speech the same way it normalises a text. It asks
the same Apex router before the agent hears anything:

- A whole-message control word (`human`, `off`, `who` and the same variants
  as text) goes to `/curbcut/v1/message` with `channel: Voice`. The router's
  wording is read back aloud, so the answer is identical to text and email.
- A code said letter by letter, "off 4 K Q 7 M T", is put back together
  before it goes to the router. Only letters from the code alphabet count, so
  "who can see" is still a control phrase and never mistaken for a code.
- Five crisis phrases (`kill myself`, `suicid`, `end my life`, `want to die`,
  `hurt myself`) match as substrings, not whole messages. They go to the
  router as a request for a person, so a real handoff exists before anything
  else is said. A language model is the wrong thing to answer these.

Everything else still goes to the agent, exactly as before.

What voice still cannot do, said plainly:

- Nobody can be called back. We hold no number, and a call is refused by
  `CurbCutCreateHandoff` in code. So after a handoff the relay adds one honest
  sentence: nobody will ring you, and to hear from the handler you have to
  write in. The router's own wording still promises a reply "on this same
  channel", because `CurbCutChannelApi.REPLY_ON` does not yet know `Voice`
  and treats it as `External`, which means text message. That is a known gap
  in the Apex, not in the relay.
- We have no crisis line to offer on a call, and we do not pretend to. A
  crisis phrase gets a person, not a hotline number, because this product
  never routes anyone to a telephone. Whether to speak a text-based crisis
  service is a decision the team has not made yet.
- Codes read aloud are only as good as the speech recogniser. "Four kay
  queue" is not rebuilt; only single letters and digits are. We have not
  tested this on a live call.
- No photo, no signed video. Speech in, speech out, nothing else.
- `STOP` and `HELP` are carrier words for text, and the relay answers them
  itself on text because the carrier requires it. On a call they are treated
  the same way, by the relay, and never reach the router. That is deliberate:
  the carrier words belong to the carrier, on every channel.
- None of the above has been exercised on the live number since it was
  written. The code is syntax-checked and the router lane is asserted by an
  invariant, and that is the whole of the evidence.

## Slack is the employer's estate

Slack is the easiest channel to reach for and the least private one we have.
Workspace owners can export direct messages on most plans. A tool whose promise
is "ask without telling your employer anything" cannot behave there the way it
behaves on a phone.

So on Slack, and only on Slack:

1. It never answers in a channel, not in a thread, not ephemerally. Asking
   about accommodations in `#general` is a disclosure to everyone scrolling.
   In a channel it says one thing: come to a DM.
2. On first contact it says out loud that Slack belongs to the employer, and
   names the two channels that do not, *before* anything else is discussed.
3. It never drafts and never sends. Read-only help; the send button lives on the
   web, where the person is anonymous.
4. The Slack user id is hashed before it reaches the ledger, exactly like a
   phone number.

## Running them

```bash
node channels/sms-relay.mjs     # SMS + voice, TwiML
node channels/slack-app.mjs     # Slack, DM only
node channels/mcp-server.mjs    # MCP over stdio
```

Slack needs `SLACK_SIGNING_SECRET` and `SLACK_BOT_TOKEN`; both are read from the
environment and neither is committed. Every request is signature-checked with a
five-minute replay window before the body is parsed.

## The guard

Five invariants now fail the build:

- `advertised-keyword-is-routed`. Scans every user-facing string in Apex, the
  Visualforce pages and the channel scripts for "reply/send/text WORD", and
  fails if `CurbCutKeyword` does not route it. This is the check that would
  have caught all six original bugs on the day they were written.
- `relay-control-words-cover-apex`. The relay mirrors the word list so it can
  answer without a round trip; two lists that disagree is how this broke.
- `control-word-not-carrier-reserved`, nothing of ours may claim `STOP`.
- `handoff-refuses-telephone`. A phone call is refused in code, not merely
  discouraged in a comment.
- `voice-uses-the-shared-router`. Looks inside the `/voice` handler alone and
  fails unless it checks `CONTROL_WORDS` and asks `/curbcut/v1/message`. The
  text path already did both, so a check over the whole file would have passed
  while voice was still wrong.
