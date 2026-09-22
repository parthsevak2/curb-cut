# Contributing

Thank you for looking. This project answers to the people it serves before it
answers to contributors, so the bar for changes is what they cost the person
asking for help, not what they add.

## Ground rules that are checked by machines

`python3 tests/invariants.py` runs 521 structural checks offline in about a
second, and CI blocks anything that breaks one. The inviolables:

- **No diagnosis field, ever.** The build fails if any field API name matches
  a medical stem.
- **Nothing sends without a clear yes.** The consent gate lives in Apex, not
  in prompts.
- **No phone numbers in storage**, only salted hashes.
- **Plain language.** Public copy is checked for reading level; error text
  never blames the person.

## Working locally

    npm install
    python3 tests/invariants.py          # offline, must pass
    npx jest                             # Sa11y accessibility suites

Suites that need a live deployment read `CURB_CUT_SITE` and skip cleanly when
it is unset. Apex tests need an authenticated org: `sf apex run test`.
On a fork, CI runs the offline suites only; the org-bound jobs skip without
secrets, and that is expected.

## Pull requests

Small, one subject, with the reasoning in the commit message. If a change
alters any user-facing sentence, say why the new sentence is kinder or truer.
Accessibility regressions are release blockers, and "it passes axe" is the
floor, not the ceiling.
