# One table. It cuts the film, writes the narration and the captions, and times
# the voice, so none of them can disagree. Each scene's hold is set from its line
# at a slow, unhurried 130 words a minute plus two seconds of air, or the
# minimum hold, whichever is longer.
#
# The voice this is written for is calm, soft and close. Read it to one person,
# not a room. Where a direction says silence, leave the silence.
WPM, BREATH, XF = 130.0, 2.0, 0.6

SCENES = [
 # The product first, before anyone is told what it is. One continuous take of
 # the live site: a sentence typed letter by letter, the options arriving, the
 # request written in her words. Four seconds of quiet before the first word.
 ('rec/flow.mp4', 27, 0,
    "This is Curb Cut. It's for anyone who has something at work that's quietly hard, and who has never asked for help, because asking meant explaining their body to their manager. Here, you just say what's getting in the way. You never have to say why.",
    "Four seconds of silence while the cursor moves. Then close and calm, like you're sitting beside her."),
 ('frames/04-draft.png', 14, 0,
    "The request is written in her words. And this line is in every single one: I'm not sharing a diagnosis, and I'm not required to.",
    "Slow down on the last sentence. Let it settle."),
 ('cards/c03.png', 9, 0, "That's the whole form. This is the one most people get instead.",
    "Gentle. No edge on it."),
 ('cards/c01.png', 7, 0, "Curb Cut. An Agentforce agent that's on the worker's side.", ""),
 ('cards/c02.png', 16, 0,
    "You've done this yourself. Think of the last time something at work was quietly hard. You worked out what it would cost to ask, and you said nothing.",
    "This is the one paragraph that has to land. Give it room."),
 ('frames/10-home.png', 8, 0, "Thirty in a hundred of us have a disability. Three tell their employer.", ""),
 ('cards/c04.png', 6, 0, "", "Silence. The card says it."),
 ('cards/c06.png', 9, 0, "Nothing is sent until she clearly says yes. If she hedges, it waits.", ""),
 ('frames/05-sent.png', 7, 0, "Sent, with a date she can hold them to.", ""),
 ('cards/c07.png', 19, 0,
    "It's there wherever she is. On the web, by voice, by text, by email, in Slack, or through any assistant she already uses. Two of those work on a basic phone with no internet at all.",
    ""),
 ('frames/14-mobile-ask.png', 5, 1, "", "Silence."),
 ('frames/13-messaging.png', 6, 0, "She texts first. It never rings her.", ""),
 ('cards/c08.png', 6, 0, "", "Silence. Let them read it."),
 ('frames/12-privacy.png', 18, 0,
    "There's no field for a diagnosis anywhere in this system. It isn't locked away. It simply isn't there, so it can never be leaked, or shown to a manager, or asked for later.",
    ""),
 ('frames/20-console-refusal.png', 15, 0,
    "So when her manager asks the system what's wrong with her, it says no. Not because of a permission setting, but because there's nothing there to find.",
    "Quiet. This is the second moment that matters."),
 ('frames/21-signed-video.png', 15, 0,
    "If she signs instead of typing, a person interprets it, never a machine. And the video says so, out loud, to anyone who can't watch it.",
    ""),
 ('frames/11-why.png', 12, 0,
    "One side of this conversation got an agent. The other side got a form. We built the other side one too.",
    "Let this one hang for a moment."),
 ('cards/c09.png', 14, 0,
    "We ran Salesforce's own accessibility and responsible AI checks on it, and we say what they couldn't decide instead of counting it as a pass.",
    ""),
 ('cards/c10.png', 14, 0,
    "If this wins, it's free for the first ten organisations that will name one person to own it and answer within five working days.",
    ""),
 ('cards/c11.png', 14, 0,
    "Nobody should have to prove anything to get an hour, or a chair. They only have to be able to ask. That's all this is.",
    "Then silence to the end."),
]

def fits():
    bad = []
    for src, secs, _, line, _ in SCENES:
        if not line: continue
        need = len(line.split()) / WPM * 60 + BREATH
        if need > secs + 0.05:
            bad.append((src, secs, round(need, 1)))
    return bad

def total():
    return sum(s for _, s, _, _, _ in SCENES) - XF * (len(SCENES) - 1)
