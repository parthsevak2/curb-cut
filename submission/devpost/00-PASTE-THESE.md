# Devpost. Every field, in order

Character counts are under each limit. Nothing here is asserted from memory;
every figure was read from the deployed org on 4 September 2026.

---

## Project Name

Curb Cut

## Problem to solve

Thirty in a hundred college-educated people in white-collar jobs in the United
States have a disability. Three point two tell their employer. Of those who did
tell, 83% say it got them better support. So it works for five out of six who
try, and almost nobody tries. The accommodation is usually free: 61% of the ones
employers priced cost nothing. The money was never the barrier and the
willingness was never the barrier. The asking was. To get a chair that does not
hurt you must find the policy, learn its words, hold a work login, and write a
sentence about your own body for somebody who will still be your manager on
Monday. **The request form is itself an accessibility barrier.**

## Our solution

An Agentforce agent whose principal is the worker, not the employer. You say what
is *hard*, never why. You get real options from a sourced library with what each
typically costs, and a request written in your own words that will not send until
you clearly say yes, a hedge is refused. Five front doors (web, voice, email,
Slack, MCP) share one Apex router, so `OFF` cannot mean one thing on a phone and
another in an inbox. There is no field for a diagnosis anywhere in 61 fields, and
if you name a condition anyway it is stripped before anything is stored.

---

## Project assets

| Slot | What to paste |
|---|---|
| **Code** | `https://github.com/parthsevak2/curb-cut`. Flip public first |
| **Documentation** | https://claude.ai/code/artifact/80443669-bf1c-4365-883d-b0d1238b474a |
| **Video** | your YouTube/Vimeo link once recorded |
| Design | https://claude.ai/code/artifact/a9157ad2-d803-46ab-ba5e-0ef3f0d13ef5 |
| Presentation slides | upload `Curb-Cut.pptx`, paste the link |
| Prototype | https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut |

## Equality Group prompt

Abilityforce.

## Image

`hero-1500x900.svg` for the Devpost hero (5:3, above the 500x300 minimum), or
`cover-the-two-questions.svg` for a 1200x630 social card. Both show the same
request asked two ways. Open in any browser and screenshot, or run through any
SVG-to-PNG converter. Deliberately not a stock photograph of somebody looking
sad: the subject is the form, not the disabled person, and everyone who has
filled that box in recognises it instantly.

Eight screen mockups are in `mockups/`, every word captured from the deployed
org. `08-signed-video-no-captions.svg` is the newest and the most worth showing:
it is the accessibility fix the Salesforce tool prompted, drawn as the operator
actually sees it.

## The four long answers

- `Q1-accessibility.txt`, 4,000 characters
- `Q2-responsible-ai.txt`, 3,994 characters
- `Q3-error-rate.txt`, 3,182 characters
- `Q4-environmental.txt`, 3,536 characters

All four are paste-ready as-is. Do not add a heading or a preamble: each is
already at or just under the 4,000 character limit, and Devpost counts
everything you paste.

**Q1 is now a real tool run.** There is no Salesforce product published as
"Accessibility Expert Skill", but there is published Salesforce accessibility
expert tooling and we found it: the `lwc-experts` toolset in the Salesforce DX
MCP server (`@salesforce/mcp`), which stands up Sa11y, their own axe-core
matcher. Twelve component states, 131 checks, zero WCAG violations, two real
defects found and fixed. Q1 opens by naming exactly which tool was run, so a
judge can check the claim. Full write-up in `docs/A11Y-SA11Y-REPORT.md`.

**Q2 is still an honest gap.** There is no RAI Self Check under that name: not in
the org, not on AgentExchange, and not among the DX MCP server's fifteen
toolsets. Q2 says so in its first line, says we asked, and then gives our own
responsible-AI audit in the shape the question asks. If the organisers send the
tool, paste its findings to me and I will rework Q2 around them. Do not leave the
field blank and do not imply it was run.

## AI Fluency Track fields

NA

## Org credentials (judges only)

- Org ID `00DgK00000YIJ5SUAX`
- Instance `https://orgfarm-7a04c62cb9.my.salesforce.com`
- Username and password: yours to paste. Do not put them in the repo.
