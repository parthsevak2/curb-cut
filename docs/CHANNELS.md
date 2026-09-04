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
| Control words | yes | yes |. | yes | yes | `reach_human` |
| Draft a request | yes | yes |. | no | no | yes |
| Send a request | yes | yes |. | no | no | never |
| Photo / signed video | yes |, |. | photo | no | no |
| Delivery ledger | yes | yes | yes | yes | yes | via Apex |
| Works with no account | yes | yes | yes | yes | no | n/a |

Email and Slack deliberately do not send. Agreeing to something in writing days
later is not the same as choosing it in the moment, so the send button stays
where the person can see exactly what it will do.

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

Four invariants now fail the build:

- `advertised-keyword-is-routed`. Scans every user-facing string in Apex, the
  Visualforce pages and the channel scripts for "reply/send/text WORD", and
  fails if `CurbCutKeyword` does not route it. This is the check that would
  have caught all six original bugs on the day they were written.
- `relay-control-words-cover-apex`. The relay mirrors the word list so it can
  answer without a round trip; two lists that disagree is how this broke.
- `control-word-not-carrier-reserved`, nothing of ours may claim `STOP`.
- `handoff-refuses-telephone`. A phone call is refused in code, not merely
  discouraged in a comment.
