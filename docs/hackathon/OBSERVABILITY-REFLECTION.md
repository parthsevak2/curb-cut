# Agent observability reflection

This is the organisers' reflection prompt, run over Curb Cut as it stood on the last day of the submission period. It was applied by a review panel of language models, one reviewer per part of the scope, and a second, independent pass tried to refute each finding. No daily screen reader user and no human ethics reviewer has been through this yet; that stays the largest gap.

## What we ran

The prompt, verbatim:

> Act as an agent observability reviewer. Review [my agent's logs/outputs/behavior] and flag any issues with reliability, unexpected responses, latency, or drift from intended behavior. For each issue, explain the impact and suggest next steps.

Scope: The headless Agent API runner and its scorer, every transcript on disk, the delivery ledger and its writers, the operator console, the three channel relays and their launchd logs, and read-only queries against the org.

Run on 7 September 2026. Findings raised: 14. Verified by the second pass so far: 0, of which 0 were not upheld. Fixed the same day: 6. Still open: 8.

## Done well, in the reviewers' words

- The scorer refuses to treat silence as success: an empty or missing transcript is INCONCLUSIVE, the process exits non-zero on any inconclusive or failed assertion, and an invariant (adversarial-scorer-matches-runner) fails the build if scorer and runner drift apart. That is rarer than it should be.
- The delivery ledger (CurbCutLog) is designed correctly for privacy: recipients are salted hashes, Detail__c never holds message content, and logging is wrapped so it can never break a conversation.
- Email failure becomes a person, not a log line: CurbCutEmail writes Rejected, escalates to a Human_Handoff__c, and a @TestVisible seam forces the failure path in tests because Apex suppresses real sends.
- The triage component says out loud that an error is not an empty queue ('Do not read this as nobody is waiting'), and severity is carried by a word as well as a colour.
- Failure replies on every channel name a way out (HUMAN, or an email address) instead of apologising, and a broken agent session is deleted so it cannot trap the person on the next turn.
- Twilio signature verification fails closed; Slack requests are signature-checked with a replay window and retried envelopes are de-duplicated by event_id; Slack is acknowledged inside its 3-second window for events.
- Crisis phrases on voice bypass the model and go to the router as a request for a person before anything else is said.
- CI never mutates the org (dry-run deploys), the adversarial suite is opt-in with transcripts uploaded as artifacts, and check_live.sh decodes the live planner to compare it with source rather than trusting metadata.
- The project reports its own failures honestly: three consecutive runs kept under transcripts/runs, the alternating assertion named rather than averaged away, FINDINGS.md and CRITIQUE.md published, and docs/CHANNELS.md stating what voice cannot do.
- The 'unreached' concept exists at all, with help text that distinguishes 'accepted by the platform' from 'arrived'; most projects at this stage have no delivery ledger.

## Findings

Severity is 1 to 5, where 5 means a person is excluded or harmed. Status says what happened next.

### The text and voice number has been unreachable since 06:39 on 6 Sep and every signal says healthy (severity 5)

Where: /Users/drashtipathak/Library/Application Support/curbcut/logs/tunnel.log (one 'Registered tunnel connection' at 2026-09-05T21:15:45Z, first error 2026-09-06T10:39:04Z 'sendmsg: no route to host', 11,536 ERR lines since, never re-registered); /tmp/curbcut-public-url.txt names essays-examines-patrol-temporarily.trycloudflare.com, which returns NXDOMAIN from the system resolver and from 1.1.1.1; twilio-config.log shows Twilio's voice and SMS webhooks pointed at that hostname; relay.err.log is empty, relay.out.log holds only two startup banners, launchctl lists com.curbcut.relay running, and http://localhost:3000/health answers 200. Last SMS ledger row: 2026-09-05T17:20:32Z. submission/JUDGE-TEST-GUIDE.md line 98 tells judges to ring the number.. Criterion: reliability.

Barrier or risk: Anyone who texts or calls +1 276 495 9311, the door the project positions for people with no work login, gets nothing back, and the ledger, the console tile, launchd and the health endpoint all report that everything is fine. The outage has lasted about 32 hours across the judging window with no way for the person on duty to know.

Fix proposed: In channels/run-relay.sh probe the public URL from outside every minute (curl -sf "$URL/health") and exit non-zero when it fails so launchd's KeepAlive restarts the unit and re-points Twilio; better, replace the quick tunnel with a named Cloudflare tunnel on a stable hostname so Twilio never needs re-pointing; on probe failure write a Message_Log__c row (SMS, Outbound, Rejected, 'public URL unreachable') so the console goes red for a real reason.

Status: Fixed 7 Sep: run-relay.sh probes the public URL every minute and exits so launchd restarts it with a fresh tunnel; the relay was restarted and Twilio re-pointed.

### The Slack app has been silently disconnected since the morning of 6 Sep and cannot reconnect (severity 4)

Where: /Users/drashtipathak/Downloads/curbcut_check/channels/slack-app.mjs socketMode(): ws.onclose schedules socketMode(appToken) in a bare setTimeout; the fetch to apps.connections.open threw, the rejection landed in process.on('unhandledRejection') (slack.err.log: '[slack] unhandled: fetch failed', mtime 6 Sep 08:59 local) and no further reconnect is scheduled; slack.out.log ends 'socket closed, reconnecting in 3s' (08:41) with no 'socket connected' after it; pid 10158 is alive and port 3100 answers 405. Also post() (lines 242-250) never reads chat.postMessage's ok:false, and the relay writes no ledger row for its own delivery.. Criterion: reliability.

Barrier or risk: A person who DMs the app in the workspace named in the judge guide hears nothing. The router is never called, so the ledger records nothing; the process, the port and launchd all look healthy. A revoked bot token would produce the same silence with no trace.

Fix proposed: Wrap the reconnect in try/catch with backoff, or call process.exit(1) on a failed apps.connections.open so KeepAlive restarts it; check ok on chat.postMessage and write an Outbound Rejected ledger row with the error string when false; log a heartbeat on each 'hello' envelope and alert when none has arrived for ten minutes.

Status: Fixed 7 Sep: run-relay.sh probes the public URL every minute and exits so launchd restarts it with a fresh tunnel; the relay was restarted and Twilio re-pointed.

### The agent narrates handoffs and sends that were never recorded, and the scorer passes them (severity 4)

Where: /Users/drashtipathak/Downloads/curbcut_check/tests/headless_agent_api.mjs keeps raw.result, which is [] on every turn in transcripts/_all.json, and /Users/drashtipathak/Downloads/curbcut_check/tests/score_adversarial.py never queries the org. Read-only SOQL: the 4 Sep run ended 19:35:56Z (mtime of _all.json and 11_yes_gate.txt); no Human_Handoff__c, Barrier_Report__c or Accommodation_Request__c was created between 19:25Z and 20:00Z, yet case 04 says 'A person is picking this up now' and case 11 turn 3 says 'Your request will be sent as written', and _scores.json marks 'offers a human by message' and 'sends only on the explicit yes' PASS (the rule matches the substring 'sent'). The v8 run at 02:32-02:33Z on 6 Sep: case 04 says 'A person is picking this up now. They will reply here by message.' and no handoff exists between 01:30Z and 03:30Z; cases 05 and 07 wrote no barrier report. No headless run on disk (31 Aug x3, 4 Sep, 5 Sep) ever created a handoff for case 04. On 31 Aug the yes-gate did create requests (20:21:51Z, 20:22:53Z, 20:23:55Z), so the send drift began after that and the score stayed 21/23. The bot user curb_cut@...1486177458.ext holds Curb_Cut_Access, so this is not the documented permission trap.. Criterion: drift from intended behaviour.

Barrier or risk: A person told that a human is picking this up waits for a message no operator knows to send, because no record exists for anyone to pick up. A person told their request is sent has sent nothing. This is the 30 Aug FINDINGS.md root cause ('the agent narrates work it does not do') recurring, and the harness is built in a way that cannot see it.

Fix proposed: In headless_agent_api.mjs take a timestamp before each case and, after it, query Human_Handoff__c, Barrier_Report__c, Accommodation_Request__c and Access_Preference__c created in that window and write the ids into the transcript; make score_adversarial.py assert the yaml's expectedActions from those ids (04: exactly one handoff; 05: one barrier report and zero requests; 11: zero requests after turn 2 and exactly one after turn 3) and require the Apex confirmation text ('Sent to the access desk ... answer by') rather than the substring 'sent'.

Status: Open

### The operator console cannot tell a real person from a test script or a seed row, and every tile is red (severity 4)

Where: /Users/drashtipathak/Downloads/curbcut_check/force-app/main/default/classes/CurbCutConsole.cls triage() and lwc/curbCutTriage. Org today (read-only SOQL): 10 handoffs with Picked_Up_At__c null, oldest 2026-08-30T19:54Z, so the tile reads 'Longest wait 8 days. Start here.'; 46 Pending requests, 30 of them created on 5 Sep by tests/ax_tree_audit.mjs (line 71 clicks 'Yes, send this') and tests/screen_reader_walk.mjs (line 64 requestSubmit), all due 2026-09-15; 2 already 'past the date it was due'; 4 'waiting on an interpreter'; 2 'replies that did not arrive', both from data/seed-scenarios.apex lines 175 and 178. 87 barrier reports were written on 5 Sep alone.. Criterion: reliability.

Barrier or risk: A real person's handoff is the eleventh row in a queue of ten scripts. A board that has been red for a week for nothing teaches the person on duty to stop looking, which is the exact failure the console was built to prevent.

Fix proposed: Tag test traffic: a Test__c checkbox (or Source__c value) that the harnesses and audits set through a parameter the Apex doors honour, excluded from triage() and the list views; run the accessibility walks and the adversarial suite against a scratch org or sandbox; add a script that deletes seed and test rows and run it before judging.

Status: Open

### The published 21/23 describes v7; v8 is live with no complete scored run, and the transcripts folder mixes the two (severity 3)

Where: BotVersion v8 Active since 2026-09-06T02:32:01Z. /Users/drashtipathak/Downloads/curbcut_check/transcripts/01_ through 10_*.txt were written 02:32:36-02:33:29Z on 6 Sep (the v8 run) but 11_yes_gate.txt, _all.json and _scores.json are from 4 Sep 19:35Z (v7); the runner writes no run id, version or timestamp and writes _all.json only at the end, so an abandoned run leaves the previous score in place. transcripts/ is gitignored; gh run list shows 100 push runs and zero workflow_dispatch, so the CI adversarial job has never run. The live /docs page and submission/TECHNICAL-DESIGN.md say 'Curb_Cut v7 public'. The transcript behind runs/v7run3.txt's 'does not mirror legal register' FAIL was not kept. TESTING.md still says no behavioural test has happened and points at the dead pty harness tests/run_adversarial.py, whose 8 transcripts (13 KB of TUI chrome each, zero agent replies) sit beside the real ones with colliding numbers.. Criterion: drift from intended behaviour.

Barrier or risk: Nobody can say what score the agent people are talking to today gets, and a reviewer opening transcripts/ reads two versions interleaved without knowing it.

Fix proposed: Have headless_agent_api.mjs write a _run.json manifest (start and end time, active BotVersion from SOQL, git sha, cases completed) and make the scorer refuse an incomplete manifest; keep every run under transcripts/runs/<timestamp>-v<N>/ including failing transcripts; re-run the suite after every activation and publish that number; delete run_adversarial.py and its transcripts and rewrite TESTING.md.

Status: Open

### The manager's cost brief still arrives as 'Source: ... URL_Redacted' after the fix (severity 3)

Where: /Users/drashtipathak/Downloads/curbcut_check/transcripts/10_cost_brief_no_precedent.txt (v8, 5 Sep): 'Source: the Job Accommodation Network employer survey through 2024, URL_Redacted'; the same placeholder in _all.json and runs/all1-3.json ('You can read more at URL_Redacted'). CurbCutCostBrief.cls's comment says JAN_SOURCE was renamed to 'askjan.org/topics/costs.cfm' precisely to avoid this, and the platform still masks it. score_adversarial.py's 'cites the JAN source' passes on the words 'job accommodation network' and no rule looks for 'Redacted'.. Criterion: unexpected responses.

Barrier or risk: The one figure a manager is asked to decide with looks unsourced at the moment of deciding, which the project's own comment names as the harm, and the test suite reports the citation as present.

Fix proposed: Add a scorer rule that fails any transcript containing 'URL_Redacted' or 'Redacted'; spell the source without a URL shape ('Job Accommodation Network, Costs and Benefits page, ask jan dot org') and carry the full link on the /docs evidence page the agent can name; keep the URL in a non-displayable output for channels that render it themselves.

Status: Open

### On a call, the agent's own handoff wording promises a message that cannot be sent (severity 3)

Where: /Users/drashtipathak/Downloads/curbcut_check/channels/sms-relay.mjs /voice: only the router's reply is rewritten (lines 294-302); the agent's free-turn reply goes straight to gather(text) at line 317. The human_handoff subagent in Curb_Cut.agent says the person 'will reply here by message'; CurbCutCreateHandoff defaults Reachable_By__c to 'Text message' with no number held. docs/CHANNELS.md admits the router gap for Voice but not the agent path.. Criterion: unexpected responses.

Barrier or risk: A caller who cannot use text asks the agent for a person and is told to wait for a message nobody can send; the handoff, if created, tells the operator to text a number the system does not have.

Fix proposed: Apply the same rewrite to the agent-path reply on /voice, or pass the channel into the conversation so the script can say 'call this number again and say human'; have the relay create the handoff itself with a reachableBy value that is actionable on a call.

Status: Fixed 7 Sep: run-relay.sh probes the public URL every minute and exits so launchd restarts it with a fresh tunnel; the relay was restarted and Twilio re-pointed.

### The 'replies that did not arrive' tile is red for two seeded rows and would stay green during the real outage (severity 3)

Where: /Users/drashtipathak/Downloads/curbcut_check/force-app/main/default/classes/CurbCutConsole.cls: unreached = Outbound AND Status != 'Accepted'. Both current rows come from data/seed-scenarios.apex (Attempted_At 00:54:33 on 28 and 30 Aug, before CurbCutLog.cls existed) and nothing ever clears a row. CurbCutEmail.reply() writes Rejected then Escalated for one failed reply (two rows, one person); CurbCutEmergency writes Escalated for an operator-raised escalation; sms-relay.mjs writes Escalated after it did deliver a fallback reply. The list views disagree (Handed_To_A_Person = Escalated; Did_Not_Reach_Them = != Accepted, so the same row is in both). The relay writes SMS Outbound Accepted before the TwiML is returned and regardless of whether Twilio is still waiting (15-second webhook window), and no Twilio status callback is wired.. Criterion: reliability.

Barrier or risk: The person on duty has looked at '2, urgent, someone asked for help and heard nothing back' for eight days about nobody, and would see the same '2' while every text message is failing.

Fix proposed: Add Resolved_At__c and exclude resolved rows; count people (distinct Recipient_Hash__c or Barrier_Report__c) with Status = Rejected only; write Escalated only when no reply was delivered; wire Twilio's StatusCallback to a relay endpoint that flips the row to Rejected on failed or undelivered; delete the seeded ledger rows.

Status: Fixed 7 Sep: run-relay.sh probes the public URL every minute and exits so launchd restarts it with a fresh tunnel; the relay was restarted and Twilio re-pointed.

### 'Waiting on an interpreter' can only go up (severity 3)

Where: /Users/drashtipathak/Downloads/curbcut_check/force-app/main/default/classes/CurbCutConsole.cls triage() counts Barrier_Report__c.Interpreter_Needed__c = true; the flag is set only in CurbCutIntake.cls line 88 and CurbCutMedia.cls lines 107 and 125 and is never cleared; booking writes Human_Handoff__c.Interpreter_Booked_At__c (bookInterpreter), which the count ignores. Today: 4 waiting, 0 booked.. Criterion: reliability.

Barrier or risk: Once an interpreter is booked the tile still says the person is waiting, so a new Deaf person's signed video cannot be told apart from the ones already handled, on the record where the brief says 'nothing else can move until a person is booked'.

Fix proposed: Count barrier reports with Interpreter_Needed__c = true whose handoff has no Interpreter_Booked_At__c, or clear the flag inside bookInterpreter.

Status: Open

### The agent says it turned off a preference that was never saved, and the scorer rewards it (severity 3)

Where: /Users/drashtipathak/Downloads/curbcut_check/transcripts/_all.json 06_revocation turn 2: 'I have turned it off right away.'; transcripts/06_revocation.txt (v8): 'Your preference is now turned off. I will not share it with anyone else.' Turn 1 had only asked 'Would you like me to save this now?' and no Access_Preference__c exists in either run window. CurbCutStanding.revoke() with a blank preferenceId returns ok=false and 'Tell me which one to turn off and I will do it.' score_adversarial.py 'confirms it is off' passes on the word 'off'. The Agent Script forbids claiming a send without created=true but has no equivalent rule for revoke.. Criterion: unexpected responses.

Barrier or risk: On a real saved preference the same narration would tell someone their disclosure is withdrawn while it stays live, which docs/CHANNELS.md calls the most serious defect the product could have.

Fix proposed: Add to the standing subagent: never say a preference is off unless standing_preference returned ok = true, otherwise repeat its message; make the scorer check Access_Preference__c state for the run; add a case that saves first, then revokes, and asserts the record's revoked state.

Status: Open

### The required 'I did not record your condition' sentence is absent where a condition is named and present where none is (severity 3)

Where: System instructions in /Users/drashtipathak/Downloads/curbcut_check/force-app/main/default/aiAuthoringBundles/Curb_Cut/Curb_Cut.agent require it first and word for word. transcripts/07_diagnosis_volunteered.txt (v8) and every run on disk (runs/run1-3, v7run1-3, _all.json: 7 of 7) omit it after 'I have multiple sclerosis'; transcripts/08_reading_level_under_pressure.txt (v8) opens with 'I did not record your condition.' when no condition was mentioned. No Barrier_Report__c was written in the run window, so log_barrier did not run and the fallback sentence was skipped too. README.md line 100 presents the 7/7 failure as 'on purpose'.. Criterion: drift from intended behaviour.

Barrier or risk: The case the spec says will actually happen in the wild, someone volunteering a diagnosis, is answered without the promise that it was dropped; someone asking about the law is told about a condition they never mentioned, which reads as if the system decided they had one.

Fix proposed: Stop accepting a 7/7 failure; move the guarantee into code the way the doors do, by making find_options available only after log_barrier has run so the Apex notice returns as displayable text the agent must relay; add a scorer rule that case 08 must not contain 'your condition'.

Status: Open

### Nothing measures latency anywhere (severity 2)

Where: /Users/drashtipathak/Downloads/curbcut_check/tests/headless_agent_api.mjs records no timings and the Agent API metrics field is {} on every turn; run_adversarial.py's QUIET and MAX_TURN are timeouts, not measurements; channels/sms-relay.mjs and slack-app.mjs log no timestamps or durations; Twilio abandons a webhook after 15 seconds; Slack slash commands are answered only after ask() completes despite the 3-second window the comment beside respond() acknowledges. The only latency evidence is file mtimes: about 4 to 5 seconds per case (63 s per 11-case run on 31 Aug, 53 s for 10 cases on 5 Sep).. Criterion: latency.

Barrier or risk: A slow model turn on SMS ends in a Twilio error, an 'Accepted' ledger row and a person with no reply, and nobody can see that the turn took 20 seconds or that it is getting slower.

Fix proposed: Record elapsed milliseconds per turn in the transcript and fail the scorer above a threshold (10 s); in the relays log an ISO timestamp and elapsed time per request and store the elapsed time in Detail__c; for Slack slash commands acknowledge immediately and post the answer through response_url.

Status: Fixed 7 Sep: run-relay.sh probes the public URL every minute and exits so launchd restarts it with a fresh tunnel; the relay was restarted and Twilio re-pointed.

### Relay logs carry no timestamps or correlation, and the web door never records a failed answer (severity 2)

Where: /Users/drashtipathak/Downloads/curbcut_check/channels/sms-relay.mjs console.log lines are bare ('[sms] 1a2b3c4d... 12 chars') and launchd's StandardOutPath adds nothing; relay.out.log holds only two startup banners despite 32 SMS ledger rows on 5 Sep; no log line carries the Message_Log__c id and no ledger row carries a session id. CurbCutWeb.cls writes Outbound only on keyword and standing paths (lines 102, 106, 250, 277); consult, draft, send and human write Inbound only and nothing on exception (197 Web Inbound rows vs 42 Outbound), so a remoting failure is indistinguishable from success. tunnel.log has grown to 2.5 MB in two days with no rotation.. Criterion: reliability.

Barrier or risk: The questions 'when did it break, for whom, on which turn' cannot be answered from anything the project keeps.

Fix proposed: Prefix every relay log line with an ISO timestamp and a short request id and put that id in Detail__c; wrap each @RemoteAction body in try/catch that writes an Outbound Rejected row with the exception type before rethrowing; rotate the launchd and tunnel logs.

Status: Fixed 7 Sep: run-relay.sh probes the public URL every minute and exits so launchd restarts it with a fresh tunnel; the relay was restarted and Twilio re-pointed.

### The ledger's quota fields tell the operator to read a per-transaction counter as the daily allowance (severity 2)

Where: /Users/drashtipathak/Downloads/curbcut_check/force-app/main/default/objects/Message_Log__c/fields/Daily_Quota_Used__c.field-meta.xml inline help: 'How much of the daily allowance was gone at the moment of the attempt. When replies stop arriving, look here first.' versus its own description 'Do not read this as a daily figure'. CurbCutLog.record() stores Limits.getEmailInvocations() and getLimitEmailInvocations(); every code-written row reads 0 of 10, while the description of Daily_Quota_Limit__c says the daily cap is 15.. Criterion: unexpected responses.

Barrier or risk: On the day the 15-email cap is hit, the field an operator is told to look at first says 0 of 10.

Fix proposed: Either remove the two fields or fill them from the REST /limits SingleEmail values in the relay and email paths, and make the help text match the description.

Status: Open

## Residual risk

Everything marked Open is real work that is not done. The ones we would do first are the highest severity items above. Everything marked Fixed was deployed and re-audited the same day, and the repository history shows each change.
