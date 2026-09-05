#!/usr/bin/env python3
"""
Accessibility audit of the live public pages.

Not a substitute for a person who uses a screen reader every day — nothing is.
But every check here is a failure that a real user would hit, and running it
against the deployed HTML rather than the source means it catches what actually
ships, including anything Visualforce rewrites on the way out.

Exits non-zero on any error. Warnings are printed and do not fail.
"""
import sys, re, urllib.request, html
from html.parser import HTMLParser

SITE = "https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut"
PAGES = ["", "ask", "why", "messaging", "privacy", "terms", "docs"]

errors, warnings, checked = [], [], 0

def err(page, rule, detail):
    errors.append(f"{page or '/'}  [{rule}]  {detail}")

def warn(page, rule, detail):
    warnings.append(f"{page or '/'}  [{rule}]  {detail}")

class Doc(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.tags = []            # (tag, attrs dict, position)
        self.text_by_tag = {}     # id(tag tuple) -> text
        self._stack = []
        self.headings = []        # (level, text)
        self.labels = []          # (for, text)
        self.controls = []        # (tag, attrs)
        self.imgs = []
        self.links = []           # (href, text)
        self.buttons = []         # (attrs, text)
        self.ids = []
        self.html_attrs = {}
        self.title = None
        self._in_title = False
        self._cur = None

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if a.get('id'):
            self.ids.append(a['id'])
        if tag == 'html':
            self.html_attrs = a
        if tag == 'title':
            self._in_title = True
        if re.fullmatch(r'h[1-6]', tag):
            self._cur = ('heading', int(tag[1]), [])
            self._stack.append(self._cur)
        elif tag == 'label':
            self._cur = ('label', a.get('for'), [])
            self._stack.append(self._cur)
        elif tag == 'a':
            self._cur = ('link', a, [])
            self._stack.append(self._cur)
        elif tag == 'button':
            self._cur = ('button', a, [])
            self._stack.append(self._cur)
        elif tag in ('input', 'select', 'textarea'):
            self.controls.append((tag, a))
        elif tag == 'img':
            self.imgs.append(a)

    def handle_endtag(self, tag):
        if tag == 'title':
            self._in_title = False
        if self._stack and (
            (re.fullmatch(r'h[1-6]', tag) and self._stack[-1][0] == 'heading') or
            (tag == 'label' and self._stack[-1][0] == 'label') or
            (tag == 'a' and self._stack[-1][0] == 'link') or
            (tag == 'button' and self._stack[-1][0] == 'button')):
            kind, meta, buf = self._stack.pop()
            text = ' '.join(''.join(buf).split())
            if kind == 'heading': self.headings.append((meta, text))
            elif kind == 'label': self.labels.append((meta, text))
            elif kind == 'link':  self.links.append((meta, text))
            elif kind == 'button': self.buttons.append((meta, text))

    def handle_data(self, data):
        if self._in_title:
            self.title = (self.title or '') + data
        for frame in self._stack:
            frame[2].append(data)

def audit(page, raw):
    global checked
    d = Doc(); d.feed(raw)

    def check(rule, ok, detail, hard=True):
        global checked
        checked += 1
        if not ok:
            (err if hard else warn)(page, rule, detail)

    # --- document ---
    check('lang', bool(d.html_attrs.get('lang')),
          'html element has no lang attribute; a screen reader guesses the language')
    check('title', bool(d.title and d.title.strip()),
          'page has no title; it is the first thing announced')

    # --- headings ---
    h1s = [t for lvl, t in d.headings if lvl == 1]
    check('one-h1', len(h1s) == 1,
          f'{len(h1s)} h1 elements; a page should have exactly one')
    levels = [lvl for lvl, _ in d.headings]
    for i in range(1, len(levels)):
        if levels[i] - levels[i-1] > 1:
            check('heading-order', False,
                  f'jumps from h{levels[i-1]} to h{levels[i]} '
                  f'("{d.headings[i][1][:40]}"); screen reader users navigate by these')
            break
    else:
        check('heading-order', True, '')
    for lvl, t in d.headings:
        check('heading-not-empty', bool(t.strip()), f'empty h{lvl}')

    # --- form controls ---
    label_for = {f for f, _ in d.labels if f}
    for tag, a in d.controls:
        if a.get('type') in ('hidden', 'submit', 'button', 'reset'):
            continue
        cid = a.get('id')
        named = (cid and cid in label_for) or a.get('aria-label') or a.get('aria-labelledby')
        check('control-has-label', bool(named),
              f'<{tag}> id={cid!r} has no label, aria-label or aria-labelledby')
        if a.get('aria-describedby'):
            for ref in a['aria-describedby'].split():
                check('describedby-resolves', ref in d.ids,
                      f'<{tag}> aria-describedby="{ref}" points at nothing')
        if a.get('aria-labelledby'):
            for ref in a['aria-labelledby'].split():
                check('labelledby-resolves', ref in d.ids,
                      f'<{tag}> aria-labelledby="{ref}" points at nothing')

    for f, text in d.labels:
        if f:
            check('label-resolves', f in d.ids,
                  f'<label for="{f}"> points at no such element')
        check('label-not-empty', bool(text.strip()), f'empty <label for="{f}">')

    # --- images ---
    for a in d.imgs:
        check('img-alt', 'alt' in a, f'<img src="{a.get("src","?")[:40]}"> has no alt attribute')

    # --- links and buttons ---
    for a, text in d.links:
        href = a.get('href', '')
        name = text or a.get('aria-label') or a.get('title') or ''
        check('link-has-name', bool(name.strip()),
              f'<a href="{href[:40]}"> has no accessible name')
        if name.strip().lower() in ('click here', 'here', 'read more', 'more', 'link'):
            check('link-name-meaningful', False,
                  f'link text "{name}" means nothing out of context', hard=False)
        if href.startswith('http') and 'salesforce-sites.com' not in href:
            check('external-link-flagged', 'target' not in a or a.get('rel'),
                  f'external link {href[:40]} opens without rel', hard=False)

    for a, text in d.buttons:
        name = text or a.get('aria-label') or a.get('title') or ''
        check('button-has-name', bool(name.strip()),
              f'<button> id={a.get("id")!r} has no accessible name')

    # --- duplicate ids break every aria reference on the page ---
    dupes = {i for i in d.ids if d.ids.count(i) > 1}
    check('unique-ids', not dupes, f'duplicate id(s): {sorted(dupes)}')

    # --- aria-current must be a valid token, not a stray string ---
    for m in re.finditer(r'aria-current="([^"]*)"', raw):
        check('aria-current-token',
              m.group(1) in ('page', 'step', 'location', 'date', 'time', 'true', 'false'),
              f'aria-current="{m.group(1)}" is not a valid token')

    # --- live regions, but only where something actually changes ---
    # A static policy page needs no live region and flagging one taught nothing.
    interactive = any(tag in ('input', 'select', 'textarea') for tag, _ in d.controls) \
                  or bool(d.buttons)
    if interactive:
        check('has-live-region', 'aria-live' in raw or 'role="status"' in raw,
              'page has controls that change things but no live region; results are '
              'announced to nobody')

    # --- skip link, landmarks ---
    check('skip-link', 'class="skip"' in raw or 'skip to' in raw.lower(),
          'no skip link; keyboard users walk the whole nav on every page')
    check('main-landmark', '<main' in raw, 'no <main> landmark')

    # --- every section is a named landmark ---------------------------------
    # A <section> with no accessible name is announced as an anonymous "region".
    # Four of six on /ask were named and two were not, so somebody navigating by
    # landmark heard "region" twice with nothing to tell them apart.
    for m in re.finditer(r'<section\b([^>]*)>', raw):
        attrs = m.group(1)
        named = ('aria-label=' in attrs) or ('aria-labelledby=' in attrs)
        check('section-is-named', named,
              'a <section> has no aria-label or aria-labelledby, so it becomes '
              'an unnamed region: <section' + attrs[:70] + '>')

    # --- status regions replace their content wholesale --------------------
    # Without aria-atomic a screen reader may announce only the changed
    # fragment of a rewritten status line, which reads as nonsense.
    for m in re.finditer(r'<[^>]*role="status"[^>]*>', raw):
        check('status-is-atomic', 'aria-atomic' in m.group(0),
              'a role="status" region has no aria-atomic, so a rewritten '
              'message may be announced in fragments: ' + m.group(0)[:80])

    # --- viewport must not block zoom ---
    vp = re.search(r'<meta[^>]+name="viewport"[^>]*>', raw)
    if vp:
        check('zoom-not-blocked',
              'user-scalable=no' not in vp.group(0) and 'maximum-scale=1' not in vp.group(0),
              'viewport blocks zoom; people who need 200% cannot get it')

    # --- reduced motion must be honoured if anything animates ---
    if '@keyframes' in raw or 'animation:' in raw:
        check('reduced-motion', 'prefers-reduced-motion' in raw,
              'page animates without honouring prefers-reduced-motion')

for p in PAGES:
    url = f"{SITE}/{p}" if p else f"{SITE}/"
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            body = r.read().decode('utf-8', 'replace')
            if r.status != 200:
                err(p, 'reachable', f'HTTP {r.status}')
                continue
    except Exception as e:
        err(p, 'reachable', f'could not fetch: {e}')
        continue
    audit(p, body)

print(f'{checked - len(errors)}/{checked} accessibility checks pass across {len(PAGES)} pages')
for w in warnings:
    print(f'  WARN  {w}')
for e in errors:
    print(f'  FAIL  {e}')
sys.exit(1 if errors else 0)
