# Curb Cut — demo video

**Target 2:52. Hard ceiling 5:00, but judges are not required to watch past 3:00,
so the entire argument closes before 3:00.** Nothing after 2:52 carries weight.

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

## 0:00 – 0:18 · The gap

**Screen.** Black. Two numbers type on, one after the other, nothing else.

> `30 in 100`
> `3 in 100`

**Narration.**
> Thirty in a hundred college-educated people in white-collar jobs in America
> have a disability. Three tell their employer. Of the people who did tell,
> eighty-three percent say it got them better support. It works for five out of
> six who try it, and almost nobody tries.

*Cut on the last word. No music swell.*

---

## 0:18 – 0:32 · Why nobody tries

**Screen.** A real corporate accommodation form — any public one — scrolling.
Highlight in one pass: the login wall, the field marked *Nature of disability*,
the words *supporting medical documentation*.

**Narration.**
> Because this is the door. Find the policy, hold a work login, and write a
> sentence about your own body for somebody who is still your manager on Monday.
> Sixty-one percent of accommodations cost the employer nothing. The money was
> never the problem. This is.

---

## 0:32 – 1:06 · Ask before you tell anyone anything

**Screen.** `/curbcut/ask`, logged out, in a private window — make the incognito
badge visible. Type into the box, in real time:

> `I cannot type for long`

Options come back. Rest on the card for **Speech-to-text software**, the cost
line clearly readable.

**Narration.**
> No account, no login, nothing written down about you yet. You say what is
> *hard*. You never say why. Real options come back from a sourced library, with
> what each one usually costs the employer.

Then click **Draft a request**. The draft appears in the person's own words. Point
at it. Do not click Send yet.

> It writes the request in your words and reads it back. And it will not send.
> Not "are you sure" — the code that creates the request refuses to run without an
> explicit yes. A hedge is not agreement.

Click **Yes, send it.** Case number appears.

---

## 1:06 – 1:28 · The two doors typing does not open

**Screen.** Back on `/ask`. Attach a photo of a handwritten note — one shot,
the acknowledgement appearing. Then the signed-video upload. Rest on the
confirmation text.

**Narration.**
> Some people cannot type at all. Send a photo of a note instead. Or sign it —
> and a signed video is never machine translated. It goes to a human interpreter,
> and you are told so in text immediately, because sitting in front of a screen
> wondering whether it sent is its own barrier.

---

## 1:28 – 2:05 · The other side of the desk, and the refusal

**Screen.** Cut to the Curb Cut Console, **On Duty**. The handoff from 1:06 is
sitting there. Open it. The brief shows the person's own words and the Path.

**Narration.**
> A promise that a real person picks this up is worthless unless that person has
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

## 2:05 – 2:25 · Four front doors, one library

**Screen.** Split or quick cuts: the site → the SMS relay answering a webhook in a
terminal → the voice TwiML → the MCP server listing its tools in a second terminal.
When the SMS frame is up, put a plain caption on it:

> `Carrier approval pending — relay shown responding locally`

**Narration.**
> Web, text, voice, email — and a Model Context Protocol server, so the same
> grounded library answers from whatever assistant somebody already uses. Add a
> channel and the answers cannot drift, because there is only ever one set of them.

---

## 2:25 – 2:45 · What it refuses to do, and how you know

**Screen.** Terminal. Run the suite for real and let it finish on camera:

```
python3 tests/invariants.py && sf apex run test -o curbcut -l RunLocalTests -w 10
```

Then cut to the delivery ledger in the console — visible rows, channel and outcome,
and no message body anywhere.

**Narration.**
> Every attempt on every channel is on the ledger — what was tried, where it went,
> whether it landed — with a salted hash and never the message itself. Four hundred
> and forty-six structural checks and a hundred and five Apex tests run on every
> build. One fails the build if an error message blames the user. One fails it if
> anyone ever adds a field for a diagnosis.

---

## 2:45 – 2:52 · Close

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
**0:32 (ask without an account)**, **1:28 (the refusal)** and **2:25 (the suite
passing)** — those three carry Accessibility, Responsible AI and Observability.
Everything else is cuttable to protect the 3:00 line.
