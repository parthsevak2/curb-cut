# A2P 10DLC resubmission — campaign CMcb0b8f321bcc5aa98b2cc45bb3ea594a

Rejected 30 Aug 2026 under **error 30909**: the reviewer could not verify how
end users consent. The fix is in the product, not the paperwork — see the
commit "Fix the A2P rejection, and the three real holes behind it". This file
is the exact text to paste back into the Twilio Console.

**Before resubmitting, confirm these are reachable in a logged-out browser:**

| URL | Must show |
|---|---|
| https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/messaging | the notice, verbatim, with the consent line |
| https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/terms | programme terms |
| https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/privacy | the mobile-information clause |

All three return HTTP 200 to an anonymous request as of this commit, and an
invariant now fails the build if any Visualforce page is not granted to the
guest profile, which is how `/messaging` first shipped as a 401.

---

## Campaign description

> Curb Cut is a workplace accessibility assistant. Employees, contractors and
> job applicants text the number to find out what workplace adjustments they
> could ask for, and the assistant can draft an accommodation request and send
> it to their employer, but only with the person's explicit approval given in
> the conversation. All messages are conversational replies to a message the
> user sent first. There is no marketing, promotional, recurring or scheduled
> messaging of any kind.

## Message flow / call to action  *(this is the field that was rejected)*

> End users opt in by sending the first text message themselves to
> +1 276 495 9311. There is no web form, no uploaded list, no purchased data
> and no third-party lead source; Curb Cut never messages anyone who has not
> messaged it first. The call to action is a printed notice displayed in
> workplaces, break rooms and union offices. That notice is reproduced word for
> word, and is publicly viewable without login, at
> https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/messaging
> The notice reads: "Is something at work harder than it needs to be? Text CURB
> CUT to +1 276 495 9311. Find out what you could ask for. By texting this
> number you agree to receive text messages from Curb Cut in reply. Message
> frequency varies. Message and data rates may apply. Reply HELP for help, STOP
> to stop. Terms: /curbcut/terms Privacy: /curbcut/privacy".
> Immediately after a person's first message, and only once, they receive this
> confirmation as a separate message: "Curb Cut: you texted first, so you will
> get replies from this number. Message frequency varies and replies only
> follow your own messages. Message and data rates may apply. Reply HELP for
> help, STOP to stop. Terms [link] Privacy [link]".
> Every later message is a direct reply to a message the user sent. Message
> frequency varies and is determined entirely by the user. Message and data
> rates may apply.
> Terms and Conditions: https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/terms
> Privacy Policy: https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/privacy
> The privacy policy states that no mobile information, phone number or
> text-message opt-in consent is shared with, sold to or rented to any third
> party or affiliate for marketing or promotional purposes.

## Sample messages

1. > You said you cannot type for long. Some things that can help are: a
   > different kind of keyboard, shaped or laid out to make typing easier or
   > less painful; and speech-to-text software, which lets you talk and the
   > computer types for you. You can stop here if you just wanted to know your
   > choices. Reply HELP for help, STOP to stop.

2. > Curb Cut: you texted first, so you will get replies from this number.
   > Message frequency varies and replies only follow your own messages.
   > Message and data rates may apply. Reply HELP for help, STOP to stop.
   > Terms https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/terms
   > Privacy https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/privacy

## Keyword responses — these are live in the relay, not aspirational

| Keywords | Reply |
|---|---|
| HELP, INFO | Curb Cut helps you find out what could make work easier at work, and ask for it, without ever saying what condition you have. Message and data rates may apply. Reply STOP to stop. Help: parth.sevak2@gmail.com Terms https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/terms |
| STOP, STOPALL, UNSUBSCRIBE, CANCEL, END, QUIT | Curb Cut: you will not get any more messages from this number. Reply START if you ever want to come back. Nothing about you is kept. |
| START, YES, UNSTOP | Curb Cut: you are back. Tell me what is hard at work right now. Message and data rates may apply. Reply HELP for help, STOP to stop. |

## Why this should now pass

| Rejection code | What it wants | Where it is satisfied |
|---|---|---|
| 30909 | end-to-end description of every opt-in path | the message flow above; there is exactly one path |
| 30907 / 30921 | a website a reviewer can actually open | `/curbcut/messaging`, HTTP 200 anonymous |
| 30919 | site explains the business and the messaging use case | `/curbcut/messaging` and `/curbcut` |
| 30908 / 30933 | compliant privacy policy, URL supplied | `/curbcut/privacy`, mobile-information clause added |
| 30934 | terms URL supplied | `/curbcut/terms` |
| 30917 | complete workflow for every opt-in method | only one method, described end to end |
| 30924 | consent language in the opt-in flow | on the notice itself, reproduced on the page |
| 30925 | opt-in unchecked by default, active consent | there is no checkbox; the person sends the first message |

## A limit worth knowing

Carrier keyword auto-responses cap at **320 characters**. Ours are delivered as
TwiML, which has no such cap, so an over-long HELP reply passed every test and
would then have been silently truncated in the Messaging Service field - leaving
`/messaging` quoting text that is not what arrives, on the one page whose whole
job is to be verifiable. The HELP reply is now 279 characters and identical
everywhere. An invariant fails the build if any keyword reply exceeds 320.

## What I could not do

Resubmitting the campaign is an attestation that the information is accurate,
and that attestation is yours to make, not mine. Everything above is prepared;
the Console submission itself needs your hand on it.
