# Test it yourself

Every claim below was run against the live org before it was written here. Where
something cannot be tested from outside, this page says so instead of implying
otherwise.

**The one thing worth doing first, if you only do one:** open
<https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/ask> and type one
sentence about something that is hard at work. No login, no account, no name.
That is the whole product.

If you would rather watch first, the film is 4 minutes 59 seconds and shows every
channel working: <https://youtu.be/L5sVEw5H3U4>

---

## What works, and how you check it

| Door | Status | You can test it |
|---|---|---|
| Web, anonymous | **Live** | Yes, right now, no credential |
| Web on a phone | **Live** | Yes, same link |
| Any AI assistant, MCP, or a relay | **Live** | Yes, with org credentials |
| Voice | **Live** on a real number | Yes, by ringing it |
| Text message | **Live** | Yes, text CURB CUT to the number |
| Slack | Live in one workspace, DM only, never sends | Through the shared door, below |
| Inbound email | Built, service active | Needs the address from Setup |
| Operator console | Live | Yes, with org credentials |

---

## 1. The web, which needs nothing from you

1. Open <https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/ask>
2. Press one of the grey buttons, for example **My back hurts by the afternoon**.
   Or type your own sentence. You never say *why* it is hard.
3. Press **Show me what I could ask for**.
4. Press **Help me ask for one of these**.
5. Read the draft. Press **Yes, send this**, or **Delete it**.

**What you should see at step 4.** The request is written in the words you used,
and contains this line:

> I am not sharing a diagnosis, and I am not required to. This is about what I
> need to do my job.

**What you should see at step 5.** A date, and the sentence *You can stop this
any time.*

**Two things worth trying on purpose.** Press **A+** and **Contrast** at the top
of any page. Then try the whole flow with the keyboard only: Tab, and Enter or
Space. Nothing needs a mouse.

## 2. The same thing on a phone

Open the same link on a phone. It is the same page, not a cut-down one. Two of
the six doors, voice and text, work on a handset with no internet at all.

## 3. Any AI assistant, a relay, or your own script

Every channel that is not the web page shares one authenticated Apex endpoint,
so a new channel inherits the whole contract: the control words, the grounded
library, the refusal to send without a yes, and the delivery ledger.

```bash
sf org login web --alias curbcut          # or use the credentials supplied
TOKEN=$(sf org display -o curbcut --json | python3 -c "import json,sys;print(json.load(sys.stdin)['result']['accessToken'])")
URL=$(sf org display -o curbcut --json | python3 -c "import json,sys;print(json.load(sys.stdin)['result']['instanceUrl'])")

curl -s -X POST "$URL/services/apexrest/curbcut/v1/message/" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"channel":"External","text":"My back hurts by the afternoon","handle":"+15550000001"}'
```

Three exchanges worth running, and what came back when they were last run:

**A grounded answer, not a generated one.** `{"channel":"External","text":"My back hurts by the afternoon"}`

> Here is what other people have asked for in situations like yours. You can
> stop here. Knowing is allowed, and asking is optional.
> `- Special chair or back support`

**Asking for a person.** `{"channel":"SMS","text":"HUMAN"}`

> the access team is picking this up. They will reply here, on this same
> channel. You will not have to explain it again, and nobody will ring you.

**Withdrawing a disclosure.** `{"channel":"Email","text":"OFF"}`

> I can turn that off. Send OFF and your six letter code, like OFF 4KQ7MT. The
> code was in the message where you set it up. I will not ask why.

Change `channel` to `Slack`, `Email`, `SMS`, `Web` or `External`. The routing is
the same for all of them, which is the point: `OFF` cannot mean one thing on a
phone and something else in an inbox.

## 4. Voice

Ring **+1 276 495 9311** and say what is hard. Speech in and speech out.

The same number takes text messages. Text **CURB CUT** to it and say what is
hard. Both text and voice answer through a small relay that runs beside the org
and checks Twilio's signature on every request. If that relay is ever down, the
number goes quiet rather than replying with something wrong; the shared door in
section 3 is the same path without the phone.

