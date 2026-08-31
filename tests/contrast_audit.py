#!/usr/bin/env python3
"""
Contrast audit, computed from the design tokens rather than trusted.

The site claims AAA body contrast. Claims about accessibility are exactly the
kind that rot silently: somebody nudges a grey to make a panel look calmer and
nobody notices that the help text under every form field just stopped being
readable for the people it was written for.

WCAG 2.1: AA needs 4.5:1 for body text and 3:1 for large text (>=24px, or
>=18.66px bold) and for UI component boundaries. AAA needs 7:1 and 4.5:1.
"""
import sys, re, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHELL = os.path.join(ROOT, 'force-app/main/default/components/CurbCutShell.component')

def srgb(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def luminance(hexcolour):
    h = hexcolour.lstrip('#')
    if len(h) == 3:
        h = ''.join(ch * 2 for ch in h)
    r, g, b = (int(h[i:i+2], 16) for i in (0, 2, 4))
    return 0.2126 * srgb(r) + 0.7152 * srgb(g) + 0.0722 * srgb(b)

def ratio(a, b):
    la, lb = luminance(a), luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)

def tokens(css, selector):
    """Pull the --name:#hex pairs out of one rule block."""
    i = css.find(selector)
    if i < 0:
        return {}
    block = css[i:css.index('}', i)]
    return {m.group(1): m.group(2)
            for m in re.finditer(r'--([a-z-]+)\s*:\s*(#[0-9A-Fa-f]{3,6})', block)}

src = open(SHELL).read()
LIGHT = tokens(src, ':root {')
DARK  = tokens(src, ':root[data-theme="dark"] {')

# (foreground token, background token, minimum, what it is)
PAIRS = [
    ('ink',       'ground',  7.0, 'body text on the page'),
    ('ink',       'raised',  7.0, 'body text on a card'),
    ('ink-soft',  'ground',  7.0, 'help text and secondary prose'),
    ('ink-soft',  'raised',  4.5, 'help text on a card'),
    ('ink-mute',  'ground',  4.5, 'labels and eyebrows'),
    ('deep',      'ground',  4.5, 'the confirming colour'),
    ('deep',      'deep-bg', 4.5, 'confirming text on its own wash'),
    ('signal',    'ground',  4.5, 'the attention colour'),
    ('signal',    'signal-bg', 4.5, 'attention text on its own wash'),
    ('alert',     'ground',  4.5, 'the refusing colour'),
    ('alert',     'alert-bg',  4.5, 'refusing text on its own wash'),
    ('focus',     'ground',  3.0, 'the focus ring against the page'),
    ('focus',     'raised',  3.0, 'the focus ring against a card'),
    ('line-firm', 'ground',  3.0, 'input borders, which must be perceivable'),
]

fails, checks = [], 0
for theme, t in (('light', LIGHT), ('dark', DARK)):
    if not t:
        fails.append(f'{theme}: no tokens found; the palette moved and this audit is blind')
        continue
    for fg, bg, need, what in PAIRS:
        checks += 1
        if fg not in t or bg not in t:
            fails.append(f'{theme}: token --{fg} or --{bg} is missing')
            continue
        r = ratio(t[fg], t[bg])
        if r < need:
            fails.append(f'{theme}: {what} — --{fg} on --{bg} is {r:.2f}:1, needs {need}:1')

print(f'{checks - len(fails)}/{checks} contrast checks pass (light and dark)')
for f in fails:
    print(f'  FAIL  {f}')
sys.exit(1 if fails else 0)
