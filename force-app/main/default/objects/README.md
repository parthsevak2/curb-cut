# Curb Cut — deployable metadata

Source-format SFDX metadata for the six Curb Cut objects.

## Deploy

    sf project deploy start --source-dir force-app --target-org <alias>

## The absence is the point

No object in this package contains a field for diagnosis, condition, disability type,
medical note, severity, or prognosis. That is not a policy — the schema is incapable
of holding it. Screenshot the field lists; it is a submission asset.

## Two guardrails enforced in metadata, not prompt

- `Requires_Person_Approval` — an Accommodation_Request cannot be inserted unless the
  person has approved it themselves. The person holds the pen.
- `Decline_Requires_Reason` — a manager cannot decline silently.

Prompt instructions can be talked around. Validation rules cannot.

## Disclosure_Event__c

Added after self-critique. A standing preference that travels ahead of you is a
disclosure made in your absence. This object is the ledger that makes it visible to
the person it concerns: who saw what, when, and why.
