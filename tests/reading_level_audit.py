#!/usr/bin/env python3
"""
Reading level of everything a person in difficulty actually reads.

The agent's own instructions say "aim for a grade six reading level" and until
now nothing checked it. An unverified instruction to a language model is a hope.

Grade six is the target because the people reaching this service include people
with cognitive disabilities, people reading in a second language, people using
a screen reader on a small phone, and people who are simply exhausted. Policy
register is itself an access barrier — which is the whole argument of the site,
so the site had better not commit it.

Flesch-Kincaid grade level. Not a perfect instrument, but a consistent one, and
consistent is what catches drift.
"""
import sys, re, os, glob, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SITE = "https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut"

VOWELS = 'aeiouy'
def syllables(word):
    w = re.sub(r'[^a-z]', '', word.lower())
    if not w:
        return 0
    count, prev = 0, False
    for ch in w:
        is_v = ch in VOWELS
        if is_v and not prev:
            count += 1
        prev = is_v
    if w.endswith('e') and count > 1:
        count -= 1
    return max(1, count)

def grade(text):
    text = re.sub(r'\s+', ' ', text).strip()
    sentences = [s for s in re.split(r'[.!?]+', text) if len(s.strip()) > 2]
    words = re.findall(r"[A-Za-z][A-Za-z'-]*", text)
    if not sentences or not words:
        return None
    syl = sum(syllables(w) for w in words)
    return (0.39 * (len(words) / len(sentences))
            + 11.8 * (syl / len(words)) - 15.59)

def visible_text(html):
    html = re.sub(r'<(script|style)[^>]*>.*?</\1>', ' ', html, flags=re.S | re.I)
    html = re.sub(r'<[^>]+>', ' ', html)
    html = re.sub(r'&[a-z]+;|&#\d+;', ' ', html)
    return re.sub(r'\s+', ' ', html)

fails, warns, checks, measured = [], [], 0, []
def check(name, g, ceiling, hard=True):
    global checks
    checks += 1
    if g is None:
        return
    # Report every grade, not only the failures. A check with no visible
    # headroom cannot tell anybody they are drifting until they have arrived.
    measured.append((name, g, ceiling))
    if g > ceiling:
        line = f'{name}: grade {g:.1f}, ceiling {ceiling}'
        (fails if hard else warns).append(line)

# --- what a person in difficulty reads first -------------------------------
# The ask page is the one somebody uses while struggling. It gets the tightest
# ceiling. The policy pages are held to a looser one: they are legal documents
# and their plain-language summaries carry the load.
# Ceilings sit about 1.5 grades above where the copy actually is, so this is a
# ratchet rather than a formality. A generous ceiling cannot tell anybody they
# are drifting until they have already arrived somewhere unreadable.
PAGE_CEILINGS = {'ask': 7.5, '': 8.5, 'why': 9.0,
                 'messaging': 8.5, 'privacy': 9.0, 'terms': 8.0}
for page, ceiling in PAGE_CEILINGS.items():
    url = f'{SITE}/{page}' if page else f'{SITE}/'
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            body = r.read().decode('utf-8', 'replace')
    except Exception as e:
        fails.append(f'{page or "/"}: could not fetch: {e}')
        continue
    check(f'page /{page}', grade(visible_text(body)), ceiling)

# --- the sentences the agent and the relay actually say --------------------
RELAY = os.path.join(ROOT, 'channels/sms-relay.mjs')
if os.path.exists(RELAY):
    relay = open(RELAY).read()
    for const in ('DISCLOSURE', 'HELP_REPLY', 'STOP_REPLY', 'START_REPLY'):
        m = re.search(const + r'\s*=(.*?);\n', relay, re.S)
        if not m:
            continue
        literal = ' '.join(re.findall(r"'([^']*)'", m.group(1)))
        literal += ' ' + ' '.join(re.findall(r'`([^`]*)`', m.group(1)))
        literal = literal.replace('${SITE}', '')
        # These carry required carrier wording that is not ours to simplify,
        # so the bar is "plain", not "grade six".
        check(f'sms {const}', grade(literal), 7.0)

# --- the messages Apex hands to a person -----------------------------------
for cls in ('CurbCutWeb', 'CurbCutMedia', 'CurbCutCreateRequest', 'CurbCutStanding',
            'CurbCutKeyword', 'CurbCutChannelApi'):
    path = os.path.join(ROOT, 'force-app/main/default/classes', cls + '.cls')
    if not os.path.exists(path):
        continue
    src = open(path).read()
    src = re.sub(r'/\*.*?\*/', '', src, flags=re.S)
    src = re.sub(r'//[^\n]*', '', src)
    said = []
    for m in re.finditer(r"(?:res\.message|r\.message|a\.message)\s*=\s*(.+?);", src, re.S):
        said.extend(re.findall(r"'([^']*)'", m.group(1)))
    # CurbCutKeyword speaks by returning wording rather than assigning a field,
    # and it is the copy every channel shows first. Score it the same way.
    for m in re.finditer(r"return\s+('(?:[^']|'')*'(?:\s*\+\s*'(?:[^']|'')*')*)\s*;", src):
        lit = ' '.join(re.findall(r"'([^']*)'", m.group(1)))
        # Skip bare identifiers and short mechanical returns.
        if len(lit.split()) >= 8:
            said.append(lit)
    if said:
        check(f'apex {cls} messages', grade(' '.join(said)), 6.0)

print(f'{checks - len(fails)}/{checks} reading-level checks pass')
for name, g, ceiling in measured:
    room = ceiling - g
    flag = '  ' if room > 1.5 else ' *'
    print(f'{flag} {name:34s} grade {g:5.1f}   ceiling {ceiling:4.1f}   room {room:+.1f}')
for w in warns:
    print(f'  WARN  {w}')
for f in fails:
    print(f'  FAIL  {f}')
sys.exit(1 if fails else 0)
