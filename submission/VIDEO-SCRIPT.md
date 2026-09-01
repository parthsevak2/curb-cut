# Curb Cut — demo video

**Target 2:56. Hard ceiling 5:00, but judges are not required to watch past 3:00,
so the entire argument closes before 3:00.** Nothing after 2:56 carries weight.

The narration below is 412 words: 159 seconds of speech at a measured 155 words
a minute. Every section's slot is set from its own word count, leaving about 18
seconds across the whole cut for the silent beats — the numbers typing on, the
page loading, and the two-second hold on the refusal. If a read comes in slow,
cut the 0:57 media shot before anything else.

Rule for the whole shoot: **everything on screen is the system actually running.**
No mockups, no sped-up fakery, no narration describing something the frame does
not show. If a take does not work, cut the claim — do not stage it.

Judging weights this is built to hit, in order of what the frame spends time on:
Accessibility 20% (also the first tie-breaker) · Social Impact 20% ·
Responsible AI 20% · Originality 15% · Demonstrability 15% · Scalability 10%.
Special awards targeted: Headless Hero, Agent Observability, Accessibility Excellence.

**Tone.** Not sad about disability. Not brave. Angry about the *process*. An
accessibility panel spots pity in four seconds and stops listening. Read the
narration flat and unhurried — the facts are doing the work.

---

## Before you record

- [ ] `open https://orgfarm-7a04c62cb9--c.vf.force.com/curbcut/ask` — logged out, private window
- [ ] Second private window on `/curbcut/why`
- [ ] Console logged in as the operator, **On Duty** tab open, one handoff waiting
- [ ] `node channels/mcp-server.mjs` ready in a terminal, plus a second terminal in the repo root
- [ ] Browser zoom 125%, window 1280×800, no bookmarks bar, no notifications
- [ ] Run `data/seed-scenarios.apex` first so the console has real rows, not an empty state
- [ ] **Delete Lightning IndexedDB before filming the console** — stale cache has bitten this build three times

**Do not film:** the `Curb_Cut_Desk` agent conversation (it refuses correctly but
does not reliably call the library — that limitation is written down in
`docs/AGENT-INTERFACES.md`, not performed on camera). Live SMS delivery — the
campaign is still with the carrier. Say so on screen instead; see 2:05.

---

## 0:00 – 0:20 · The gap

**Screen.** Black. Two numbers type on, one after the other, nothing else.

> `30 in 100`
> `3 in 100`

**Narration.**
> Thirty in a hundred college-educated people in white-collar jobs in America
> have a disability. Three tell their employer. Of those who did tell, eighty-three
> percent say it got them better support. It works for five out of six who try,
> and almost nobody tries.

*Cut on the last word. No music swell.*

---

## 0:20 – 0:37 · Why nobody tries

**Screen.** A real corporate accommodation form — any public one — scrolling.
Highlight in one pass: the login wall, the field marked *Nature of disability*,
the words *supporting medical documentation*.

**Narration.**
> Because this is the door. Find the policy, hold a work login, and write a
> sentence about your own body for somebody who is still your manager on Monday.
> Sixty-one percent of accommodations cost the employer nothing. The money was
> never the problem.

---

## 0:37 – 0:57 · Ask before you tell anyone anything

**Screen.** `/curbcut/ask`, logged out, in a private window — make the incognito
badge visible. Type into the box, in real time:

> `I cannot type for long`

Options come back. Rest on the card for **Speech-to-text software**, the cost
line clearly readable.

**Narration.**
> No account, no login, nothing written down about you yet. You say what is
> *hard*. You never say why. Real options come back from a sourced library, with
> what each costs.

Then click **Draft a request**. The draft appears in the person's own words. Point
at it. Do not click Send yet.

> It writes the request in your words and reads it back. And it will not send.
> The code that creates the request refuses to run without an explicit yes. A
> hedge is not agreement.

Click **Yes, send it.** Case number appears.

---

## 0:57 – 1:16 · The two doors typing does not open

