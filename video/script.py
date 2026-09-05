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
    "This is Curb Cut. It's for the one in four of us who has something at work that's quietly hard, and who never asked, because asking meant explaining our bodies to a manager. Here, you just say what's getting in the way. You never have to say why.",
    "Four seconds of silence while the cursor moves. Then close and calm, like you're sitting beside her."),
 ('mocks/people.png', 22, 0,
    "One in four isn't a number on a slide. It's your sister. The colleague who never asks. The person beside you on the bus. We don't get to look past them.",
    "Slow. This is the one that has to land."),
 ('frames/04-draft.png', 14, 0,
    "The request is written in her words. And this line is in every single one: I'm not sharing a diagnosis, and I'm not required to.",
    "Slow down on the last sentence. Let it settle."),
 ('cards/c03.png', 9, 0, "That's the whole form. This is the one most people get instead.",
    "Gentle. No edge on it."),
 ('cards/c02.png', 16, 0,
    "You've done this yourself. Think of the last time something at work was quietly hard. You worked out what it would cost to ask, and you said nothing.",
    "This is the one paragraph that has to land. Give it room."),
 ('frames/10-home.png', 9, 0, "One in four of us has a disability. Three in a hundred tell their employer.", ""),
 ('cards/c04.png', 8, 0, "You say what's hard. You never have to say why. No name, no login, and no diagnosis.", "Gentle."),
 ('cards/c06.png', 9, 0, "Nothing is sent until she clearly says yes. If she hedges, it waits.", ""),
 ('frames/agent-yes_gate-3.png', 13, 0,
    "Here it is, live, in the agent. She hedges, and it waits. She says yes, and only then does it move.",
    ""),
 ('frames/05-sent.png', 7, 0, "Sent, with a date she can hold them to.", ""),
 ('cards/c07.png', 12, 0,
    "And it's there wherever she is: on the web, by voice, by text, by email, in Slack, or through any assistant she already uses.",
    ""),
 ('mocks/sms.png', 21, 0,
    "The same thing by text, on a basic phone with no internet. She texts CURB CUT, says what's hard, and real options come back with what they usually cost. She picks one. It writes the request in her words, and waits for her yes.",
    "Unhurried. Let them read the phones."),
 ('mocks/voice.png', 10, 0, "Or she rings the same number and just says it. It never rings her back.", ""),
 ('mocks/email.png', 9, 0, "By email, the answer comes from the same door, so it's the same answer.", ""),
 ('mocks/slack.png', 8, 0, "In Slack, it's a private message. It can't post anywhere else.", ""),
 ('mocks/mcp.png', 13, 0,
    "And any assistant she already uses can ask on her behalf, through a tool that can find and draft, but can never send.",
    ""),
 ('cards/c08.png', 6, 0, "", "Silence. Let them read it."),
 ('frames/12-privacy.png', 16, 0,
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
    "We ran Salesforce's accessibility checks and our own responsible AI checks, and we say what they couldn't decide instead of counting it as a pass.",
    ""),
 ('cards/c10.png', 14, 0,
    "The code is open. Any organisation can run it in its own org, at no cost. What it needs is one person who will answer.",
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
