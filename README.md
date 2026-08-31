# Curb Cut

**The process for requesting a disability accommodation is itself an accessibility barrier.**

To get help you must first navigate a system designed by and for people without
your disability. Find the policy. Learn its vocabulary. Hold a corporate login.
Complete a form. And disclose something you may be afraid to disclose — to a
stranger, in writing, in a language that may not be your first.

The money was never the barrier.

| Evidence | Source |
|---|---|
| **61 of every 100** accommodations cost the employer nothing. Median one-time cost of the rest: **$300**. | [JAN employer survey](https://askjan.org/topics/costs.cfm), 5,406 employers, Jan 2019 – Dec 2024 |
| **More than a third** of employed Canadians with a disability had an accommodation need **go unmet** in 2022. | [Statistics Canada](https://www.statcan.gc.ca/o1/en/plus/7142-more-canadians-disabilities-workforce-unmet-accommodation-needs-among-barriers-equity), Canadian Survey on Disability |
| The **GC Workplace Accessibility Passport** already implements "ask once, not forever" — and only for federal public servants. | [Government of Canada](https://www.canada.ca/en/government/publicservice/wellness-inclusion-diversity-public-service/diversity-inclusion-public-service/accessibility-public-service/government-canada-workplace-accessibility-passport.html) |

Curb Cut is an Agentforce agent whose principal is **the worker, not the employer**.

---

## Live now

| Surface | Address | State |
|---|---|---|
| Web | https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut | live |
| Ask (full journey, no phone) | `/curbcut/ask` | live |
| Privacy | `/curbcut/privacy` | live |
| Terms | `/curbcut/terms` | live |
| SMS | +1 276 495 9311 | built; awaiting A2P 10DLC approval |
| Voice | +1 276 495 9311 | built, speech in and out |
| Email | `curbcut@…apex.salesforce.com` (see `channels/.env.example`) | live |
| Agent | Curb Cut v6 | active |
| Console (internal) | `/lightning/app/Curb_Cut_Console` | live |
| Why now | `/curbcut/why` | live |
| Messaging programme | `/curbcut/messaging` | live |
| MCP server | `node channels/mcp-server.mjs` | 3 tools, none of which can send |

The console is the half of this that nobody demos. Every promise the assistant
makes about a person reaching a human being is worthless unless a human being
has somewhere to stand. `Human_Handoff__c` was creating records that said
"a person is picking this up" with no surface for that person.

| Console surface | What it is for |
|---|---|
| **On Duty** (app home) | Three queues in the order they should be worked, with standing orders above them |
| Waiting for a person | Someone asked for a human and is currently getting silence |
| Awaiting a decision | Approved requests an employer has not answered, nearest deadline first |
| Needs an interpreter | Signed video, waiting on a person, never machine translated |
| Curb Cut Overview (dashboard) | Where the system is failing people, in five panels |
| Record feeds | Two people often work one request, so the conversation lives on the record |

Nothing in the console shows a diagnosis, because there is no field for one.
An operator who is asked what a person has can only answer that nobody knows
and nobody can find out.

## The four principles

1. **The agent's principal is the worker.** Nothing leaves that the person did not personally approve.
2. **No channel is the real one.** Text, voice, email and web are equal front doors.
3. **Ask before you disclose.** A real answer without identifying yourself or naming anything about your body.
4. **Ask once, not forever.** Standing preferences travel ahead of you.

## What is deliberately not built

- **No automated sign language.** ASL is a complete language; recognition is unsolved. Signed video routes to a human, with immediate text acknowledgement so nobody waits in silence.
- **No diagnosis field.** Not encrypted, not restricted — absent. CI fails the build if anyone adds one.
- **No phone fallback, ever.** `Reachable_By__c` is hard-coded to message.
- **No inference.** Nothing is profiled or predicted. Every signal is one the person set.

## Verification

```
42+ Apex tests           100% pass, 89% org-wide coverage
110 CI invariants        every one proven to fail on violation
23 adversarial assertions  run headless against the live agent
```

```bash
python3 tests/invariants.py                 # ~1s, no org needed
sf apex run test --test-level RunLocalTests --target-org curbcut
node tests/headless_agent_api.mjs && python3 tests/score_adversarial.py
```

## Repository map

| Path | What |
|---|---|
| `force-app/main/default/objects/` | 8 objects, 46 fields, 5 triage list views |
| `force-app/main/default/classes/` | 11 Apex classes + 6 test classes, 56 tests |
| `force-app/main/default/aiAuthoringBundles/` | the Agent Script |
| `force-app/main/default/pages/` `components/` `sites/` | the public site |
| `force-app/main/default/emailservices/` | inbound email channel |
| `force-app/main/default/applications/` `tabs/` `flexipages/` | the internal console |
| `force-app/main/default/reports/` `dashboards/` | five reports and the overview dashboard |
| `channels/` | SMS + voice relay, MCP server, Twilio configuration and A2P copy |
| `tests/` | invariants, adversarial suite, headless runner, scorer |
| `submission/` | shot list, submission text |
| `legal/` | privacy and terms source |
| `docs/` | architecture, BRD, roadmap, decisions |

Start with [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), then
[`CRITIQUE.md`](CRITIQUE.md) — which is where the honest list of what is still
weak lives.

## Documentation

| Document | Purpose |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | How it fits together, with diagrams |
| [`docs/BRD.md`](docs/BRD.md) | Business requirements and traceability |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | What is next, and what was rejected |
| [`docs/DECISIONS.md`](docs/DECISIONS.md) | Every significant call and why |
| [`docs/EVIDENCE.md`](docs/EVIDENCE.md) | Every public figure, with source, denominator and caveat |
| [`docs/AGENT-INTERFACES.md`](docs/AGENT-INTERFACES.md) | Headless, MCP, agent-to-agent, and the profile we will not build |
| [`CRITIQUE.md`](CRITIQUE.md) | What is still wrong |
| [`SPEC-CONFORMANCE.md`](SPEC-CONFORMANCE.md) | Build spec conformance |
| [`FINDINGS.md`](FINDINGS.md) | Adversarial run results |
| [`CI.md`](CI.md) | Pipeline and invariants |
| [`DEPLOY.md`](DEPLOY.md) | Deployment |
| [`TESTING.md`](TESTING.md) | Test strategy |

---

Built by Parth Sevak. Welland, Ontario, Canada.
Agentforce for Good, Dreamforce 2026 · Builder Track · Abilityforce.
