#!/usr/bin/env python3
"""
Link integrity and cross-surface copy consistency.

Two failure modes this catches, both of which have already happened here:

1. A link that goes nowhere. On a site whose argument is that process shuts
   people out, a dead link is the argument failing in miniature.

2. Two surfaces telling somebody different words for the same control. The Apex
   once said "reply STOP to turn off a preference" while the site said OFF.
   Anybody who followed the Apex would have lost the whole service and kept the
   preference. Surfaces drift silently; this makes the drift loud.
"""
import sys, re, os, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SITE = "https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut"
PAGES = ["", "ask", "why", "messaging", "privacy", "terms"]

fails, checks = [], 0
def check(ok, detail):
    global checks
    checks += 1
    if not ok:
        fails.append(detail)

bodies = {}
for p in PAGES:
    url = f"{SITE}/{p}" if p else f"{SITE}/"
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            bodies[p] = r.read().decode('utf-8', 'replace')
    except Exception as e:
        check(False, f'{p or "/"} could not be fetched: {e}')

# ---- every internal link resolves to a page that exists -------------------
known = {'/', '/ask', '/why', '/messaging', '/privacy', '/terms'}
for p, body in bodies.items():
    for href in set(re.findall(r'href="(/[^"#?]*)"', body)):
        h = href.rstrip('/') or '/'
        check(h in known,
              f'{p or "/"} links to {href}, which is not a page on this site')
    # anchors must point at an id that exists on the same page
    for anchor in set(re.findall(r'href="#([A-Za-z][\w-]*)"', body)):
        check(f'id="{anchor}"' in body,
              f'{p or "/"} links to #{anchor}, and no element has that id')

# ---- the words people are told to reply ----------------------------------
# Each keyword, and every surface that is allowed to name it.
SURFACES = {
    'site:terms':     bodies.get('terms', ''),
    'site:privacy':   bodies.get('privacy', ''),
    'site:messaging': bodies.get('messaging', ''),
    'relay':          open(os.path.join(ROOT, 'channels/sms-relay.mjs')).read(),
    'agent':          open(os.path.join(ROOT,
                        'force-app/main/default/aiAuthoringBundles/Curb_Cut/Curb_Cut.agent')).read(),
    'standing':       open(os.path.join(ROOT,
                        'force-app/main/default/classes/CurbCutStanding.cls')).read(),
}

# OFF turns a preference off. It must never be described as STOP anywhere that
# talks about preferences, because STOP belongs to the carrier.
for name in ('site:terms', 'site:privacy', 'site:messaging'):
    body = SURFACES[name]
    if 'preference' in body.lower() or 'standing' in body.lower():
        check('OFF' in body,
              f'{name} discusses standing preferences without naming OFF as the way off')

# The three in-conversation words must be identical everywhere they appear.
for word, meaning in (('DELETE', 'discard a draft'),
                      ('OFF', 'turn off a preference'),
                      ('WHO', 'see who was shown it')):
    named_in = [n for n, b in SURFACES.items() if re.search(rf'\b{word}\b', b)]
    check(len(named_in) >= 2,
          f'{word} ({meaning}) is named on only {named_in}; a control nobody '
          f'mentions twice is a control nobody knows about')

# HELP and STOP are the carrier's, and the relay must answer both.
relay = SURFACES['relay']
for kw in ('help', 'stop'):
    check(f"'{kw}'" in relay, f'the relay does not recognise the reserved keyword {kw.upper()}')

# ---- the number is the same everywhere -----------------------------------
NUMBER = '+1 276 495 9311'
for name in ('site:terms', 'site:messaging'):
    check(NUMBER in SURFACES[name], f'{name} does not carry the programme number')
stray = set()
for name, body in SURFACES.items():
    for m in re.finditer(r'\+1[\s\-]?\d{3}[\s\-]?\d{3}[\s\-]?\d{4}', body):
        if m.group(0).replace('-', ' ') != NUMBER:
            stray.add(f'{name}: {m.group(0)}')
check(not stray, f'a different phone number appears somewhere: {sorted(stray)}')

print(f'{checks - len(fails)}/{checks} link and copy checks pass')
for f in fails:
    print(f'  FAIL  {f}')
sys.exit(1 if fails else 0)
