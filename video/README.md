# The demo film, as source

`curb-cut-demo.mp4` is generated. Nothing in it is a mock-up or a re-creation:
every product frame is a screenshot of the deployed site, captured by driving a
real browser through the real flow against the live org.

## Why it is silent

The film carries its own captions and has no soundtrack. That is a choice. A
film about access should not assume you can hear it, and a synthetic narrator
reading an emotional script badly is worse than no narrator. `submission/VIDEO-NARRATION.md`
has the script with timings if you want to record a human voice over it.

## One table drives everything

`script.py` holds the scene list: source, hold, and the line spoken over it.
`build_video.py` cuts the film from it and `narration.py` writes the script from
it, so the timings in the document cannot drift away from the timings in the
film. `script.fits()` fails if any line needs more time than its hold allows at
140 words per minute; that check caught a card asking for 42 words in 8 seconds,
which is 315 words per minute and unsayable.

## Rebuilding it

```bash
node flow.mjs      # drives /ask end to end on the live site, captures each state
node pages.mjs     # the other public pages, plus a phone
node cards.mjs     # the caption cards, SVG then PNG
python3 build_video.py
python3 narration.py
```

`cdp.mjs` is a small Chrome DevTools Protocol client. Node 22+ has a native
WebSocket, so it needs no dependencies. The Browser pane could not be used
because it caps the viewport well below 1080p; this drives headless Chrome at
1600x900 with a device scale factor of 2, which is a 3200x1800 source frame.
