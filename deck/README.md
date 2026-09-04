# The deck, as source

`submission/Curb-Cut.pptx` is generated, not hand-edited. The source is
`build.js`, so a number in the deck can be checked against the same test run
that produces it, and the deck can be rebuilt by anyone.

```bash
cd deck && npm install pptxgenjs && node build.js
python3 qa.py        # nothing off-slide, nothing overflowing its box
python3 overlap.py   # no two text boxes colliding
```

Then recompress. pptxgenjs writes every package part STORED rather than
DEFLATED, which is a 546KB file instead of a 113KB one. Note that rezipping with
`writestr(zipinfo, ...)` inherits `compress_type` from the source entry and
silently does nothing; the type has to be set explicitly.

To see it rendered, rather than trusting the geometry checks:

```bash
soffice --headless --convert-to pdf --outdir . Curb-Cut.pptx
pdftoppm -png -r 90 Curb-Cut.pdf slide
```

Two habits worth keeping. Run `qa.py` and `overlap.py` after every edit, because
moving one box to fix a collision reliably creates another. And render it before
believing it: a count in this deck was stale for three commits while every
geometry check passed, because geometry cannot tell you a number is wrong.
