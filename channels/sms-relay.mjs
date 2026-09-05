/**
 * Curb Cut — SMS channel adapter.
 *
 * Twilio POSTs an inbound SMS here; we answer with TwiML, which Twilio sends
 * back to the person. That means the reply path needs NO Twilio credentials at
 * all — this process never calls Twilio's API, it only answers the webhook.
 * The only secret in the system stays the Salesforce auth the CLI already holds.
 *
 * Spec section 3: text is a front door, not a fallback. Spec section 2:
 * Person_Handle__c is "Phone hash or employee ref. Never the raw number." The
 * raw number is hashed on arrival and never stored or logged.
 */
import { createServer } from 'node:http';
import { createHmac, createHash } from 'node:crypto';
import { execSync } from 'node:child_process';
import { join } from 'node:path';

// The Salesforce CLI bundles @salesforce/core and @salesforce/agents. Find
// them where the CLI is installed, not where one laptop happened to keep them.
// SF_CLI_MODULES overrides the lookup when the CLI lives somewhere unusual.
const SF_CLI_MODULES = process.env.SF_CLI_MODULES
  || join(execSync('npm root -g', { encoding: 'utf8' }).trim(),
          '@salesforce', 'cli', 'node_modules', '@salesforce');
const { Org }             = await import(join(SF_CLI_MODULES, 'core',   'lib', 'index.js'));
const { ProductionAgent } = await import(join(SF_CLI_MODULES, 'agents', 'lib', 'index.js'));

const PORT   = Number(process.env.PORT || 3000);
const ALIAS  = process.env.SF_ORG_ALIAS || 'curbcut';
const AGENT  = process.env.CURB_CUT_AGENT || 'Curb_Cut';
// Optional. When set, inbound webhooks are verified as genuinely from Twilio.
const TWILIO_AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN || '';
const PUBLIC_URL        = process.env.PUBLIC_URL || '';
/* Local testing without a token has to be a deliberate act, named out loud on
   the command line, and it refuses to combine with a public URL. */
const ALLOW_UNVERIFIED  = process.env.ALLOW_UNVERIFIED === '1' && !PUBLIC_URL;
// Salt so a stored handle cannot be reversed to a phone number by rainbow table.
const HANDLE_SALT = process.env.HANDLE_SALT || 'curb-cut-local-dev-salt';
// The public site. Carriers require the opt-in flow to be verifiable at a URL,
// and the disclosure messages below quote these two pages by name.
const SITE = process.env.CURB_CUT_SITE ||
  'https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut';

/* ------------------------------------------------------------------
   Carrier compliance.

   A2P 10DLC campaign CMcb0b8f321bcc5aa98b2cc45bb3ea594a was rejected with
   error 30909: the reviewer could not verify how anyone consents. That was
   fair. The agent and the legal pages existed; the channel's own compliance
   layer did not. Every inbound message went straight to the agent, so HELP
   was answered by an accessibility assistant rather than by the required
   help text, and nobody was ever sent the disclosure that makes their
   opt-in real.

   Opt-in here is keyword-style: the person texts first, from a poster. That
   is the hardest kind for a reviewer to verify, which is exactly why the
   auto-reply below has to carry every required element, and why /messaging
   on the public site reproduces the poster verbatim.
   ------------------------------------------------------------------ */

// Sent once, the first time we ever reply to someone. Program name, frequency,
// rates, HELP, STOP, and both policy links - the full required set.
const DISCLOSURE =
  'Curb Cut: you texted first, so you will get replies from this number. ' +
  'Message frequency varies and replies only follow your own messages. ' +
  'Message and data rates may apply. Reply HELP for help, STOP to stop. ' +
  `Terms ${SITE}/terms Privacy ${SITE}/privacy`;

