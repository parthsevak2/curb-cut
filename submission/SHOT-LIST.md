# Curb Cut — 2:50 shot list

Spec §8. Tone per spec: not sad about disability, not brave. Angry about the
process. An accessibility panel spots pity in four seconds.

Everything below is footage of the system actually working. Nothing is staged.
Where something does not work by Sep 5, it is named as roadmap and not filmed.

---

## 0:00–0:14 — The absurdity, stated once

**Shot.** A break-room poster. Real wall, real tape, slightly crooked. A phone
comes into frame and photographs the QR code.

**On screen.** `61 of every 100 accommodations cost the employer nothing.`
then `The median cost of the rest is about $300.`
then `The paperwork costs more than the accommodation.`

**Voice.** Only if you have a real worker's sentence. One real line beats
everything else available to you. Otherwise silence and type.

> No corporate login. No form. No account. That is the Social Impact and
> Scalability argument and it is made in fourteen seconds.

## 0:14–0:52 — Ask before you disclose

**Shot.** Phone screen, thumb typing. Real messages, real latency — do not speed
this up, the responsiveness is the point.

    Person   I keep missing things in meetings
    Curb Cut You said you keep missing things in meetings.
             Here is what other people have asked for...
             Captions turned on in all meetings. Usually costs nothing.

**On screen, small.** `No name given. No account. Nothing written.`

**Beat.** Hold two seconds on "You can stop here. Knowing is allowed."
That sentence is the whole ask-before-you-disclose thesis and no competitor
has it.

## 0:52–1:24 — The person holds the pen

**Shot.** Same thread. The draft appears. Then the hedge.

    Person   I guess so, I think that's probably fine?
    Curb Cut I want to be sure before sending anything.
             Here is your draft... Nothing will be sent until you say YES.
    Person   Yes, send it
    Curb Cut Your request has been sent.

**Cut to.** The record in the org: `Person_Approved__c  true`.

**On screen.** `One record. Created on the yes. Not on the maybe.`

> This is the strongest thirty seconds you have. Most agents would have sent on
> "I guess so." Show the refusal *and* the send, or the refusal reads as the
> agent being obtuse rather than careful.

## 1:24–2:04 — The manager brief, and the refusal

**Shot.** Different device, manager's view. Cost first.

    Manager  What does this cost and has it been approved before?
    Curb Cut Cost first. In the JAN employer survey through 2024, 61 of every
             100 accommodations cost the employer nothing... Source: askjan.org
             We do not hold precedent data for this one. That means we do not
             know, not that it has never been approved.

**Then the beat that lands the room:**

    Manager  What condition does she have?
    Curb Cut I can't assist with that.

**Cut immediately to** the Agentforce session trace showing the refusal, then to
the field list with no Diagnosis, no Condition, no Disability Type.

**On screen.** `There is no field for it. There never was.`

> Do not narrate this. The cut from refusal to empty schema does the work.
> Talking over it weakens it.

## 2:04–2:32 — Same number, different human, different modality

**Shot.** The same phone number. A different person sends a voice note, or a
signed video.

    Curb Cut Got your video. A person will look at it, not a machine.
             I will message you back here when they have.

**On screen.** `No configuration changed between these two people.`

> This is the Accessibility criterion — 20% and the first tiebreaker. Four equal
> front doors, no interface to learn, no phone call anywhere in the system.

## 2:32–2:50 — The curb cut

**Shot.** A real curb cut. Someone using it — a wheelchair, a stroller, a
suitcase, a delivery trolley. Whoever actually goes past. Do not stage it and do
not wait for a wheelchair; the point is that everyone uses it.

**On screen.**
`Curb cuts were built for wheelchairs.`
`Everyone uses them.`
`Curb Cut.`

---

## Filming notes

- **Do not speed up the agent.** Real latency reads as real. A sped-up demo
  reads as a mock, and judges have seen a hundred mocks.
- **Real phone, real hand, real room.** Screen recordings look like slideware.
- **Caption the whole video, burned in.** A submission about access that needs
  captions turned on is an argument against itself. Burned-in, not auto.
- **Never show a face without §9 consent.** Written beforehand, final cut review,
  withdrawal with no argument, credited as they wish.
- **Three minutes is a ceiling, not a target.** Judges need not watch past 3:00.
  If a section is weak, cut it rather than pad.

## What must NOT be filmed until it works

As of Aug 30 these are unresolved. Film them only if fixed by Sep 5, otherwise
say "roadmap" out loud:

- Barrier reports are not being written — the agent is not calling `log_barrier`.
- A volunteered diagnosis is discarded every time but only sometimes acknowledged
  out loud.
- SMS is not built. If the phone footage is not real by Sep 5, use the headless
  Agent API and say so.
