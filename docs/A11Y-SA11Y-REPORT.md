# Accessibility audit: Salesforce Sa11y on the Curb Cut components

**Tool:** Sa11y, Salesforce's own accessibility matcher, driven by axe-core,
obtained through the Salesforce DX MCP server (`@salesforce/mcp`) and its
`lwc-experts` toolset. The two tools used were `guide_component_accessibility`
and `run_lwc_accessibility_jest_tests`.

**Ruleset:** the 100-rule `extended` preset, minus one rule, stated below.
Not the 64-rule `base` preset that Sa11y applies by default.

**Scope:** all five Lightning Web Components, in twelve states.
**Run:** `npm run test:a11y`

---

## Result

| | |
|---|---|
| States audited | 12 |
| axe checks passed | 131 |
| **WCAG violations** | **0** |
| Rules axe could not decide | 3 |
| Defects found and fixed | 2 |

Seven test suites, thirteen tests, all passing.

---

## The one rule removed, and why

`region` requires every piece of content to sit inside a landmark. It is an
axe **best-practice** rule and carries no WCAG tag. It fires 43 times here for a
single reason: a component mounted alone in a test has no page around it, so
there is no `<main>` for it to sit in. The landmark structure that satisfies
this rule lives on the Visualforce pages, which are checked by the separate
static accessibility suite.

It is excluded in `jest/a11y-ruleset.js`, in one place, with that reason written
next to it. Every other rule in `extended` is enforced.

## What axe could not decide

These came back `incomplete`, not `pass`. A green suite is not evidence about
them, and saying otherwise would be the easiest lie in this document.

**`color-contrast` and `color-contrast-enhanced`** — 12 states each.
axe measures contrast by painting to a canvas, and jsdom has no canvas:

```
Error: Not implemented: HTMLCanvasElement.prototype.getContext
    at Rule.colorContrastMatches (axe-core/axe.js:27292)
```

Contrast is therefore measured elsewhere, by computing WCAG relative luminance
directly from the stylesheets. That suite runs 28 checks and passes. The new
`.nocap` note added in this audit measures **10.59:1** against the card it sits
on, against a 4.5:1 requirement.

**`video-caption`** — 1 state. Discussed below; it is the finding that mattered.

**`aria-valid-attr-value`** — 1 state, caused by the fix below. axe cannot
follow an `aria-describedby` idref through LWC's synthetic shadow DOM. Rather
than leave that unanswered, a test asserts the reference resolves to a real
element containing real text. It does.

---

## Finding 1: a video that says nothing to the person who cannot watch it

`curbCutMediaViewer` renders signed video with no captions and no transcript.
axe returns `incomplete` on `video-caption` (WCAG 1.2.2) because it cannot
inspect the media, so the tool could not settle this. A person using a screen
reader could.

The obvious remedy is the forbidden one. This video is usually a Deaf person
signing, and the product's central promise is that signed video is never
machine translated — an auto-caption here would be a machine putting words in
someone's mouth about their own body, then filing them. The banner already says
so to the operator.

But the operator was the only one being told. Reaching the `<video>` element
itself, there was silence: no captions, and no explanation of the silence.

**Fixed.** Every video now carries an `aria-describedby` pointing at a note that
is on the page for everyone:

> No captions and no transcript, and none will be generated.
> This is waiting on a human interpreter.

That does not satisfy 1.2.2, and this report does not claim it does. It replaces
an unexplained absence with a stated one, which is the honest position while a
human interpretation is genuinely pending.

**Files:** `curbCutMediaViewer.html`, `.js`, `.css`

## Finding 2: the emergency form kept the last emergency's words

The LWC compiler flagged it during the first run:

```
LWC1057: value is not valid attribute for textarea
  curbCutEmergency/curbCutEmergency.html
```

`<textarea value={reason}>` does nothing. A textarea holds its text as a child
node, not an attribute. So `this.reason = ''` in the close path cleared the
field in JavaScript and left the words on screen.

This is the escalation form: the one place in Curb Cut that a telephone number
comes out of, used when somebody may be at risk. Stale text in that box after
closing an escalation invites the next one to be raised on the last one's words.

**Fixed.** The invalid attribute is gone, and closing an escalation now clears
the element as well as the field.

**Files:** `curbCutEmergency.html`, `.js`

---

## Proving the suite can fail

A suite that cannot fail proves nothing, so `jest/__tests__/harness-control.a11y.test.js`
plants `<img src="x.png">` with no alt text and asserts that the matcher throws.
It does. Every green result in this report is green against a harness that has
been shown to go red.

---

## What this audit does not cover

- No screen reader user has tested Curb Cut. Nothing here substitutes for that.
- jsdom is not a browser. Focus order, contrast as rendered, and media are
  checked by other means or not at all.
- The Visualforce public pages are outside Sa11y's reach; they have their own
  static suite.
