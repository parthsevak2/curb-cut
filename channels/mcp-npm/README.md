# Curb Cut MCP server

This is for people who run a [Curb Cut](https://github.com/parthsevak2/curb-cut) installation and want the library reachable from an assistant. Curb Cut helps a person find out what workplace adjustments they could ask for, and draft the ask, without ever disclosing a medical condition. Most people who need that are already inside some assistant, so this server puts the library where they are instead of asking them to come to us.

One promise before anything else: these tools never send anything on anyone's behalf. They look up and they draft. Sending an accommodation request is a disclosure, and a disclosure belongs to the person, so the only way anything reaches an employer is the person sending it themselves, in a conversation they're present for. There's also no tool that accepts a diagnosis, because there's nowhere in the system to put one. A caller who sends one gets told so, and nothing is stored.

## What you need

- Node 22 or newer.
- The Salesforce CLI (`npm install -g @salesforce/cli`), logged in to a Salesforce org with Curb Cut deployed: `sf org login web --alias curbcut`. The CLI holds the org login, which is why this package ships no credentials and no Salesforce dependencies of its own.
- If you don't have an org with Curb Cut yet, start at the [main repository](https://github.com/parthsevak2/curb-cut). This package is the doorway, not the building.

## Install

Add it to your MCP client's configuration:

```json
{
  "mcpServers": {
    "curb-cut": {
      "command": "npx",
      "args": ["-y", "curb-cut-mcp"],
      "env": { "SF_ORG_ALIAS": "curbcut" }
    }
  }
}
```

When it starts it prints `curb-cut MCP server ready` to stderr. It starts even without the Salesforce CLI or an org login: it answers `initialize` and `tools/list`, and `curbcut_cost_brief` and `curbcut_draft_request` work, because neither touches the org. When the CLI is missing it says so in one line on startup, and a tool that does need the org returns the command that fixes it as its result, instead of the server stopping.

## The five tools

| Tool | What it does |
| --- | --- |
| `curbcut_find_options` | Given what a person says is hard at work, in their own words, returns adjustments they could ask for, with what each typically costs and a source. Returns nothing rather than guessing. |
| `curbcut_cost_brief` | Published evidence on what accommodations actually cost employers, with the survey, the sample and the denominator. |
| `curbcut_draft_request` | Drafts the ask in the person's own words, describing what would help and never why. Returns text for the person to read and decide about. It cannot send. |
| `curbcut_reach_human` | Hands the person to a named human handler, on the channel they're already using, and returns a code they keep. Never routes anyone to a phone call. |
| `curbcut_nominate` | Nominates a workplace that should have Curb Cut. Stores the workplace name and nothing about the person nominating, not even a hash. |

Describe difficulties functionally: "can't type for long", "misses things in meetings". Any call that includes a diagnosis, condition or medical detail is refused, and the refusal explains how to ask so the person gets the same answer without anyone ever knowing why.

## Environment

| Variable | Required | What it's for |
| --- | --- | --- |
| `SF_ORG_ALIAS` | no | CLI alias of the org. Defaults to `curbcut`. |
| `CURB_CUT_SITE` | no | Public URL of your installation's site, quoted when a draft tells the person where they can send it themselves. |
| `TWILIO_NUMBER` | no | Your installation's SMS number, offered the same way. |
| `CURB_CUT_SUPPORT_EMAIL` | no | Address given when a human handoff can't be completed. |
| `SF_CLI_MODULES` | no | Where to find the CLI's `node_modules/@salesforce` directory, if the CLI lives somewhere unusual. |

## License

Apache-2.0, same as the rest of Curb Cut.
