# Channels

The doors that live beside the org rather than inside it. Every one of them
talks to the same Salesforce agent and the same Apex door; none of them stores
anything about a person on the machine it runs on.

| File | Door | Needs |
|---|---|---|
| `sms-relay.mjs` | Text and voice, through Twilio | A Twilio number, a stable HTTPS address, `TWILIO_AUTH_TOKEN` |
| `slack-app.mjs` | Slack direct messages, Socket Mode, so no public address | A Slack app from `slack-manifest.json`, `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN` |
| `mcp-server.mjs` | Any MCP client: Claude, an IDE, another assistant | Nothing to start; an org alias for the tools that read the library |
| `mcp-npm/` | The same MCP server, packaged as `curb-cut-mcp` on npm | `npx curb-cut-mcp` |
| `configure-twilio.sh` | Points the number's webhooks at the relay and reports A2P status | Twilio credentials in `channels/.env` |
| `run-relay.sh`, `run-slack.sh`, `install-launchd.sh` | Keep the relay and the Slack app running on a Mac, restarted if they die | macOS |

Copy `.env.example` to `.env` and fill it in. `.env` is gitignored, and nothing
here prints a secret.

## What every door shares

- **The agent is reached headlessly**, over the Agent API. The text and voice
  relay keeps one session per hashed number and ends it after 30 minutes, so a
  shared phone never inherits somebody else's conversation.
- **Nothing sends without a clear yes** from the person, in the conversation.
- **HUMAN works everywhere.** It opens a real handoff on the channel already in
  use, and never routes anyone to a phone call.
- **NOMINATE works everywhere.** It stores a workplace name and the door it came
  through, and nothing about who sent it.
- **No door calls back.** The voice line answers and never dials out.

## Environment

| Variable | Used by | Meaning |
|---|---|---|
| `SF_ORG_ALIAS` | all | The Salesforce CLI alias of your org |
| `CURB_CUT_SITE`, `CURB_CUT_SUPPORT_EMAIL` | relay, MCP | Your public site and access-desk address, said aloud and in replies |
| `HANDLE_SALT` | relay, Slack | Salt for hashing phone numbers and Slack ids before they reach the org; set your own |
| `SF_CLI_MODULES` | all | Where the Salesforce CLI's modules live, if not the usual global install |
| `TWILIO_AUTH_TOKEN` | relay | Signature checking on every webhook; the relay refuses to start without it |
| `TWILIO_NUMBER` | MCP | The number the MCP server tells people they can text |
| `PUBLIC_URL`, `PORT` | relay | Where Twilio reaches the relay |
| `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`, `SLACK_SIGNING_SECRET`, `SLACK_PORT` | Slack | From the app you create from the manifest |
| `CURB_CUT_AGENT` | relay | The agent's API name, if not `Curb_Cut` |
| `ALLOW_UNVERIFIED` | relay | Local testing only. Never set it on a public address |

The full walk-through, from an empty org, is [DEPLOY.md](../DEPLOY.md) steps 7
and 8. What each tool of the MCP server can and cannot do is in
[docs/AGENT-INTERFACES.md](../docs/AGENT-INTERFACES.md).
