#!/usr/bin/env python3
"""
Does the submission agree with itself?

Twice in one day a number went stale in public while every other check stayed
green: the invariant count sat at 491 across the deck and four Devpost answers
after the suite grew to 494, and the slide count said 13 and then 24 while the
deck was 32. Both were found by eye, which is not a method.

So this reads the artefacts themselves rather than trusting prose about them.
It opens the pptx and counts slides. It measures each answer file. It asks the
scene table how long the film is. Then it checks that every claim made about
those things matches the thing itself.
"""
import os, re, sys, glob, json, zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def read(rel):
    try:
        with open(os.path.join(ROOT, rel), encoding='utf-8') as f: return f.read()
    except OSError: return ''

fails, checks = [], 0
def check(name, ok, detail=''):
    global checks
    checks += 1
    if not ok: fails.append((name, detail))

# ── the artefacts, measured ────────────────────────────────────────────────
deck = os.path.join(ROOT, 'submission/Curb-Cut.pptx')
slides = 0
if os.path.exists(deck):
    with zipfile.ZipFile(deck) as z:
        slides = len([n for n in z.namelist()
                      if re.match(r'ppt/slides/slide\d+\.xml$', n)])
check('deck-exists', slides > 0, 'submission/Curb-Cut.pptx is missing or empty')

answers = {}
for p in sorted(glob.glob(os.path.join(ROOT, 'submission/devpost/Q*.txt'))):
    answers[os.path.basename(p)] = len(open(p, encoding='utf-8').read())

# the film's length comes from the table that cuts it, not from a note somewhere
film = None
try:
    sys.path.insert(0, os.path.join(ROOT, 'video'))
    import script as filmscript          # the table that actually cuts the film
    film = filmscript.total()
except Exception:
    pass

# ── every long answer has to fit the box it is pasted into ────────────────
LIMIT = 4000
for name, n in answers.items():
    if name.startswith('Q0'): continue          # the short fields share another budget
    check('answer-fits-%s' % name, n <= LIMIT, f'{n} characters, limit {LIMIT}')

# the three description fields share one 5,000 character budget on the form
short = sum(n for k, n in answers.items() if k.startswith('Q0'))
check('description-block-fits', short <= 5000, f'{short} characters across Q0 files, limit 5000')

# ── claims about those artefacts must match them ──────────────────────────
CLAIMS = ['submission/INDEX.md', 'submission/RUN-REQUIRED-TOOLS.md',
          'submission/devpost/00-PASTE-THESE.md', 'submission/DEVPOST-ANSWERS.md',
          'submission/JUDGE-TEST-GUIDE.md', 'docs/A11Y-SA11Y-REPORT.md']

bad = []
for rel in CLAIMS:
    for m in re.finditer(r'(\d{1,3})\s+slides', read(rel)):
        if int(m.group(1)) != slides: bad.append(f'{rel} says {m.group(1)} slides')
check('slide-count-claims-are-current', not bad, f'the deck has {slides}: ' + '; '.join(bad))

bad = []
for rel in CLAIMS + ['submission/VIDEO-NARRATION.md']:
    txt = read(rel)
    for m in re.finditer(r'\b(\d):(\d\d)\b(?!\d)', txt):
        # only lines that are talking about the film
        line = txt[max(0, m.start()-70):m.end()+10]
        if not re.search(r'run ?time|runs? for|length|\bfilm is\b|\bvideo is\b', line, re.I):
            continue
        claimed = int(m.group(1)) * 60 + int(m.group(2))
        if film and abs(claimed - film) > 1:
            bad.append(f'{rel} says {m.group(0)}')
check('film-length-claims-are-current',
      not bad, f'the cut is {int(film//60)}:{int(film%60)}: ' + '; '.join(bad) if film else '')

# character counts quoted next to an answer name must be that answer's length
bad = []
for rel in CLAIMS:
    txt = read(rel)
    for m in re.finditer(r'(Q[1-4])[^\n]{0,80}?([\d,]{3,6})\s*characters', txt):
        q = [k for k in answers if k.startswith(m.group(1))]
        if not q: continue
        if int(m.group(2).replace(',', '')) != answers[q[0]]:
            bad.append(f'{rel} says {m.group(1)} is {m.group(2)}, it is {answers[q[0]]}')
check('answer-length-claims-are-current', not bad, '; '.join(bad))

# ── nothing half-finished should reach a judge ────────────────────────────
PLACEHOLDER = re.compile(r'\bTODO\b|\bTBD\b|\bFIXME\b|\bXXX\b|lorem ipsum|https://t\.com', re.I)
bad = []
for rel in CLAIMS + list('submission/devpost/' + a for a in answers):
    for m in PLACEHOLDER.finditer(read(rel)):
        # the guide is allowed to name the placeholder it is telling you to replace
        ctx = read(rel)[max(0, m.start()-70):m.end()+40]
        if 'placeholder' in ctx.lower() or 'should be' in ctx.lower(): continue
        bad.append(f'{rel}: {m.group(0)}')
check('no-placeholders-left', not bad, '; '.join(bad))

# one repository, spelled one way
owners = set(re.findall(r'github\.com/([\w-]+)/curb-cut', '\n'.join(read(r) for r in CLAIMS)))
check('one-repository-url', len(owners) <= 1, f'referred to as {owners}')

print('%d/%d submission consistency checks pass' % (checks - len(fails), checks))
for n, d in fails:
    print('  FAIL  %s: %s' % (n, d))
print('\n  deck %d slides | film %s | answers %s'
      % (slides,
         ('%d:%02d' % (film//60, film%60)) if film else 'unknown',
         ', '.join('%s %d' % (k[:2], v) for k, v in sorted(answers.items()))))
sys.exit(1 if fails else 0)
