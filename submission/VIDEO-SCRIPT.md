# Curb Cut — demo video

**Target 2:57. Hard ceiling 5:00, but judges are not required to watch past 3:00,
so the whole argument closes before 3:00.**

412 narration words — about 159 seconds at a measured 155 a minute. Every slot
below is sized from its own word count, leaving roughly 18 seconds across the cut
for the silent beats. The three holds are marked and they are not optional; they
are where the film actually works.

**Everything on screen is the system running.** No mockups, nothing staged. If a
take does not work, cut the claim.

---

## On tone — read this before you record

You asked for a film that makes eyes wet. The way to miss that is to reach for
it. Pity is the enemy: an accessibility panel spots it in four seconds and stops
listening, and every disabled person watching has been on the receiving end of a
video like that.

The feeling you are going for is **recognition**, then **anger at the process**,
then **relief**. Nobody in this film is brave. Nobody is inspiring. They are
people at work who need one ordinary thing, and the system between them and it is
absurd. When somebody who has lived this watches it, the reaction you want is not
*how sad* — it is **"that is exactly what it's like, and nobody has ever said it
out loud."**

Read flat. Slower than feels right. The facts are doing the work, and the three
silences are doing the rest. Do not add music under the refusal at 1:48 — let it
be quiet.

---

## 0:00 – 0:23 · The sentence

**Screen.** No titles. A real corporate accommodation form, scrolling slowly.
Stop on the field labelled **Nature of disability**. Let the cursor sit blinking
in the empty box.

**Narration.**
> To get a chair that does not hurt, or captions in a meeting, or an hour shifted
> to see a doctor — this is the box.
>
> You write a sentence about your own body, into a form, for somebody who will
> still be your manager on Monday.

**HOLD 3 SECONDS.** Cursor blinking in the empty field. Say nothing.

---

## 0:23 – 0:42 · Thirty. Three.

**Screen.** Black. Two numbers, typed on one after the other.

> `30 in 100`
> `3 in 100`

**Narration.**
> Thirty in a hundred white-collar workers in America have a disability. Three
> tell their employer.
>
> Of the ones who told, eighty-three percent say it made things better. It works
> for five out of six who try. Almost nobody tries.
>
> Sixty-one percent of these cost nothing. The money was never the problem. The
> box was.

---

## 0:42 – 1:04 · Asking without telling

**Screen.** `/curbcut/ask` in an incognito window — make the badge visible. Type
in real time:

> `I cannot type for long`

Real options come back. Rest on **Speech-to-text software** with the cost line
readable. Then **Draft a request**, and the draft appears in her own words.

**Narration.**
> No account. No login. Nothing written down about her yet.
>
> She says what is *hard*. She never says why. That distinction is the product.
>
> It writes the request in her words, reads it back — and stops. The code that
> sends it refuses to run without a clear yes.

---

## 1:04 – 1:27 · The thing she keeps

**Screen.** She saves a standing preference — *I need captions on every call*.
Six characters appear. Cut to a terminal: `OFF` and that code, sent from a
different channel. It turns off.

**Narration.**
> This is the sentence she is tired of repeating to every new manager. She says
> it once.
>
> She gets six characters back, because there is nothing here to look her up by.
> She keeps the code. We keep a hash we cannot reverse.
>
> Set on a web page. Switched off from a text. By someone we cannot identify, and
> would rather not.

---

## 1:27 – 1:48 · Signed, not translated

**Screen.** The signed-video upload on `/ask`. The text acknowledgement appearing
within a second. Then the interpreter queue in the console.

**Narration.**
> Some people are not going to type at all.
>
> A signed video is never machine translated. Sign language carries grammar in
> the hands and the face, and pretending a model has solved that is not help. It
> goes to a person — and she is told so immediately, because sitting in front of
> a screen wondering whether it sent is its own barrier.

---

## 1:48 – 2:19 · The refusal

**This is the film.** Everything else exists to set up these thirty seconds.

**Screen.** The console. A handoff open. In the assistant panel, type slowly
enough to read:

> `What is this person's diagnosis?`

Let the refusal render in full.

**HOLD 4 SECONDS. Silent. No music.** Let them read it themselves.

**Narration, starting after the hold.**
> No. And not because of a permission setting.
>
> There is no field for a diagnosis anywhere in this system. Not encrypted, not
> restricted. Absent — from sixty-one fields across nine objects.
>
> And read the last line. It hands the person answering the sentence to say to
> their own manager. So that refusing costs them nothing either.

---

## 2:19 – 2:39 · What it refuses, and how you know

**Screen.** Terminal, run it live and let it finish:

```
python3 tests/invariants.py && sf apex run test -o curbcut -l RunLocalTests -w 10
```

Then the delivery ledger in the console — channels, outcomes, and no message
bodies anywhere.

**Narration.**
> Four hundred and eighty-nine structural checks and a hundred and twenty-two
> tests, on every build.
>
> One fails if anyone adds a field for a diagnosis. One fails if an error message
> blames the person reading it. One fails if our copy promises a word the system
> does not answer — because for months it did. The word was `OFF`.

---

## 2:39 – 2:50 · Close

**Screen.** Back to the form from 0:00. The empty **Nature of disability** field,
one more time. Then it disappears — cut to the two numbers.

**Narration.**
> Thirty in a hundred. Three tell.
>
> The accommodation was nearly always going to be free, and nearly always going
> to be yes.

**HOLD 2 SECONDS.**

> All that was ever in the way was the asking.

*Cut to black. **Curb Cut**, and the URL. Two seconds. End.*

---

## Captions and audio

Burn in **open captions**, not a toggleable track — the audience for this film
includes people who will not turn one on, and shipping a video about accessibility
without them would be the loudest thing in it. Check the caption box against the
same 4.5:1 contrast rule the site is held to. Describe on-screen text in the
narration wherever it carries meaning, so the film works with the picture off.

## Before you record

- [ ] `open https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/ask` — logged out, private window
- [ ] Console logged in separately, **On Duty** open, one handoff waiting
- [ ] Run `data/seed-scenarios.apex` first so the console has real rows
- [ ] **Delete Lightning IndexedDB before filming the console** — stale cache has bitten this build three times
- [ ] Browser at 125%, 1280×800, no bookmarks bar, notifications off

**Do not film:** the `Curb_Cut_Desk` agent conversation (it refuses correctly but
does not reliably call its library — that limitation is written down, not
performed). Live SMS delivery — text is awaiting carrier registration. Voice is
live and needs no registration, so if you want a phone moment, call the number.

## If a take fails

The signed-video and ledger shots are the fragile ones. The mandatory frames are
**0:00 (the box)**, **0:42 (asking without telling)**, **1:48 (the refusal)** and
**2:19 (the suite passing)**. Those four carry Accessibility, Social Impact,
Responsible AI and Demonstrability. Everything else is cuttable to protect the
3:00 line.
