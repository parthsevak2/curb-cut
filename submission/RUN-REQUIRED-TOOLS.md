# The two tools that gate the submission

> *"Every team must run both the Accessibility Expert Skill and the RAI Self Check
> Skill from the AI Expert Suite. In your submission, describe what each tool
> flagged and how your team responded. **Judges evaluate your engagement with the
> findings, not a perfect score.**"*

That last sentence is the whole game. A finding you engaged with honestly scores
better than a clean run. Do not tune for a green.

## Where to get them

I could not reach them from here — they are not installed in the provisioned org,
not a public Salesforce package, and not available as a skill in this
environment. They are distributed to participants. Try in this order:

1. **Devpost → the hackathon page → Additional details → "Support Channel &
   Resources."** This is the most likely home.
2. **The hackathon Slack sandbox** (Additional details → "Slack Sandboxes"). The
   AI Expert Suite is most plausibly a set of Agentforce/Claude skills shared
   there.
3. **Additional details → "Workshops and Tutorials."**
4. If none of those have it, **ask in the support channel.** With five days left,
   asking early costs nothing and waiting costs the submission.

## What to point them at

Have these ready so a run takes one pass:

| Input | Value |
|---|---|
| Public site | `https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut` |
| The page that matters most | `…/curbcut/ask` |
| Org | `00DgK00000YIJ5SUAX` |
| Agent | `Curb_Cut`, Active at v7 |
| Internal agent | `Curb_Cut_Desk`, Active at v5 |
| Console app | Curb Cut Console |

If the Accessibility skill takes a URL, give it `/ask` first — that is the page
somebody uses on a hard day, and it is where a finding matters most. Then
`/curbcut` and `/why`.

## What to do with the output

1. **Paste the raw findings** into `DEVPOST-ANSWERS.md` under the two scaffolded
   questions. Do not summarise them away.
2. **For each finding, answer three things:** what it flagged, what we changed,
   and — where we did not change it — why not. A defended decision is a real
   answer; "fixed everything" is not.
3. Send me the output and I will fix what is fixable and draft the responses.

## Where we already agree with them, probably

Both tools will likely flag things we have already handled. Say so, and point at
the evidence rather than asserting it:

- Contrast, focus visibility, reflow at 320px, live-region announcements — all
  audited on every build against the live pages, 333 + 28 checks.
- No diagnosis field anywhere; volunteered conditions stripped before storage.
- Explicit-consent gate with two independent locks.
- Delivery ledger with hashed handles and no message bodies.

## Where they will probably find something real

Be ready for these, and do not be defensive about them:

- **No screen-reader user has tested this.** Machine-verified is not user-verified,
  and we say so on the evidence page already. We did, however, drive the live page
  with a real browser and read its accessibility tree, which found four defects a
  source scan could not — including that the claim code, shown once and
  unrecoverable, never took focus.
- **The conversational agent's narration is nondeterministic** — 21 of 23
  assertions across three runs, with one failure that alternates.
- **Colour and copy on the console** have had far less accessibility attention than
  the public site, because the public site is where somebody arrives on a bad day.
- **The Slack app has never run against a real workspace.**