// HELP is a reserved keyword and must be answered by us, not by the agent.
// Kept under 320 characters so the identical text fits the carrier keyword
// field too. Two different HELP replies would make /messaging quote something
// that is not what arrives, and that page exists to be verifiable.
const HELP_REPLY =
'Curb Cut helps you find out what could make work easier at work, and ask ' +
  'for it, without ever saying what condition you have. ' +
  'Message and data rates may apply. Reply STOP to stop. ' +
  `Help: parth.sevak2@gmail.com Terms ${SITE}/terms`;

const STOP_REPLY =
  'Curb Cut: you will not get any more messages from this number. ' +
  'Reply START if you ever want to come back. Nothing about you is kept.';

const START_REPLY =
  'Curb Cut: you are back. Tell me what is hard at work right now. ' +
  'Message and data rates may apply. Reply HELP for help, STOP to stop.';

// Reserved keywords the carriers own. These must never reach the agent: an
// assistant improvising a reply to STOP is a compliance failure, and worse,
// it is someone asking to be left alone and being answered back.
const HELP_WORDS  = new Set(['help', 'info']);

/* Control words. These are NOT carrier keywords - they are ours, and they were
   advertised for months with nothing behind them: HUMAN came back with an ASL
   interpreter card, OFF came back with "I do not have good information on that".
   Somebody withdrawing a disclosure was told the system did not understand, and
   the sharing stayed on.

   The list is mirrored from CurbCutKeyword.cls, which is the one place the rules
   live. An invariant fails the build if these two ever disagree, because two
   channels quietly disagreeing about what OFF means is exactly how this broke. */
const CONTROL_WORDS = new Set([
  'actualhuman','actualperson','agent','ahuman','anactualperson','aperson',
  'arealhuman','arealone','arealperson','canitalktoaperson',
  'canitalktosomeone','getmeahuman','human','humanplease','humans',
  'ineedahuman','ineedaperson','ineedsomeone','iwantahuman','iwantaperson',
  'iwantsomeone','letmetalktoaperson','letmetalktosomeone','notabot',
  'notarobot','off','person','personplease','realhuman','realpeople',
  'realperson','rep','representative','somebody','someone','speaktoahuman',
  'speaktoaperson','speaktohuman','speaktosomeone','stopsharing',
  'stopsharingit','switchitoff','switchoff','takeitback','takethatback',
  'talktoahuman','talktoaperson','talktohuman','talktosomeone','turnitoff',
  'turnoff','unshare','who','whocansee','whocanseeit','whohasit',
  'whohasseen','whohasseenit','whoknows','whoknowsit','whosaw','whosawit',
  'whoseesit','whowastold','withdraw','withdrawit',
]);
const STOP_WORDS  = new Set(['stop', 'stopall', 'unsubscribe', 'cancel', 'end', 'quit']);
const START_WORDS = new Set(['start', 'yes', 'unstop', 'curb cut', 'curbcut', 'curb', 'hello', 'hi', 'hey']);
/* The options a person was last shown, by handle, so a bare "2" in reply means
   the second one. Kept in memory with the session and forgotten with it. */
const picks = new Map();

/* One normalisation for every door on this relay. Text and voice used to
   disagree here: text squashed "Turn it off." to "turnitoff" and matched, and
   voice matched nothing at all, because it never looked. */
const keyword = (text) => text.toLowerCase().replace(/[^a-z]/g, '');
// A code travelling with the word: "off 4KQ7MT". Shared so the two paths agree.
const CODE_COMMAND = /^(off|who)\s+[a-z0-9]{6}$/i;

/* Somebody on a call saying one of these is not describing a barrier, and a
   language model is the wrong thing to answer them. They go to the router as a
   request for a person, so a real handoff exists before anything else is said.
   Substring on purpose: "I think I want to die" must match, and the router's
   six-word cap on control phrases must not apply. We have no crisis line to
   offer on a call, and docs/CHANNELS.md says so rather than pretending. */
const CRISIS_PHRASES = ['kill myself', 'suicid', 'end my life', 'want to die', 'hurt myself'];