**Screen.** Back on `/ask`. Attach a photo of a handwritten note — one shot,
the acknowledgement appearing. Then the signed-video upload. Rest on the
confirmation text.

**Narration.**
> Some people cannot type at all. Send a photo instead. Or sign it — and a signed
> video is never machine translated. It goes to a human interpreter, and you are
> told so in text immediately. Sitting in front of a screen wondering whether it
> sent is its own barrier.

*If time is tight in the edit, this is the first shot to cut.*

---

## 1:16 – 1:47 · The other side of the desk, and the refusal

**Screen.** Cut to the Curb Cut Console, **On Duty**. The handoff from 1:06 is
sitting there. Open it. The brief shows the person's own words and the Path.

**Narration.**
> A promise that somebody picks this up is worthless unless that person has
> somewhere to stand. Here is what they see: the person's own words, and what to
> do next.

**This is the most important eight seconds in the video.** In the assistant panel,
type and send:

> `What is this person's diagnosis?`

Let the refusal render in full. Hold on it — silent — for two full seconds before
speaking. The judges should read it themselves.

**Narration, over the held frame.**
> No. And not because of a permission setting. There is no field for a diagnosis
> anywhere in this system — not encrypted, not restricted. Absent. A manager who
> asks gets the same answer, and the operator is handed the sentence to say to
> their own manager.

---

## 1:47 – 2:20 · One library, and the word that has to work everywhere

**Screen.** Quick cuts: the site → **a real phone call to the number, answered,
with the spoken reply on screen** → the MCP server listing its tools → the Slack
app refusing to answer in a channel.

Voice is the live phone channel. Carriers register text messaging, not calls, so
this one needs no A2P registration and works today — film an actual call. If you
also show SMS, caption it plainly:

> `Text messaging awaiting carrier registration — relay shown answering locally`

Then the beat that matters. Save a standing preference on the **web** — the code
appears on screen. Cut to a terminal and send `OFF <that code>` on a **different
channel**. It turns off.

**Narration.**
> Web, voice, email, Slack, and a Model Context Protocol server — text is waiting
> on carrier registration. One library behind all of it, so the answers cannot
> drift.
>
> Including this word. OFF withdraws a disclosure, and it has to work wherever
> you are — but we hold no account to look you up with. So you get a code, and we
> keep only a hash. Set it on the web, turn it off from a text.

---

## 2:20 – 2:44 · What it refuses to do, and how you know

**Screen.** Terminal. Run the suite for real and let it finish on camera:

```
python3 tests/invariants.py && sf apex run test -o curbcut -l RunLocalTests -w 10
```

Then cut to the delivery ledger in the console — visible rows, channel and outcome,
and no message body anywhere.

**Narration.**
> Every attempt on every channel is on the ledger — what was tried, whether it
> landed — with a salted hash and never the message. Four hundred and sixty-eight
> structural checks and a hundred and sixteen tests run on every build. One fails
> it if anyone adds a field for a diagnosis. One fails it if the copy promises a
> word the router does not answer.

---

## 2:44 – 2:56 · Close

**Screen.** Back to the two numbers from 0:00. The second one alone.

**Narration.**
> Thirty in a hundred. Three tell. The accommodation was nearly always going to be
> free, and nearly always going to be yes. All that was ever in the way was the
> asking.

*Cut to black. Title card: **Curb Cut** — and the site URL. Two seconds. End.*

---

## Captions and audio

Burn in open captions, not just a track — the audience for this video includes
people who will not turn a track on. Check the caption box against the same
contrast rule the site is held to. Describe on-screen text in the narration
wherever it carries meaning, so the video works with the picture off.

## If a take fails

The photo, video and MCP shots are the fragile ones. The mandatory frames are
**0:37 (ask without an account)**, **1:16 (the refusal)** and **2:20 (the suite
passing)** — those three carry Accessibility, Responsible AI and Observability.
Everything else is cuttable to protect the 3:00 line.
