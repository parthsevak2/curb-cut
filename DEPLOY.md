# Deploy Curb Cut

## 0. CLI version — this matters
Requires @salesforce/cli 2.149.x or later. Older CLIs have no
`AiAuthoringBundle` metadata type: they ignore the agent file and report
a SUCCESSFUL deploy without it.

    npm install -g @salesforce/cli@latest
    sf --version        # must be >= 2.149

## 1. Authenticate — YOU do this step, a browser opens
    sf org login web --alias curbcut \
      --instance-url https://orgfarm-7a04c62cb9.my.salesforce.com

## 2. Deploy the metadata
    sf project deploy start --source-dir force-app --target-org curbcut

## 3. Assign the permission set
Custom fields deployed through the Metadata API carry NO field-level
security. Without this, the `WITH SECURITY_ENFORCED` query in
CurbCutOptions throws and every Apex test fails.

    sf org assign permset --name Curb_Cut_Access --target-org curbcut

## 4. Load the grounded options library
    sf data import bulk --sobject Accommodation_Option__c \
      --file accommodation_options_seed.csv --target-org curbcut --wait 10

## 5. Run the Apex tests
    sf apex run test --class-names CurbCutOptionsTest \
      --target-org curbcut --result-format human --wait 10

Expect 5 passing tests. The one that matters is
`returnsEmptyRatherThanGuessing`.

## 6. Compile and publish the agent
The Agent Script file does NOT compile as part of step 2. Step 2 only
uploads it. It is compiled server-side by these commands, and both
require an authenticated org — there is no offline syntax check.

    sf agent validate authoring-bundle --api-name Curb_Cut --target-org curbcut
    sf agent publish  authoring-bundle --api-name Curb_Cut --target-org curbcut

Run validate first and expect errors. See KNOWN-ISSUES.md — the script
is written in a syntax that predates the shipped Agent Script grammar.

## 7. Turn on session tracing (UI)
Setup -> Einstein Audit, Analytics, and Monitoring Setup -> Agentforce Session Tracing

## If deploy fails
- `AiAuthoringBundle` not known: org is below API 66.0, or the CLI is old.
- `INVALID_FIELD` on the permission set: a field was renamed but the
  permission set was not regenerated.
- Anything else: paste the whole error back into chat.