/* Spoken aloud, a code arrives as letters with spaces: "off 4 K Q 7 M T". Put
   it back together so the router's whole-token code match can see it. Only
   letters from the code alphabet count (CurbCutKeyword.CODE_ALPHABET, which has
   no O 0 I 1 S 5), and a whole control phrase like "who can see" is never
   touched. Returns the text unchanged when there is nothing to rebuild. */
function rebuildSpokenCode(text) {
  if (CONTROL_WORDS.has(keyword(text))) return text;
  const spoken = text.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
  const m = spoken.match(/^(off|who)\s+((?:[abcdefghjklmnpqrtuvwxyz2346789]\s*){6})$/);
  return m ? `${m[1]} ${m[2].replace(/\s+/g, '')}` : text;
}

const org = await Org.create({ aliasOrUsername: ALIAS });
const connection = org.getConnection();

// One conversation per person, keyed by hashed number. Sessions expire so a
// shared phone does not inherit someone else's thread.
const SESSION_TTL_MS = 30 * 60 * 1000;
const sessions = new Map();

const handleFor = (from) =>
  createHash('sha256').update(HANDLE_SALT + from).digest('hex').slice(0, 32);
// Belt and braces before this ever reaches a SOQL string. It is our own hex
// digest, so it cannot be anything else, and it still gets checked.
const safeHandle = (h) => (/^[0-9a-f]{32}$/.test(h) ? h : null);

const xmlEscape = (s) => String(s)
  .replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;')
  .replaceAll('"','&quot;').replaceAll("'",'&apos;');

// Speech in, speech out. A long timeout because people who are choosing to
// speak may need a moment; rushing them is its own barrier.
const gather = (say) =>
  `<?xml version="1.0" encoding="UTF-8"?><Response>` +
  `<Gather input="speech" action="/voice" method="POST" speechTimeout="auto" language="en-US">` +
  `<Say voice="Polly.Joanna">${xmlEscape(say)}</Say>` +
  `</Gather>` +
  `<Say voice="Polly.Joanna">I did not hear anything. Call back any time, or send a message instead.</Say>` +
  `</Response>`;

// More than one <Message> is allowed, and the order matters. The useful answer
// goes first and the disclosure second, because someone who is having a hard
// enough week to be texting this number should not have to read carrier
// boilerplate before they read the help.
const twiml = (...bodies) =>
  `<?xml version="1.0" encoding="UTF-8"?><Response>` +
  bodies.filter(Boolean).map(b => `<Message>${xmlEscape(b)}</Message>`).join('') +
  `</Response>`;

/* Delivery ledger. The email channel failed silently for days because nothing
   recorded the attempt, and SMS had exactly the same hole. Records that we
   tried, never what was said, never the number. */
async function ledger(channel, direction, status, handle, detail) {
  try {
    await connection.sobject('Message_Log__c').create({
      Channel__c: channel, Direction__c: direction, Status__c: status,
      Recipient_Hash__c: handle, Detail__c: detail ? String(detail).slice(0, 30000) : null,
      Attempted_At__c: new Date().toISOString(),
    });
  } catch (e) {
    console.error('[ledger]', e?.message);   // never break a conversation to log it
  }
}

/* Has this person ever been sent the disclosure? Answered from the ledger so it
   survives a restart, with an in-process cache so the common case costs nothing.
   Erring towards sending it twice is safe; erring towards never is not. */
const greeted = new Set();
async function needsDisclosure(handle) {
  if (greeted.has(handle)) return false;
  try {
    const r = await connection.query(
      `SELECT Id FROM Message_Log__c WHERE Recipient_Hash__c = '${handle}' ` +
      `AND Direction__c = 'Outbound' LIMIT 1`);
    if (r.totalSize > 0) { greeted.add(handle); return false; }
  } catch (e) {
    console.error('[greet]', e?.message);
  }
  greeted.add(handle);
  return true;
}

