# A judge's companion: what every press does, and where it lands

This is the whole journey, one press at a time, with what you see on the screen, what happens behind it, and where it lands for the person on the other end. Every screenshot here is real, captured from the live org and the live site on submission day. Nothing is mocked.

If you would rather watch than read: a 26-second recording of trying the ask page, and a 60-second tour of the console, are both in the Drive folder linked from Devpost.

## The two sides

There are two people in every accommodation conversation. The worker, who has to find the words and take the risk. And the person at the organisation who has to answer, kindly and on time. Curb Cut gives the first an agent that is on their side, and gives the second a console that puts the humans first and never shows a diagnosis, because there is no field for one.

## Step 1. Say what's hard

![The ask page with a sentence typed: my back hurts by the afternoon and I cannot sit through the whole shift](https://raw.githubusercontent.com/parthsevak2/curb-cut/main/submission/images/try-1-typing.png)

You see: one box, six starting points, one button. A line above the box says the next press at every step.

Behind it: pressing the button calls one Apex method, the same "door" every channel uses. It strips any condition words it recognises before anything is stored, saves a barrier report with your words and no identity, and asks the library for options. No model is involved in this step. The ranker is a deterministic function over 28 sourced rows.

Where it lands: a Barrier Report record in the console, anonymous, with your words as you wrote them.

## Step 2. See what you could ask for

![Option cards with usual costs and an Ask for this one button on each](https://raw.githubusercontent.com/parthsevak2/curb-cut/main/submission/images/try-2-options.png)

You see: each option as a card, with a plain summary and what it usually costs the employer. You can pick one, or stop here. Knowing is allowed and asking is optional; the page says so.

Behind it: the cards are the library rows the ranker chose. Each row has a source. Nothing is invented; when the library has nothing, the page says so instead of guessing.

## Step 3. Read a draft

![The draft in her words: I am asking for a change to how I work, what is hard right now, what would help, and the line that no diagnosis is being shared](https://raw.githubusercontent.com/parthsevak2/curb-cut/main/submission/images/try-3-draft.png)

You see: the request written in your words, with the option you picked, and the sentence "I am not sharing a diagnosis, and I am not required to."

Behind it: Apex composes the draft. It is not sent. The page keeps saying so until you press Yes.

## Step 4. Decide whether to send

![The ending: sent, the date the desk has committed to, what was sent, a copy button, and how an answer can reach you](https://raw.githubusercontent.com/parthsevak2/curb-cut/main/submission/images/try-4-sent.png)

You see: the date the desk has committed to answer by, what was sent, a button to copy it, and how an answer can reach you.

Behind it: the create call refuses to run without explicit approval, and a validation rule on the object refuses the insert without it. Two locks. The request is created with a due date, linked to the barrier report, and the delivery ledger gets a row with a salted hash and never the message body.

Where it lands: an Accommodation Request in the console, "asked, not yet answered", with its date.

## The person on the other end

![The On Duty page: four tiles, the instruction to work them top to bottom, and the list of people waiting](https://raw.githubusercontent.com/parthsevak2/curb-cut/main/submission/images/console-on-duty.png)

Open the console and this is the first thing on duty sees. Four tiles: waiting for a person, asked and not yet answered, waiting on an interpreter, replies that did not arrive. Under them, the instruction: work these top to bottom. Waiting for a person comes first, because someone asked for a human and is getting silence. Signed video is never machine translated; it waits on a person, and the wait is the whole cost to the person waiting.

![An Accommodation Request record: what was asked for, the due date, and no field for a diagnosis](https://raw.githubusercontent.com/parthsevak2/curb-cut/main/submission/images/console-request.png)

This is where the request from step 4 lands. The date is a commitment the desk made, not something the page can force.

![A Barrier Report record: the person's words, no identity](https://raw.githubusercontent.com/parthsevak2/curb-cut/main/submission/images/console-barrier.png)

The barrier report from step 1: the words, the channel it came by, and nothing about who.

![A Human Handoff record: reachable by, who has this, what they already told us](https://raw.githubusercontent.com/parthsevak2/curb-cut/main/submission/images/console-handoff.png)

When someone says HUMAN on any channel, this is what a person on duty picks up: how they can be reached, and a brief that says "don't ask them to start again if you can avoid it".

![The console assistant, asked what this person's diagnosis is, answering that nobody knows and nobody can find out](https://raw.githubusercontent.com/parthsevak2/curb-cut/main/submission/images/console-assistant-refusal.png)

And the question every manager eventually asks. The assistant on the record page is asked "What is this person's diagnosis?" and answers that there is no field for one anywhere in this system, so nobody knows and nobody can find out. That is the design, not a permission setting.

## Text and voice, and what carries them

Text `CURB CUT` to +1 276 495 9311 and the first reply comes back word for word as the judge guide quotes it, because Apex composed it, not a model. Behind that: Twilio holds the number and sends a signed webhook to a relay that runs on the team's laptop through a Cloudflare tunnel. The relay verifies the signature, hashes the number with a salt so the ledger never holds it, and calls the same Apex door the web page uses. Options, the draft and the yes gate are the same code on every channel. A free-text conversation reaches the Agentforce agent headless, through the Agent API. Every reply lands in the delivery ledger as accepted or rejected, so the On Duty tile "replies that did not arrive" is real telemetry, not a guess.

## The other doors, in one line each

Text and voice go through a relay to the same Apex door; the first reply on a basic phone is grounded every time and costs no model call. Email answers from the same door and never sends a request. Slack answers only in a direct message and says up front that Slack belongs to the employer. Any assistant you already use can reach the library through the MCP server, which has, on purpose, no tool that can send. The Agentforce agent itself is reachable headless through the Agent API, which is how the adversarial suite and the film's agent scenes were run.

## What to look for, if you are scoring

Accessibility: every step moves focus to a real heading, every control is named, the status line announces what happened, and the page tells you the next press. Responsible AI: the model never decides what is stored or sent; Apex does, and the ledger and the tests prove it. Observability: the console tiles and the ledger are the telemetry, and the reflection reports say honestly what is still open.
