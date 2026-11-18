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

## Quick install

Once you are logged in (step 1), one command asks you a few plain questions,
finds the rest in your org (your site's address, the inbound email address, your
agent user), deploys the web door and both agents, assigns the permission set,
loads the starter library, runs the tests, creates the org's own signing key,
and then checks your setup. There is no XML to edit:

    bash scripts/install.sh curbcut

A few steps need a person: accepting the Einstein Bots terms, creating the
site, and activating the agents. The check names whatever is left, in plain
words, and you can run it again any time:

    node scripts/check-setup.mjs curbcut

The steps below are the same install by hand, with the reasons. See
[scripts/README.md](scripts/README.md).

## 1. Authenticate

    sf org login web --alias curbcut

A browser opens; sign in to the target org. Every later command uses the alias.
Add `--instance-url` only for a sandbox with My Domain.

## 2. Make it yours: six labels, one file

`node scripts/configure.mjs curbcut` fills these in for you: it asks for what
it cannot find out and reads the rest from your org, and the quick install runs
it for you. To do it by hand instead, edit
`force-app/main/default/labels/CustomLabels.labels-meta.xml` before the first
deploy. The six values are your deployment's identity, quoted in every
reply, page and disclosure. Two of them switch a door on: until they hold a
real value, the site simply does not offer that door.

| Label | What it is |
|---|---|
| `CurbCut_Operator` | who runs this deployment, as people and carriers should read it |
| `CurbCut_SMS_Number` | your Twilio number as displayed; leave the placeholder until you add texting |
| `CurbCut_SMS_Number_Link` | the same number in E.164 (`+14165550123`). While it holds `+10000000000`, the site offers no texting or calling |
| `CurbCut_Inbound_Email` | the address Setup generates for `CurbCutInbound` (step 6). While it holds the placeholder, the site offers no email door |
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
Expect every test to pass; the README's Verification block carries the current count. If the org's async test runner errors, run the
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
`Curb_Cut_Guest` permission set: read and create only, the most Salesforce
lets a guest hold, and nothing on preferences or the disclosure ledger. The repository ships no site subdomain on
purpose; the site is yours. Put the site's full URL into `CurbCut_Site_URL`
(step 2) and redeploy the labels if you created the site after first deploy.

Verify from outside: the home page renders with your number and address, and
`/ask` walks to a draft without a login.

## 6. Email door

Setup → Email Services → `CurbCutInbound` → the org generates the inbound
address. Put it in `CurbCut_Inbound_Email` and deploy the labels; the site's
email door appears once it is set. Publish that address wherever your people
are. Replies are sent by
Apex; for them to reach inboxes reliably your org needs a verified sending
domain (Setup → Deliverability, DKIM). Until then, an undeliverable reply
becomes a human handoff rather than silence.

## 7. Optional: text and voice, on your own number

Curb Cut answers texts and calls on a number your organisation owns. Until you
connect one, the site and every reply simply do not offer texting or calling,
so nobody is ever pointed at a number that does not answer.

1. **Get a number.** In your own Twilio account, buy a number that can text and
   take calls. A US number must be registered for A2P 10DLC before carriers
   deliver its texts, and the reviewer reads your `/curbcut/messaging` page, so
   open the web door (step 5) first.
2. **Tell the org.** Set `CurbCut_SMS_Number` (the number as people should read
   it) and `CurbCut_SMS_Number_Link` (the same number in E.164, like
   `+14165550123`), then redeploy the labels. The text and call options appear
   on the site the moment the link label holds a real number.

       sf project deploy start --source-dir force-app/main/default/labels --target-org curbcut

3. **Fill in the relay's settings.** Every value is yours, and the file stays
   out of git:

       cp channels/.env.example channels/.env

   `channels/.env.example` explains each line. You need the Twilio account SID,
   auth token and number, a long random `HANDLE_SALT` (`openssl rand -hex 32`),
   your site address, your access-desk mailbox, and your org alias.
4. **Run the relay** on a machine with a stable HTTPS address:

       node channels/sms-relay.mjs        # or install the launchd/systemd unit

   It refuses to start without the auth token and the site address. Set
   `PUBLIC_URL` to its public address and every reply also asks Twilio to report
   whether it reached the phone; those receipts land in the ledger.
5. **Point the number at the relay:**

       bash channels/configure-twilio.sh https://your-relay-host

6. **Try it.** Text `CURB CUT` to your number. The welcome and the carrier
   disclosure should come back, then `node scripts/check-setup.mjs curbcut`
   shows the text door as open.

The relay verifies Twilio's signature on every request and hashes numbers with
your salt before anything is stored. `run-relay.sh` wraps it in a Cloudflare
quick tunnel, which is fine on a laptop for a pilot and wrong for production;
for production, use a named tunnel or any stable host.

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

And when you're live, write to curbcut@havihi.digital and say so. With your
permission we name workplaces where somebody answers, and every name on that
list makes the next organisation braver.

## If something fails

- `AiAuthoringBundle` not recognised: CLI below 2.149 or org below API 66.
- Every test fails on a security-enforced query: the permission set from
  step 3 is missing.
- Agent activation `fetch failed`: the Bots legal terms from step 0.
- Anything else: open an issue with the command and the whole error.