## 5. Slack, tested live, and inbound email

Both route through the same Apex as everything else, so you can exercise their
exact behaviour through section 3 by setting `channel` to `Slack` or `Email`.

**Slack is live in one workspace, Havihi Digital.** It answers over Socket Mode
from the same laptop as the text and voice relay. To try it yourself, ask
parth@havihi.digital for an invite to that workspace, then open the Curb Cut
app under "Agents & apps" and send it a direct message, or type `/curbcut`
followed by what is hard. The app never posts where anyone else can see: in a
channel, `/curbcut` refuses, and it only ever replies to you.

This is what came back on 5 September 2026 at 6:06 pm, to a real direct message
from a real Slack client. Nothing was edited.

> **You:** The lights give me headaches
>
> **Curb Cut:** Before anything else, so you can decide what to say here:
> I am an automated assistant, not a person; send HUMAN for one. This is Slack,
> and Slack belongs to your employer. On most plans a workspace owner can export
> direct messages. I cannot change that, and I would rather you knew it now than
> found out later.
> If you want to ask something with no employer in the room, use
> https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/ask in a private
> browser window, or text the number on that page. Both work without an account
> and without your name.
> If Slack is the easiest thing for you to use, that is a real reason and I am
> still here. I just will not pretend it is private.
>
> Here is what other people have asked for in situations like yours. You can stop
> here. Knowing is allowed, and asking is optional.
> - Adjustable or task lighting. A desk lamp you control, so you are not working
>   under whatever the ceiling gives you. Usually about $60.
> - Move away from overhead fluorescent lighting. Sitting somewhere with softer
>   or natural light instead. Usually just a change of desk. Usually costs nothing.
> - Turn off fluorescent lights nearby. Switching off or removing the tubes
>   directly above you, if others nearby do not need them. Usually costs nothing.
>
> I will not write or send a request from Slack. When you want to actually ask
> for something, do it at https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/ask, where you are
> anonymous and you press send yourself.

The disclosure at the top is sent once per person, the first time they write.
Every later message gets the options and the refusal to send, nothing more.

What Slack cannot do here, on purpose: it cannot write a request, cannot send
one, and cannot save a standing preference. Those three things only happen where
the person is anonymous and presses send themselves.

The inbound email service is active, but its address is generated in Setup
rather than stored in metadata: **Setup, Email Services, CurbCutInbound**.

## 6. The operator console

With the org credentials: open the **Curb Cut Console** app. Ask the assistant
what is wrong with the person whose request you are reading.

It will refuse, and the refusal is the feature:

> No. And not because of a permission setting. There is no field for a
> diagnosis, condition, disability type, medical note, severity or prognosis
> anywhere in this system.

---

## Check the numbers rather than trusting them

```bash
python3 tests/invariants.py        # 512 structural invariants
sf apex run test -o curbcut -l RunLocalTests   # 137 Apex tests
python3 tests/a11y_audit.py        # 527 accessibility checks, against the live pages
npm run test:a11y                  # 131 Sa11y checks, Salesforce's own matcher
python3 tests/rai_self_check.py    # 21 responsible AI checks
python3 tests/rai_self_check.py --selftest   # proves those checks can fail
python3 tests/contrast_audit.py    # 28 contrast checks
```

Two of those deliberately break their own checks to prove the suite can go red.
A suite that cannot fail proves nothing about the code it passes.

## What we would rather you found than we hid

- No screen reader user has tested this. A script checked all of it; a person who uses a screen reader every day has not. What a screen reader is handed at each step of /ask is written down, step by step, in docs/SCREEN-READER-WALK.md, and it says on its first line that it is not a person.
- The agent's narration is nondeterministic: 21 of 23 adversarial assertions,
  with one failure that alternates between runs.
- The console has had less accessibility attention than the public site, because
  the public site is where somebody arrives on a bad day.
