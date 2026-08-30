# Self-critique — 30 August 2026

Written against the build, not the pitch. Everything here is a real weakness.

## Fixed this round

**Substring matching was recommending irrelevant accommodations.**
`CurbCutOptions` scored options with `haystack.contains(keyword)`. The word
`long` is inside `alongside`, so someone who said they could not type for long
was offered *visual fire and safety alerts*. Grounded, correctly cited, and
completely irrelevant. An irrelevant suggestion is not a harmless miss: it tells
someone already having a hard week that they were not heard. Now matches whole
words only, with a regression test named after the bug.

**The scorer reported a false failure.** The rule "does not echo the diagnosis"
matched the phrase *your condition* inside the agent's own correct refusal,
"I did not record your condition." A false failure is as damaging as a false
pass; both hide the truth. The rule now strips the refusal before testing.

**The live agent contradicted the published Terms.** Terms promised `DELETE` and
`OFF`; the running agent still said `STOP`. A legal document that disagrees with
the running system is worse than no document. v6 is active and matches.

**An orphaned Apex class was dragging org coverage.** `CurbCutUrlRewriter` was
deleted locally but left in the org. Removed.

**A statistic was overstated.** A draft of the footer read "one in three working
North Americans". The Statistics Canada figure is 35.4% of *employed Canadians
with a disability*. On a project whose entire argument is not inventing figures,
that would have been self-refuting.

## Still weak

**One real channel, not four.** SMS and voice are built and tested. Video and
image are described in the design and routed in the agent script, but nothing
receives them yet. The site is a set of documents, not an agent surface: someone
with no phone at all still cannot start a conversation. That is the largest
remaining gap against the accessibility argument, and it is the next thing worth
building.

**Barrier reports are still not written.** `log_barrier` is bound, unit-tested
and live, and the agent does not call it during consult. Every conversation
leaves no intake record. Tests pass because they call the Apex directly.

**Visualforce, and why.** Not a preference. `Network`, `ExperienceBundle` and
`DigitalExperienceConfig` are all unavailable in this org, so Experience Cloud
and LWR cannot be created here at all. `CustomSite` plus `ApexPage` is the only
public-site mechanism available. `LightningComponentBundle` does deploy, so LWC
inside the Site is the upgrade path if Digital Experiences is ever licensed.

**The library is 14 rows.** Enough to demonstrate grounding, not enough to serve
anyone. Statistics Canada names modified hours, modified duties, working from
home, ergonomic workstation and back support as the top five needs; only some of
those are in the library.

**No accessibility audit by a person who needs it.** Every claim on the site
about screen readers, keyboard use and contrast is mine, tested by me. The spec
is right that one sentence from one real worker beats every production choice
available. That has not happened.

## Sources, verified against the live pages

- Job Accommodation Network employer survey, 1 Jan 2019 – 31 Dec 2024,
  5,406 employer responses. 61% no cost; median one-time cost $300.
  askjan.org/topics/costs.cfm
- Statistics Canada, Canadian Survey on Disability, 2022. 35.4% of employed
  Canadians with disabilities had an unmet accommodation need. Top need:
  modified work hours, 16.3%.
- Government of Canada Workplace Accessibility Passport. Belongs to the
  employee, moves with them across the federal public service, avoids repeated
  requests for documentation. Precedent for "ask once, not forever" — and
  available only to federal public servants.