// Twilio signs each request with the auth token over URL + sorted params.
/* Fails CLOSED. This used to return true when no token was configured, which
   meant an empty TWILIO_AUTH_TOKEN - exactly what was sitting in channels/.env -
   turned every unsigned request into a valid one. Anyone who learned the URL
   could post a forged From and Body, drive the agent, create handoffs and write
   to the ledger. An unverified webhook must refuse, not wave things through. */
function signatureValid(url, params, header) {
  if (!TWILIO_AUTH_TOKEN) return false;
  const data = Object.keys(params).sort()
    .reduce((acc, k) => acc + k + params[k], url);
  const expected = createHmac('sha1', TWILIO_AUTH_TOKEN).update(Buffer.from(data,'utf-8')).digest('base64');
  return header === expected;
}

async function agentFor(handle) {
  const existing = sessions.get(handle);
  if (existing && Date.now() - existing.touched < SESSION_TTL_MS) {
    existing.touched = Date.now();
    return existing.agent;
  }
  const agent = new ProductionAgent({ connection, apiNameOrId: AGENT });
  await agent.preview.start();
  sessions.set(handle, { agent, touched: Date.now() });
  return agent;
}

const server = createServer((req, res) => {
  if (req.method === 'GET' && req.url === '/health') {
    res.writeHead(200, {'content-type':'text/plain'});
    return res.end('ok');
  }
  // Voice front door. The person CHOOSES to speak; nothing here ever requires
  // it, and nothing here ever places an outbound call. Speech in, speech out.
  if (req.method === 'POST' && req.url.startsWith('/voice')) {
    let raw = '';
    req.on('data', c => { raw += c; if (raw.length > 1e5) req.destroy(); });
    req.on('end', async () => {
      const params = Object.fromEntries(new URLSearchParams(raw));
      const handle = handleFor(params.From || '');
      const said   = (params.SpeechResult || '').trim();
      res.writeHead(200, {'content-type':'text/xml'});

      if (!said) {
        // First leg of the call, or nothing was understood.
        console.log(`[voice] ${handle.slice(0,8)}… opening`);
        return res.end(gather(
          'Hi. I can help you work out what might make work easier, and help you ask for it. ' +
          'You do not have to tell me your name. You do not have to tell me what condition you have. ' +
          'I will never ask. Tell me what is hard right now.'));
      }

      console.log(`[voice] ${handle.slice(0,8)}… ${said.length} chars`);
      const key = safeHandle(handle);
      await ledger('Voice', 'Inbound', 'Accepted', key, `${said.length} chars`);

      /* Same router as text, before the agent ever hears it. Until this lane
         existed a caller who said "human" or "off" got a model, and the promise
         on every poster, one set of words on every door, was false for voice. */
      const heard  = rebuildSpokenCode(said);
      const spoken = heard.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
      const crisis = CRISIS_PHRASES.some(p => spoken.includes(p));
      if (crisis || CONTROL_WORDS.has(keyword(said)) || CODE_COMMAND.test(heard.trim())) {
        try {
          const answer = await connection.apex.post('/curbcut/v1/message/', {
            channel: 'Voice', text: crisis ? 'human' : heard, handle: key,
          });
          await ledger('Voice', 'Outbound', 'Accepted', key,
                       crisis ? 'routed: crisis, handoff requested' : 'routed: control word');
          /* The router's handoff reply promises an answer on the same channel.
             On a call we hold no number and never ring anyone, so on voice that
             sentence is replaced, not followed by a correction. */
          let spokenReply = answer.message || '';
          if (answer.handedOff) {
            spokenReply = spokenReply
              .replace(/They will reply here, on this same channel\.?/i, '')
              .replace(/\s+nobody will ring you\.?/i, '.')
              .replace(/\s{2,}/g, ' ').trim() +
              ' I hold no number for you, so nobody can ring you back. To reach them again, ' +
              'call this number and say human, or write to parth.sevak2@gmail.com.';
          }
          return res.end(gather(spokenReply));
        } catch (e) {
          console.error('[voice] control word failed:', e?.message);
          await ledger('Voice', 'Outbound', 'Escalated', key, `control word failed: ${e?.message}`);
          return res.end(gather(
            'I could not do that just now, and I am not going to pretend I did. ' +
            'Write to parth.sevak2@gmail.com and a person will sort it out.'));
        }
      }

      try {
        const agent = await agentFor(handle);
        const reply = await agent.preview.send(said);
        const text  = (reply?.messages ?? []).map(m => m.message).filter(Boolean).join(' ');
        await ledger('Voice', 'Outbound', 'Accepted', key, 'spoken reply');
        return res.end(gather(text || 'I did not catch that. Say it again however you like.'));
      } catch (e) {
        console.error('[voice] agent error:', e?.message);
        await ledger('Voice', 'Outbound', 'Escalated', key, `agent error: ${e?.message}`);
        sessions.delete(handle);
        return res.end(gather(
          'Something went wrong on my end, and that is not your problem to solve. ' +
          'A real person can pick this up. You will not have to explain it again.'));
      }
    });
    return;
  }

  if (req.method !== 'POST' || !req.url.startsWith('/sms')) {
    res.writeHead(404); return res.end();
  }

  let raw = '';
  req.on('data', c => { raw += c; if (raw.length > 1e5) req.destroy(); });
  req.on('end', async () => {
    const params = Object.fromEntries(new URLSearchParams(raw));
    const from = params.From || '';
    const body = (params.Body || '').trim();
    const handle = handleFor(from);

    if (!ALLOW_UNVERIFIED
        && !signatureValid(PUBLIC_URL + '/sms', params, req.headers['x-twilio-signature'])) {
      // Never echo why. An attacker learns nothing from a bare 403.
      res.writeHead(403); return res.end();
    }

    // Log the hash, never the number, never the message body. What someone
    // finds hard is not ops telemetry.
    console.log(`[sms] ${handle.slice(0,8)}… ${body.length} chars`);
    const key  = safeHandle(handle);
    const word = keyword(body);
    const xml  = (...m) => {
      res.writeHead(200, {'content-type':'text/xml'});
      res.end(twiml(...m));
    };

    await ledger('SMS', 'Inbound', 'Accepted', key, `${body.length} chars`);

    // Reserved keywords are answered here and never forwarded. If Twilio's own
    // Advanced Opt-Out is handling them this code never runs; if it is not, the
    // carrier still requires an answer, so both paths are covered.
    if (STOP_WORDS.has(word)) {
      sessions.delete(handle);
      await ledger('SMS', 'Outbound', 'Accepted', key, 'stop confirmation');
      return xml(STOP_REPLY);
    }
    if (HELP_WORDS.has(word)) {
      await ledger('SMS', 'Outbound', 'Accepted', key, 'help reply');
      return xml(HELP_REPLY);
    }
    if (START_WORDS.has(word) && !sessions.has(handle)) {
      greeted.delete(handle);
      await ledger('SMS', 'Outbound', 'Accepted', key, 'start reply');
      return xml(START_REPLY);
    }

    /* Our own control words. Answered by the shared Apex router rather than by
       the agent, so HUMAN books a real handoff and OFF actually revokes, and so
       the wording is identical to the wording on email and on the web. A code
       may travel with the word - "off 4KQ7MT" - which is how somebody turns a
       standing disclosure off from a phone when we deliberately have no idea
       who they are. */
    if (CONTROL_WORDS.has(word) || CODE_COMMAND.test(body.trim())) {
      try {
        const answer = await connection.apex.post('/curbcut/v1/message/', {
          channel: 'SMS', text: body, handle: key,
        });
        return xml(answer.message, await needsDisclosure(key) ? DISCLOSURE : null);
      } catch (e) {
        console.error('[sms] control word failed:', e?.message);
        await ledger('SMS', 'Outbound', 'Escalated', key, `control word failed: ${e?.message}`);
        // Never leave somebody reaching for the exit with nothing.
        return xml(
          'I could not do that just now, and I am not going to pretend I did. ' +
          'Write to parth.sevak2@gmail.com and a person will sort it out.');
      }
    }

    // Only on the very first reply this person has ever had from us.
    const disclose = await needsDisclosure(key) ? DISCLOSURE : null;

    /* A bare number answers the list this person was last shown. The agent
       then writes the request in their words and waits for a clear yes. */
    let said = body;
    const pick = body.trim().match(/^([1-9])$/);
    if (pick && picks.has(handle)) {
      const title = picks.get(handle)[Number(pick[1]) - 1];
      if (title) {
        said = `I would like to ask for this: ${title}. Please write the request in my own words and read it back to me before anything is sent.`;
      }
    }

    /* The shared Apex door first, the same one the web, email and Slack use.
       It ranks the sourced library without a model, so the first reply is the
       same on every channel and never depends on a model remembering to call
       its own action. The agent takes over only to draft, and only once the
       person has chosen. */
    if (!pick) {
      try {
        const answer = await connection.apex.post('/curbcut/v1/message/', {
          channel: 'SMS', text: body, handle: key,
        });
        const titles = (answer.options || '').split('\n').filter(l => l.startsWith('- ')).map(l => l.slice(2).trim());
        if (!answer.noMatch && titles.length) {
          picks.set(handle, titles);
          const numbered = (answer.options || '').split('\n').map(l => {
            const i = titles.indexOf(l.startsWith('- ') ? l.slice(2).trim() : null);
            return i >= 0 ? `${i + 1}. ${titles[i]}` : l;
          }).join('\n');
          const text = `${answer.message}\n\n${numbered}\n\nReply with a number and I will write the request in your words, and nothing is sent until you say yes. Or reply HUMAN for a person.`;
          await ledger('SMS', 'Outbound', 'Accepted', key, disclose ? 'options + disclosure' : 'options');
          return xml(text, disclose);
        }
      } catch (e) {
        console.error('[sms] door failed, falling back to the agent:', e?.message);
      }
    }

    try {
      const agent = await agentFor(handle);
      const reply = await agent.preview.send(said);
      const text = (reply?.messages ?? []).map(m => m.message).filter(Boolean).join('\n\n')
        || 'I did not catch that. Say it again however you like.';
      await ledger('SMS', 'Outbound', 'Accepted', key, disclose ? 'reply + disclosure' : 'reply');
      return xml(text, disclose);
    } catch (e) {
      console.error('[sms] agent error:', e?.message);
      sessions.delete(handle);   // a broken session must not trap the person
      await ledger('SMS', 'Outbound', 'Escalated', key, `agent error: ${e?.message}`);
      return xml(
        'Something went wrong on my end, and that is not your problem to solve. ' +
        'Send HUMAN and a real person will pick this up.', disclose);
    }
  });
});

if (!TWILIO_AUTH_TOKEN && !ALLOW_UNVERIFIED) {
  console.error(
    'Refusing to start: TWILIO_AUTH_TOKEN is not set, so no inbound request can\n' +
    'be verified as coming from Twilio, and this relay will not accept unsigned\n' +
    'webhooks. Set it in channels/.env, or run with ALLOW_UNVERIFIED=1 for local\n' +
    'testing only (which refuses to combine with PUBLIC_URL).');
  process.exit(1);
}

server.listen(PORT, () => {
  console.log(`Curb Cut SMS relay on :${PORT}`);
  console.log(`  org      ${ALIAS}`);
  console.log(`  agent    ${AGENT}`);
  console.log(`  verify   ${TWILIO_AUTH_TOKEN ? 'on' : 'OFF — UNVERIFIED, local only'}`);
  console.log(`  POST /voice  ready now, no registration; control words and crisis go to the router`);
  console.log(`  POST /sms    HELP/STOP/START handled here, disclosure on first reply`);
});
