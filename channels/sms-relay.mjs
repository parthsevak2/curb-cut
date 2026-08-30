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
import { Org } from '/Users/drashtipathak/.nvm/versions/node/v22.22.2/lib/node_modules/@salesforce/cli/node_modules/@salesforce/core/lib/index.js';
import { ProductionAgent } from '/Users/drashtipathak/.nvm/versions/node/v22.22.2/lib/node_modules/@salesforce/cli/node_modules/@salesforce/agents/lib/index.js';

const PORT   = Number(process.env.PORT || 3000);
const ALIAS  = process.env.SF_ORG_ALIAS || 'curbcut';
const AGENT  = process.env.CURB_CUT_AGENT || 'Curb_Cut';
// Optional. When set, inbound webhooks are verified as genuinely from Twilio.
const TWILIO_AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN || '';
const PUBLIC_URL        = process.env.PUBLIC_URL || '';
// Salt so a stored handle cannot be reversed to a phone number by rainbow table.
const HANDLE_SALT = process.env.HANDLE_SALT || 'curb-cut-local-dev-salt';

const org = await Org.create({ aliasOrUsername: ALIAS });
const connection = org.getConnection();

// One conversation per person, keyed by hashed number. Sessions expire so a
// shared phone does not inherit someone else's thread.
const SESSION_TTL_MS = 30 * 60 * 1000;
const sessions = new Map();

const handleFor = (from) =>
  createHash('sha256').update(HANDLE_SALT + from).digest('hex').slice(0, 32);

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

const twiml = (body) =>
  `<?xml version="1.0" encoding="UTF-8"?><Response><Message>${xmlEscape(body)}</Message></Response>`;

// Twilio signs each request with the auth token over URL + sorted params.
function signatureValid(url, params, header) {
  if (!TWILIO_AUTH_TOKEN) return true;             // unverified mode, dev only
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
      try {
        const agent = await agentFor(handle);
        const reply = await agent.preview.send(said);
        const text  = (reply?.messages ?? []).map(m => m.message).filter(Boolean).join(' ');
        return res.end(gather(text || 'I did not catch that. Say it again however you like.'));
      } catch (e) {
        console.error('[voice] agent error:', e?.message);
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

    if (PUBLIC_URL && !signatureValid(PUBLIC_URL + '/sms', params, req.headers['x-twilio-signature'])) {
      // Never echo why. An attacker learns nothing from a bare 403.
      res.writeHead(403); return res.end();
    }

    // Log the hash, never the number, never the message body. What someone
    // finds hard is not ops telemetry.
    console.log(`[sms] ${handle.slice(0,8)}… ${body.length} chars`);

    try {
      const agent = await agentFor(handle);
      const reply = await agent.preview.send(body);
      const text = (reply?.messages ?? []).map(m => m.message).filter(Boolean).join('\n\n');
      res.writeHead(200, {'content-type':'text/xml'});
      res.end(twiml(text || 'I did not catch that. Say it again however you like.'));
    } catch (e) {
      console.error('[sms] agent error:', e?.message);
      sessions.delete(handle);   // a broken session must not trap the person
      res.writeHead(200, {'content-type':'text/xml'});
      res.end(twiml(
        'Something went wrong on my end, and that is not your problem to solve. ' +
        'Reply HUMAN and a real person will pick this up.'));
    }
  });
});

server.listen(PORT, () => {
  console.log(`Curb Cut SMS relay on :${PORT}`);
  console.log(`  org      ${ALIAS}`);
  console.log(`  agent    ${AGENT}`);
  console.log(`  verify   ${TWILIO_AUTH_TOKEN ? 'on' : 'OFF — set TWILIO_AUTH_TOKEN'}`);
  console.log(`  POST /voice  ready now, no registration`);
  console.log(`  POST /sms    needs A2P 10DLC approval first`);
});
