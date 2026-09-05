# The two tools that gate the submission

> *"Every team must run both the Accessibility Expert Skill and the RAI Self Check
> Skill from the AI Expert Suite. In your submission, describe what each tool
> flagged and how your team responded. **Judges evaluate your engagement with the
> findings, not a perfect score.**"*

That last sentence is the whole game. A finding you engaged with honestly scores
better than a clean run. Do not tune for a green.

**Status: one done, one outstanding.**

---

## 1. Accessibility. Done, and it found two real things

There is no Salesforce product published under the name "Accessibility Expert
Skill". There *is* published Salesforce accessibility expert tooling, and it is
public, installable and GA:

| | |
|---|---|
| Package | `@salesforce/mcp`, the Salesforce DX MCP server |
| Toolset | `lwc-experts` |
| Tools run | `guide_component_accessibility`, `run_lwc_accessibility_jest_tests` |
| What they set up | Sa11y, Salesforce's own axe-core accessibility matcher |
| Re-run it | `npm run test:a11y` |

**Result:** 12 component states, 131 axe checks passed, 0 WCAG violations,
against the 100-rule `extended` preset rather than the 64-rule `base` preset
Sa11y applies by default. Seven suites, fourteen tests.

**Two defects found and fixed:**

1. **A video that said nothing to the person who could not watch it.** axe
   returned `incomplete` on `video-caption` (WCAG 1.2.2), not a pass, because it
   cannot inspect media inside a test runner. The obvious remedy was the
   forbidden one: that video is usually a Deaf person signing, and a machine
   caption would put words in somebody's mouth about their own body and then
   file them. Every video now carries an `aria-describedby` note saying there are
   no captions, none are coming, and a human interpreter is what it waits on.

2. **`LWC1057`,** from the compiler rather than axe. `<textarea value={...}>`
   does nothing, so closing an escalation left the previous emergency's words on
   screen, on the one screen in Curb Cut that produces a telephone number.

**Also recorded honestly:** `color-contrast` came back `incomplete` in all twelve
states, because axe measures contrast by painting to a canvas and jsdom has none.
Reported as undecided rather than banked as a pass. Contrast is measured
separately by computing WCAG relative luminance from the stylesheets: 28 checks.

Full write-up: `../docs/A11Y-SA11Y-REPORT.md`
Raw findings: `../docs/a11y-sa11y-findings.json`
Devpost answer: `devpost/Q1-accessibility.txt`, paste-ready at 4,000 characters.

---

## 2. RAI Self Check. Still missing, and it needs you

Searched thoroughly and found nothing. Not installed in the provisioned org, not
on AgentExchange, and not among the fifteen toolsets the DX MCP server publishes,
which cover accessibility, security, code analysis, mobile and DevOps but include
no responsible-AI self check.

Conclusion: if it exists it is distributed to participants directly, through the
hackathon Slack sandbox or the Devpost resources page. Both need your login.

**What to do, five minutes, in parallel:** send `devpost/ASK-THE-ORGANISERS.txt`
to all three at once.

1. The hackathon Slack sandbox, in the channel signposted for support.
2. Devpost, hackathon page, Additional details, Support Channel & Resources.
3. The organisers named on the page: Alexandra Iyer and Megan Alfaro.

Do not wait for one before trying the next. Asking in parallel costs nothing and
the deadline does not move.

**The moment anything comes back,** send it to me. Most useful is the skill's own
instructions in any form: if I can see what it checks, I can run it whether or
not I can install it.

**Meanwhile we ran the exercise anyway.** `tests/rai_self_check.py` audits Curb
Cut against Salesforce's own five published guidelines for responsible agentic
AI: Accuracy, Safety, Honesty, Empowerment, Sustainability. 21 checks, 19 pass,
0 fail, 2 undecided, and `--selftest` breaks four of them on purpose to prove
they can go red.

It found a real defect on its first run: the seed file in this repository could
no longer rebuild the deployed library. The org held 28 rows, the seed held 24,
and the four missing ones were exactly the lighting rows added to fix an earlier
bias defect. Anyone deploying from our code would have silently reintroduced it.
Fixed, and a check now compares the two on every run.

`devpost/Q2-responsible-ai.txt` is written around that finding, 3,798 characters.
It still opens by saying we could not find the named tool. Do not leave the field
blank and do not imply the tool was run.

---

## What to point any tool at

| Input | Value |
|---|---|
| Public site | `https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut` |
| The page that matters most | `…/curbcut/ask` |
| Org | `00DgK00000YIJ5SUAX` |
| Agent | `Curb_Cut`, Active at v7 |
| Internal agent | `Curb_Cut_Desk`, Active at v5 |
| Console app | Curb Cut Console |

If the tool takes one URL, give it `/ask`. That is the page somebody uses on a
hard day, and it is where a finding matters most.

## Where they will probably still find something real

Be ready for these, and do not be defensive:

- **No screen-reader user has tested this.** Machine-verified is not
  user-verified, and the evidence page says so already.
- **The agent's narration is nondeterministic.** 21 of 23 assertions across three
  runs, with one failure that alternates.
- **The console has had less accessibility attention than the public site,**
  because the public site is where somebody arrives on a bad day.
- **The Slack app has never run against a real workspace.**
