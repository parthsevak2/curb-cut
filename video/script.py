# One table. It drives the cut, the narration and the timings, so they cannot
# disagree with each other. Duration is set from the line at an unhurried
# 140 words per minute plus two seconds of air, or the minimum hold, whichever
# is longer. A card that already carries its sentence is left silent on purpose:
# reading a slide aloud to somebody who is reading it is how a film loses them.
WPM, BREATH, XF = 140.0, 2.0, 0.6

SCENES = [
 # The product first. A judge with ninety seconds should see it working before
 # they are told what it is. One continuous take of the live site: a sentence
 # typed letter by letter, the options arriving, the draft written in her words.
 ('rec/flow.mp4', 24, 0,
    "This is Curb Cut. One question: what is hard at work right now. Never why. She types it. The options come from a sourced library, not a model. Then it writes the request in her words.",
    "Silence for the first four seconds while the cursor moves. Then plain."),
 ('frames/04-draft.png', 10, 0,
    "I am not sharing a diagnosis, and I am not required to.",
    "The line the whole thing turns on. Slow down."),
 ('cards/c03.png', 9, 0, "That is the whole form. Here is the usual one.",
    "Flat. No indignation. Let them read the card."),
 ('cards/c01.png', 7, 0, "Curb Cut. An Agentforce agent whose principal is the worker.",
    ""),
 ('cards/c02.png', 13, 0,
    "Think of the last time something at work was quietly hard. You worked out what it would cost to ask, and you said nothing.",
    "Slow. This is the only paragraph that has to land."),
 ('frames/10-home.png', 8, 0, "Thirty in a hundred have a disability. Three tell their employer.", ""),
 ('cards/c04.png', 6, 0, "", "Silent. The card says it."),
 ('cards/c06.png', 7, 0, "A hedge is refused, and a test proves the refusal.", ""),
 ('frames/05-sent.png', 6, 0, "Sent, with a date she can hold them to.", ""),
 ('cards/c07.png', 8, 0, "Two of them work on a basic phone, with no internet.", ""),
 ('frames/14-mobile-ask.png', 5, 1, "", "Silent."),
 ('frames/13-messaging.png', 5, 0, "She texts first. It never rings her.", ""),
 ('cards/c08.png', 6, 0, "", "Silent. Let them read it."),
 ('frames/12-privacy.png', 9, 0,
    "Absent, not encrypted. The only field that cannot leak is the one that was never created.", ""),
 ('frames/20-console-refusal.png', 9, 0,
    "So when her manager asks what is wrong with her, it refuses.", "Second emotional beat. Let it sit."),
 ('frames/21-signed-video.png', 8, 0,
    "If she signs instead of typing, a person interprets it. Never a machine.", ""),
 ('frames/11-why.png', 7, 0, "One side got an agent. The other side got a form.", "Let this hang."),
 ('cards/c09.png', 7, 0, "", "Silent."),
 ('cards/c10.png', 9, 0,
    "Free for the first ten who will name an owner and answer within five days.", ""),
 ('cards/c11.png', 9, 0, "They only have to be able to ask.", "Then silence to the end."),
]

def fits():
    bad = []
    for src, secs, _, line, _ in SCENES:
        if not line: continue
        need = len(line.split()) / WPM * 60 + BREATH
        if need > secs + 0.05:
            bad.append((src, secs, need))
    return bad

def total():
    return sum(s for _, s, _, _, _ in SCENES) - XF * (len(SCENES) - 1)
