# Evidence

Every number Curb Cut states in public, with its source, its date, its
denominator, and what it does **not** say.

This file exists because the project's whole argument is that claims should be
checkable. A statistic quoted without its denominator is a claim you cannot
check, and we shipped one: the home page cited "61 out of every 100" against a
sample of 5,406 employer responses. The 61% is real, but it is of the 1,425
employers who actually gave cost figures. That is corrected in the site copy
and recorded here rather than quietly fixed.

Reviewed 30 August 2026.

---

## 1. What accommodations cost

**Source:** Job Accommodation Network, *Costs and Benefits of Accommodations*,
survey of employers who contacted JAN between 1 January 2019 and 31 December
2024. <https://askjan.org/topics/costs.cfm>

| Figure | Value |
|---|---|
| Employers surveyed | 26,028 |
| Employers who responded | 5,406 |
| Respondents who gave cost information | 1,425 (26% of respondents) |
| **Of those 1,425: cost nothing** | **61%** |
| One-time cost | 33%, median **$300** |
| Ongoing cost | 6%, median **$2,400 per year** |
| Very or extremely effective | 66% of 2,069 answering |
| Somewhat effective | 22% |
| **Ineffective** | **12%** |
| Cited increased employee retention | 85% |

**What this does not say.** It is not a random sample of employers. Everyone in
it had already contacted JAN for accommodation guidance, so they are employers
already trying. It describes employers in general and says nothing about any
particular employer. And 12% of accommodations did not work, which we state
because a page that only quotes the 66% is selling something.

## 2. How many people never ask

| Figure | Value | Source |
|---|---|---|
| US college-educated, white-collar employees aged 21–65 with a disability | **30%** | Coqual, *Disabilities and Inclusion* <https://coqual.org/reports/disabilities-and-inclusion/> |
| Of those, share who disclose to their employer | **3.2%** | same |
| Disabled employees who did not disclose | 62% | National Organization on Disability |
| Would disclose at the recruitment stage | 23% | industry survey, 2025 |
| Of those who did disclose, felt it got them better support | **83%** | same |

**Why this pairing is the argument.** Disclosure overwhelmingly helps the people
who do it, and almost nobody does it. The barrier is not the outcome. The
barrier is the act of telling someone.

**What this does not say.** The 30% figure uses the broad US federal definition
of disability, which is wider than most people's self-image, and that is part of
the point rather than a flaw. The 3.2% is disclosure *to an employer*, not to
anyone.

## 3. Unmet need

| Figure | Value | Source |
|---|---|---|
| Employed Canadians with a disability who had an unmet accommodation need, 2022 | **more than one third** | Statistics Canada, Canadian Survey on Disability <https://www.statcan.gc.ca/o1/en/plus/7142-more-canadians-disabilities-workforce-unmet-accommodation-needs-among-barriers-equity> |
| Most common need: modified working hours | 16.3% | same |
| Modified or different duties | 11.6% | same |
| Working from home | 10.9% | same |
| US labour force participation, people with disabilities, June 2026 | **23.9%** vs 67.7% | US Bureau of Labor Statistics |
| US unemployment, people with disabilities, June 2026 | **8.6%** vs 4.2% | same |

Note that the most common unmet need is not equipment. It is a change to when
someone works, which costs nothing to grant and requires only that somebody say
yes.

## 4. The other side of the conversation is already automated

| Figure | Value | Source and exact standing |
|---|---|---|
| Employers using some automated tool to screen or rank candidates | "as many as **83%**" | An estimate quoted at the EEOC public hearing *Navigating Employment Discrimination in AI and Automated Systems*, 31 January 2023. <https://www.eeoc.gov/meetings/meeting-january-31-2023-navigating-employment-discrimination-ai-and-automated-systems-new/transcript> |
| Fortune 500 companies doing the same | "up to **99%**" | same |

**Be careful with this one.** It is phrased in the source as "by some
estimates", it was cited at an EEOC hearing rather than produced by the EEOC,
and it is from 2023. It is strong enough to say the practice is close to
universal among large employers. It is not strong enough to state as a
precise measurement, and Curb Cut does not.

**How these systems fail disabled people.** The EEOC's ADA guidance identifies
three recurring ways an algorithmic tool creates liability:

1. **Screening out** a person because of a disability-related trait. An
   employment gap caused by treatment, atypical speech, slower input.
2. **Conducting a disability-related inquiry or a medical examination** before
   an offer, which the ADA prohibits, sometimes without the employer realising
   the tool is doing it.
3. **Failing to provide a reasonable accommodation** within the automated
   process itself. A timed assessment with no way to ask for more time.

Source: EEOC, *The Americans with Disabilities Act and the Use of Software,
Algorithms, and Artificial Intelligence to Assess Job Applicants and Employees*
(2022), and the EEOC's AI and Algorithmic Fairness Initiative.
<https://www.eeoc.gov/eeoc-disability-related-resources/artificial-intelligence-and-ada>

## 5. Regulation is arriving, and it constrains the employer's system

| Development | Date |
|---|---|
| California Civil Rights Council regulations on automated decision systems in employment take effect | **1 October 2025** |
| EEOC continues its focus on algorithmic bias, with expectations of regular auditing | 2026 |

Every one of these governs the system pointed **at** the person. None of them
gives the person a system of their own. That gap is what Curb Cut occupies, and
it is the reason the timing matters now rather than five years ago.

---

## How to check this file

Nothing here is asserted from memory. Each row links to its source, and where a
figure is an estimate rather than a measurement it says so on the row. If a
number appears on the public site that is not in this file, that is a defect, `tests/invariants.py` fails the build if the site quotes a headline figure that
this document does not carry.
