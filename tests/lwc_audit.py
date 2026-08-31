#!/usr/bin/env python3
"""
Accessibility audit of the Lightning Web Components.

The public site is audited against what it actually serves. The console cannot
be, because it is behind a login, so these components are audited from source.
Everything checked here is a failure an operator using a screen reader or a
keyboard would hit, and the console is where the people who answer spend their
day.
"""
import sys, re, os, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LWC = os.path.join(ROOT, 'force-app/main/default/lwc')

fails, warns, checks = [], [], 0
def check(name, ok, detail, hard=True):
    global checks
    checks += 1
    if not ok:
        (fails if hard else warns).append(f'{name}: {detail}')

for d in sorted(glob.glob(os.path.join(LWC, '*'))):
    if not os.path.isdir(d):
        continue
    name = os.path.basename(d)
    html_path = os.path.join(d, f'{name}.html')
    js_path = os.path.join(d, f'{name}.js')
    if not os.path.exists(html_path):
        continue
    html = open(html_path).read()
    js = open(js_path).read() if os.path.exists(js_path) else ''

    # --- a control that shows and hides content must say which it is doing ---
    for m in re.finditer(r'<button\b[^>]*>', html):
        tag = m.group(0)
        # heuristic: a button whose handler flips a boolean used by an if:true
        if re.search(r'onclick=\{(toggle|open|expand|show|hide)\w*\}', tag):
            check(name, 'aria-expanded' in tag,
                  'a disclosure button has no aria-expanded, so a screen reader '
                  'cannot tell whether the section is open')

    # --- clickable things must be real controls ---
    for m in re.finditer(r'<(div|span|p|li|img)\b[^>]*onclick=', html):
        check(name, False,
              f'<{m.group(1)}> has an onclick; a div is not reachable by keyboard '
              f'and is not announced as a control')

    # --- images ---
    for m in re.finditer(r'<img\b[^>]*>', html):
        check(name, 'alt=' in m.group(0), f'<img> with no alt attribute')

    # --- media needs a stated text alternative or a documented reason ---
    for m in re.finditer(r'<video\b[^>]*>', html):
        has_track = '<track' in html
        documented = 'never machine translated' in html.lower() or \
                     'do not machine translate' in html.lower()
        check(name, has_track or documented,
              'a <video> with no captions track and no explanation of why there '
              'are none')

    # --- inputs need names ---
    for m in re.finditer(r'<(input|textarea|select)\b[^>]*>', html):
        tag = m.group(0)
        if 'type="hidden"' in tag:
            continue
        idm = re.search(r'\bid="([^"]+)"', tag)
        labelled = (idm and f'for="{idm.group(1)}"' in html) \
                   or 'aria-label' in tag or 'aria-labelledby' in tag
        check(name, labelled,
              f'<{m.group(1)}> has no label, aria-label or aria-labelledby')

    # --- headings inside a component are never the page heading ---
    for m in re.finditer(r'<h1\b', html):
        check(name, False,
              'uses an h1; a component sits inside a page that already has one')

    # --- no positive tabindex, ever ---
    for m in re.finditer(r'tabindex="(\d+)"', html):
        check(name, int(m.group(1)) <= 0,
              f'tabindex="{m.group(1)}" reorders the tab sequence for everyone')

    # --- asynchronous work must be announced ---
    does_async = 'await ' in js or 'refreshApex' in js
    if does_async:
        announces = 'role="status"' in html or 'aria-live' in html \
                    or 'ShowToastEvent' in js
        check(name, announces,
              'does asynchronous work but never announces the outcome; a screen '
              'reader user presses a button and hears nothing')

    # --- colour must never be the only carrier of state ---
    if 'data-tone' in html or re.search(r'class=\{[^}]*tone', html):
        # a tone attribute is fine as long as words accompany it
        has_words = re.search(r'\{(\w*note|\w*Note|\w*Line|why|label)\}', html) is not None
        check(name, has_words,
              'uses a tone/colour attribute with no accompanying words; an '
              'operator with a colour vision difference reads nothing from it')

print(f'{checks - len(fails)}/{checks} component accessibility checks pass')
for w in warns:
    print(f'  WARN  {w}')
for f in fails:
    print(f'  FAIL  {f}')
sys.exit(1 if fails else 0)
