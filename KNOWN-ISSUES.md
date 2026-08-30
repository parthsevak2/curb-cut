# Status after deploy — 2026-08-29

## Deployed and verified

| Component            | Result                                  |
|----------------------|-----------------------------------------|
| 7 custom objects     | Created                                 |
| 37 custom fields     | Created                                 |
| 2 validation rules   | Created                                 |
| 2 Apex classes       | Created                                 |
| Curb_Cut_Access permset | Created and assigned                 |
| Seed library         | 12 / 12 records loaded                  |
| Apex classes         | 4 classes, all deployed                 |
| Apex tests           | 13 / 13 pass                            |
| Agent Script         | Compiles, 0 errors                      |
| Agent bundle deployed | Created in org                         |
| Agent published      | BLOCKED — Einstein Bots terms not accepted |

Org: EPIC OrgFarm, Enterprise Edition, API 67.0.

## BLOCKER: Einstein Bots legal terms not accepted

Two of the three required org settings were enabled by metadata deploy:

    AgentPlatformSettings.enableAgentPlatform   -> enabled
    EinsteinGptSettings.enableEinsteinGptPlatform -> enabled

That was enough to make `AiAuthoringBundle` and `Bot` available as metadata
types, and the agent bundle now deploys into the org successfully.

The third will not deploy:

    Settings / Bot / Legal Terms acceptance and/or necessary feature
    dependencies required to enable Bot Settings

`BotSettings.enableBots` cannot be set by metadata. Someone with org access
has to accept the Einstein Bots / Agentforce terms in Setup. That is a legal
acceptance binding the org, so it is not an automation step.

Until that is done, `sf agent publish authoring-bundle` fails at the Publish
Agent step with `TypeError: fetch failed` against
`https://api.salesforce.com/einstein/ai-agent/v1.1/authoring/agents`.
`BotDefinition` returns 0 rows — no live agent exists yet.

Network was ruled out: Node fetch and curl both reach that host fine from
this machine, and deploy / query / validate all work against the org.

### To finish

1. Setup -> Einstein Bots (or Agentforce Agents) -> accept the terms and
   toggle the feature on.
2. Re-run:

       sf agent publish authoring-bundle --api-name Curb_Cut --target-org curbcut

3. Confirm:

       sf data query --query "SELECT DeveloperName FROM BotDefinition" --target-org curbcut

### Housekeeping

The bundle currently in the org has full name `Curb_Cut_1`, not `Curb_Cut` —
an earlier failed publish attempt appears to have taken the base name. Check
Setup and delete the orphan before publishing for real, or the demo may point
at the wrong bundle.

## The Agent Script was rewritten

`Curb_Cut.agent` as shipped produced 510 compilation errors and failed from
line 0 — it was written in a syntax that predates the shipped Agent Script
grammar. It now compiles with 0 errors.

The original is preserved at `Curb_Cut.agent.original`.

Every instruction carried over verbatim: never ask for a diagnosis, never
route to a phone call, never invent a cost or precedent count, never send
without a yes, grade six reading level, offer a human before they ask three
times. What changed is only the scaffolding.

Structural changes forced by the grammar:
- `topic` -> `subagent`; block headers take colons
- `welcome_message` / `error_message` -> `messages:` -> `welcome:` / `error:`
- `config` now carries `developer_name`, `agent_label`, `description`,
  `default_agent_user`
- variables now carry types and defaults
- `//` comments are not valid anywhere and were removed
- imperative `set` / `run` / `say` / `if` / `transition to` are not statements
  in this grammar; behaviour is declared under `reasoning: actions:` using
  `@utils.transition`, `@utils.setVariables`, `@utils.escalate`

## Actions: all five now implemented and wired

| Action                | Apex class              | Bound target                  |
|-----------------------|-------------------------|-------------------------------|
| `find_options`        | CurbCutOptions          | `apex://CurbCutOptions`       |
| `draft_request`       | CurbCutDraftRequest     | `apex://CurbCutDraftRequest`  |
| `create_request`      | CurbCutCreateRequest    | `apex://CurbCutCreateRequest` |
| `create_handoff`      | CurbCutCreateHandoff    | `apex://CurbCutCreateHandoff` |
| `route_to_interpreter`| built-in                | `@utils.escalate`             |

`CurbCutCreateRequest` refuses to set `Person_Approved__c` unless the caller
passes explicit approval through, and the `Requires_Person_Approval`
validation rule blocks the insert independently. Two locks, because an agent
optimising for a completed task will find one.

`CurbCutCreateHandoff` hard-codes `Reachable_By__c` to `Text message`.

Tests: 13/13 pass.

    CurbCutOptions        89%
    CurbCutDraftRequest  100%
    CurbCutCreateRequest  94%
    CurbCutCreateHandoff  78%

---

## Why `sf agent publish` cannot work from the CLI (diagnosed 2026-08-30)

The CLI reports only `TypeError: fetch failed`. The real chain, surfaced by
calling `ScriptAgent.publish()` directly through the library:

1. `POST https://api.salesforce.com/einstein/ai-agent/v1.1/authoring/agents`
   returns **HTTP 404** for this org, on an authenticated request.
2. The CLI's `requestWithEndpointFallback` then retries against
   `test.api.salesforce.com`, the sandbox ingress
   (`ingress-internal.core4.test1-uswest2.aws.sfdc.cl`,
   44.228.60.86 / 34.213.108.10 / 34.210.29.116).
3. That host is not reachable from this network. TCP 443 times out at 10s,
   which surfaces as `ConnectTimeoutError` wrapped into `fetch failed`.

`api.salesforce.com` itself is fine — the Agent API session and message
endpoints work against it, which is how the headless runner operates. It is
specifically the **v1.1 authoring/publish path that 404s** for this org.

Publishing therefore has to go through the Publish button in Agentforce
Builder, which uses an internal Lightning path rather than this API. This is
not a local or fixable condition.

`tests/publish_agent.mjs` reproduces the diagnosis.
