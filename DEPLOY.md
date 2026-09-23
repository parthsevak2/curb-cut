# Install Curb Cut in your own org

This guide starts from a fresh Salesforce org and ends with the web door live,
the agent active and a person named on the access desk. The web and email doors
need nothing outside Salesforce. Text, voice and Slack are optional and come
last.

## 0. Prerequisites

- **A Salesforce org with Agentforce.** Curb Cut was built and verified on
  Enterprise Edition, API 67.0. Agentforce and Einstein generative AI are
  licensed Salesforce products; the open-source code is free, the platform
  under it is not.
- **Einstein and the Bots legal terms accepted, by a human, in Setup.** Two of
  the three switches deploy as metadata; the terms acceptance cannot. Setup →
  Einstein Setup → turn on Einstein. Then Setup → Einstein Bots → accept the
  terms. Until this is done, agent activation fails with an unhelpful
  `fetch failed`.
- **Salesforce CLI 2.149 or later.** Older CLIs silently drop the agent file
  and still report a successful deploy.

      npm install -g @salesforce/cli@latest
      sf --version

## 1. Authenticate

    sf org login web --alias curbcut

A browser opens; sign in to the target org. Every later command uses the alias.
Add `--instance-url` only for a sandbox with My Domain.

## 2. Make it yours: four labels, one file

Edit `force-app/main/default/labels/CustomLabels.labels-meta.xml` before the
first deploy. The four values are your deployment's identity, quoted in every
reply, page and disclosure:

| Label | What it is |
|---|---|
| `CurbCut_SMS_Number` | your Twilio number as displayed, or leave the placeholder until you add texting |
| `CurbCut_SMS_Number_Link` | the same number in E.164 for tap-to-text links |
| `CurbCut_Support_Email` | a mailbox your access desk reads |
| `CurbCut_Site_URL` | your public site URL from step 5, no trailing slash |

Also set `errorRoutingAddress` in
`force-app/main/default/emailservices/CurbCutInbound.xml-meta.xml` to a mailbox
you read, and `default_agent_user` in both files under
`force-app/main/default/aiAuthoringBundles/` to a real user in your org.

## 3. Deploy, permission, seed, test

    sf project deploy start --source-dir force-app --target-org curbcut
    sf org assign permset --name Curb_Cut_Access --target-org curbcut
    sf data import bulk --sobject Accommodation_Option__c \
      --file accommodation_options_seed.csv --target-org curbcut --wait 10
    sf apex run test --target-org curbcut --result-format human --wait 15

The permission set matters: fields deployed through the Metadata API carry no
field-level security, and without it every security-enforced query throws.
Expect 129 tests, all passing. If the org's async test runner errors, run the
test classes one at a time with `--synchronous`; the classes are independent.

## 4. Activate the agent

    sf agent validate authoring-bundle --api-name Curb_Cut --target-org curbcut

Validate should report no errors. Publishing from the CLI does not work on
every org (the authoring API returns 404 on some), so activate in the UI:
Setup → Agentforce Builder → open **Curb Cut** → save as a version → in the
activation dialog choose **Select User** and pick the agent user you named in
step 2, with the `Curb_Cut_Access` permission set assigned → Activate.
Repeat for **Curb Cut Desk**, the console-side agent.

Then turn on tracing: Setup → Einstein Audit, Analytics and Monitoring →
Agentforce Session Tracing.

## 5. Open the web door

Setup → Sites → New. Pick your Force.com domain, name the site, set the
active home page to `CurbCutHome`, and assign the guest user the
`Curb_Cut_Access` permission set. The repository ships no site subdomain on
purpose; the site is yours. Put the site's full URL into `CurbCut_Site_URL`
(step 2) and redeploy the labels if you created the site after first deploy.

Verify from outside: the home page renders with your number and address, and
`/ask` walks to a draft without a login.

## 6. Email door

Setup → Email Services → `CurbCutInbound` → the org generates the inbound
address. Publish that address wherever your people are. Replies are sent by
Apex; for them to reach inboxes reliably your org needs a verified sending
domain (Setup → Deliverability, DKIM). Until then, an undeliverable reply
becomes a human handoff rather than silence.

## 7. Optional: text and voice

You need a Twilio account, a number (US texting also needs A2P 10DLC
registration), and a machine with a stable HTTPS address to run the relay.

    cp channels/.env.example channels/.env    # fill it in; it stays gitignored
    node channels/sms-relay.mjs               # or install the launchd/systemd unit
    bash channels/configure-twilio.sh https://your-relay-host

The relay verifies Twilio's signature on every request, hashes numbers with
your salt before anything is stored, and refuses to start without
`CURB_CUT_SITE`. The `run-relay.sh` script wraps it in a Cloudflare quick
tunnel, which is demo-grade: fine on a laptop for a pilot, wrong for
production. For production, use a named tunnel or any stable host.

## 8. The Slack door, two minutes

Where your people already live in Slack, this is the door most of them find
first, so treat it as part of the install rather than an extra. Create the app in your workspace from `channels/slack-manifest.json` (Socket
Mode is already on in the manifest), copy the three tokens into
`channels/.env`, and run `node channels/slack-app.mjs`. It answers direct
messages only, opens every first contact with the employer-can-export
disclosure, and cannot write or send a request by design.

## 9. Name the person

Assign the console app (`Curb_Cut_Console`) to whoever answers. The On Duty
page is their whole job: work it top to bottom. Every door ends at them.

## 10. Put it on the wall

The people this serves most are the ones who never see your intranet. A
print-ready poster lives at
[parthsevak2.github.io/curb-cut/poster.html](https://parthsevak2.github.io/curb-cut/poster.html)
(source: `docs/poster.html`). Put your own doors on it through the address
bar, no editing:

```
poster.html?num=+1 555 000 1234&site=https://your-site/curbcut/ask
```

Print it and put it where people actually stand: the break room, the loading
dock, beside the kettle.

## If something fails

- `AiAuthoringBundle` not recognised: CLI below 2.149 or org below API 66.
- Every test fails on a security-enforced query: the permission set from
  step 3 is missing.
- Agent activation `fetch failed`: the Bots legal terms from step 0.
- Anything else: open an issue with the command and the whole error.
