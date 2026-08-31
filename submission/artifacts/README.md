# Published artifact sources

The three pages published to claude.ai, kept here so a change to the product can
be diffed against what the public pages actually say. They drifted badly once
already: the flagship page claimed 7 objects / 37 fields / 102 invariants / 24
tests, and presented `Reachable_By__c = Text message` as a principle on the day
it was proven to be a defect.

| File | URL |
|---|---|
| `curbcut.html` | https://claude.ai/code/artifact/13947fab-1a4d-4586-a406-8e9ab39b5c22 |
| `curbcut-privacy.html` | https://claude.ai/code/artifact/7d520923-e7bb-490e-b158-063404c053bd |
| `curbcut-terms.html` | https://claude.ai/code/artifact/742cd290-a320-45a5-bed6-bde0d256da9b |

Publish with the Artifact tool, passing the URL so it updates in place rather
than creating a fourth page.

Both policy pages carried the sentence "if you mention a condition anyway, it is
not recorded", which was false until 31 August 2026 and is now true within a
stated limit. If the redaction list in `CurbCutRedact` ever changes materially,
these two pages have to change with it.
