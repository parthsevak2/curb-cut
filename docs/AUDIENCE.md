# Who this is for

Two different questions get confused here, so they are answered separately: who
*uses* Curb Cut, and who would ever *deploy* it. They are not the same people,
and the first group is deliberately not a market.

---

## 1. The user, who buys nothing

The primary user is a working person who needs one ordinary adjustment and has
not asked for it.

They need no account, no employer relationship with us, and no organisation to
have bought anything on their behalf. That is a product decision, not a gap in
the business model: the moment a person has to be inside somebody's licence to
get help, the population who needs help most is the population excluded.

**Who specifically.** Four groups the current design serves, in order of how
badly the usual process fails them:

| Group | Why the usual process fails them |
|---|---|
| Hourly, shift and minimum-wage workers | In 2025, US workers with a disability were twice as likely to be part time (30% against 17%) and more often in service, production and transport jobs (BLS, released March 2026). No work email, no desk, no HR office on the floor, and no time during a shift to fill in a form. Text and voice on a basic phone exist for them |
| Contractors, temps, agency and gig workers | Often have no work login and no HR relationship at all, yet are expected to disclose to get anything |
| People with invisible conditions | 62% of disabled employees in the Coqual study; they are believed less and asked to prove more |
| Deaf and hard-of-hearing workers | Every escalation path in most systems ends at "give us a call" |
| Anyone in their first weeks somewhere | Least social capital, highest perceived cost of asking |

---

## 2. Who would deploy it

Three buyer types exist, and they want it for different reasons.

### Employers with an existing disability programme

**Disability:IN** alone has a network of **over 400 corporations** and 25 state
affiliates. These organisations have already decided that disability inclusion is
worth spending on, already run self-identification campaigns, and already know
their disclosure numbers are low.

The pitch to them is not "care about this". They already do. It is: your
self-identification rate is low because the act of identifying is the barrier,
and this measures that rather than exhorting people to try harder.

### Disability employment service providers

Organisations that place and support disabled workers, including the
**AbilityOne / SourceAmerica** network, which employed **more than 36,000 people
with disabilities in FY2024** at an average wage of **$18.96 per hour**. They
carry the accommodation conversation on behalf of people who have no leverage in
it.

For them Curb Cut is a channel their clients can reach without a caseworker
present, which matters most in the hours when no caseworker is available.

### Centers for Independent Living and community nonprofits

Consumer-controlled, community-based, chronically under-resourced. The MCP server
and the shared channel API exist partly for them: an organisation with no
Salesforce budget can still put the grounded library behind whatever they already
run.

---

## 3. What we can and cannot claim about market size

**What is documented.** North America accounts for **$120.5 billion in 2025** of
the intellectual and developmental disability services market, about **42.1% of
global revenue**.

**What that number is not.** It is the services market, not a market for
accommodation-request software, and quoting it as though it were our addressable
market would be dishonest. We include it only to establish that the surrounding
sector is large and funded, not to imply a share of it.

**The number that actually matters commercially** is the one from Statistics
Canada: **35.4% of employed Canadians with disabilities have an unmet
accommodation need**, and the most common one is modified working hours, which
costs an employer nothing. The gap is not a spending gap. It is a process gap,
which is cheaper to close and harder to sell against, because there is no budget
line for "the asking was too hard".

---

## 4. Why an employer would actually adopt it

In descending order of how often it is the real reason:

1. **Their self-identification numbers embarrass them** and they have run out of
   campaigns to fix it.
2. **Legal exposure.** In the US the interactive process is not optional, and a
   request that never reaches anybody is a request the employer cannot show they
   engaged with. The delivery ledger is the record of every attempt.
3. **Retention.** JAN's employer survey reports 85% of respondents citing
   increased employee retention among the benefits.
4. **It costs almost nothing to say yes.** 61% of the accommodations employers
   priced cost them nothing.

---

## 5. Who this is not for

- **Not a diagnostic tool.** It holds no medical data and gives no medical advice.
- **Not a compliance product.** It records that a request was made and answered;
  it does not assess whether an accommodation was legally required.
- **Not a replacement for an accommodations team.** It is the front door to one,
  and it ships with a console because a promise that a person will pick this up
  is worthless unless that person has somewhere to stand.

---

**Once it is sent, the employer holds it.** The request contains no diagnosis, every word in it is the person's own, and OFF withdraws a standing preference at once. None of that stops a manager reacting badly. The interactive-process duty is why the same record can also protect the person: it shows they asked, in writing, on a date.

## Sources

- Disability:IN network size — <https://disabilityin.org/>
- SourceAmerica / AbilityOne FY2024 employment and wage figures —
  <https://www.sourceamerica.org/who-we-are/reports-factsheets/america-made-here-disability-employment-and-abilityone-manufacturing>
- Centers for Independent Living, description and role — Cornell University
  disability and employment guide,
  <https://guides.library.cornell.edu/c.php?g=745939&p=8056467>
- IDD services market size, North America 2025 — Dataintelo market report,
  <https://dataintelo.com/report/global-intellectual-and-developmental-disability-services-market>
  (a commercial market-research estimate, not a government statistic, and
  labelled as such wherever it appears)
- Unmet accommodation need, retention and cost figures — see `EVIDENCE.md`
