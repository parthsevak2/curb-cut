#!/usr/bin/env node
/**
 * Curb Cut on Slack.
 *
 * Slack is the hardest channel this project has, and not for a technical
 * reason. Slack is the employer's estate. Workspace owners can export private
 * channels and direct messages under Discovery; on many plans a compliance
 * export includes DMs. A tool whose entire promise is "you can ask without
 * telling your employer anything" cannot behave on Slack the way it behaves on
 * a phone, and pretending otherwise would be the single most dishonest thing
 * in this codebase.
 *
 * So the rules here are narrower than on every other channel:
 *
 *   1. It never answers in a channel. Not in a thread, not ephemerally. Asking
 *      about accommodations in #general is a disclosure to everyone scrolling,
 *      and an ephemeral reply still leaves the question visible. In a channel it
 *      says one thing: come to a DM.
 *   2. It says out loud, on first contact, that Slack belongs to the employer
 *      and names the two channels that do not. Somebody should be told what
 *      they are standing in before they say anything, not after.
 *   3. It never drafts and never sends a request from here. Read-only help.
 *      The send button lives on the web, where the person is anonymous.
 *   4. It writes no message text anywhere, and hashes the Slack user id before
 *      it touches the ledger, exactly like a phone number.
 *
 * Everything it does answer comes from the same Apex router as SMS, email and
 * the web, so the control words mean the same thing here as everywhere else.
 *
 * Zero dependencies beyond jsforce, which the SMS relay already uses.
 */

import http from 'node:http';
import { createHmac, timingSafeEqual, createHash } from 'node:crypto';
import { join } from 'node:path';
import { execSync } from 'node:child_process';

const PORT           = Number(process.env.SLACK_PORT || 3100);
const SIGNING_SECRET = process.env.SLACK_SIGNING_SECRET || '';
const ALIAS          = process.env.SF_ORG_ALIAS || 'curbcut';
const HANDLE_SALT    = process.env.HANDLE_SALT || 'curb-cut-slack-salt-v1';

const SITE = 'https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut';

/* Said once, on first contact, before anything else is discussed. Not buried in
   a privacy page nobody opens. */
const WHERE_YOU_ARE =
  'Before anything else, so you can decide what to say here:\n\n' +
  'I am an automated assistant, not a person; send HUMAN for one. This is Slack, and Slack belongs to your employer. On most plans a workspace ' +
  'owner can export direct messages. I cannot change that, and I would rather ' +
  'you knew it now than found out later.\n\n' +
  `If you want to ask something with no employer in the room, use ${SITE}/ask ` +
  'in a private browser window, or text the number on that page. Both work ' +
  'without an account and without your name.\n\n' +
  'If Slack is the easiest thing for you to use, that is a real reason and I am ' +
  'still here. I just will not pretend it is private.';

const IN_CHANNEL_REFUSAL =
  'I only answer in a direct message, never in a channel.\n\n' +
  'A question about what would make work easier is nobody else\'s business, and ' +
  'in here it is visible to everyone scrolling. Send me a DM instead and I will ' +
  'pick it straight up.';

const NO_SENDING =
  '\n\nI will not write or send a request from Slack. When you want to actually ' +
  `ask for something, do it at ${SITE}/ask, where you are anonymous and you ` +
  'press send yourself.';

/* Same pattern as the SMS relay: the CLI already holds the credential, so
   nothing here needs its own secret on disk. The connection comes from
   @salesforce/core, which refreshes the access token when it expires; a raw
   token copied out of `sf org display` goes stale after a few hours and the
   app would start answering everyone with an apology. */
const SF_CLI_MODULES = process.env.SF_CLI_MODULES
  || join(execSync('npm root -g', { encoding: 'utf8' }).trim(),
          '@salesforce', 'cli', 'node_modules', '@salesforce');
const { Org } = await import(join(SF_CLI_MODULES, 'core', 'lib', 'index.js'));
const conn = (await Org.create({ aliasOrUsername: ALIAS })).getConnection();

const handleFor = (id) =>
  createHash('sha256').update(HANDLE_SALT + id).digest('hex').slice(0, 32);

/* Slack signs every request. An unsigned one is not from Slack, and this is a
   public endpoint, so it is refused before the body is even parsed. */
function signatureValid(rawBody, headers) {
  if (!SIGNING_SECRET) return false;
  const ts  = headers['x-slack-request-timestamp'];
  const sig = headers['x-slack-signature'];
  if (!ts || !sig) return false;
  // Replay window. Slack recommends five minutes.
  if (Math.abs(Date.now() / 1000 - Number(ts)) > 60 * 5) return false;
  const mine = 'v0=' + createHmac('sha256', SIGNING_SECRET)
    .update(`v0:${ts}:${rawBody}`).digest('hex');
  const a = Buffer.from(mine), b = Buffer.from(sig);
  return a.length === b.length && timingSafeEqual(a, b);
}

const seenUsers = new Set();
/* Slack retries an envelope it thinks was not acknowledged. Each event carries
   an event_id, so a retry is answered once, not twice. */
const seenEvents = new Set();
function fresh(id) {
  if (!id) return true;
  if (seenEvents.has(id)) return false;
  seenEvents.add(id);
  if (seenEvents.size > 500) seenEvents.delete(seenEvents.values().next().value);
  return true;
}

async function ask(text, slackUserId) {
  const handle = handleFor(slackUserId);
  const answer = await conn.apex.post('/curbcut/v1/message/', {
    channel: 'Slack', text, handle,
  });
  let out = answer.message || '';
  if (answer.options) out += '\n\n' + answer.options;
  // Only ever add the send-elsewhere line when we actually returned options.
  if (answer.options) out += NO_SENDING;
  return out;
}

/* Slack wants a 200 within three seconds. Anything slower than that has to be
   acknowledged first and answered afterwards, and a person watching a spinner
   is a person being made to wait for no reason. */
function respond(res, payload) {
  if (res.headersSent || res.writableEnded) { return; }   // already acknowledged; never answer twice
  res.writeHead(200, { 'content-type': 'application/json' });
  res.end(JSON.stringify(payload));
}

/* A failed reply to one person must never take the app down for everyone
   else. Log it, keep the socket open, keep listening. */
process.on('uncaughtException', e => console.error('[slack] uncaught:', e?.message));
process.on('unhandledRejection', e => console.error('[slack] unhandled:', e?.message || e));

const server = http.createServer((req, res) => {
  if (req.method !== 'POST') { res.writeHead(405); return res.end(); }
  let raw = '';
  req.on('data', c => { raw += c; if (raw.length > 1e5) req.destroy(); });
  req.on('end', async () => {
    if (!signatureValid(raw, req.headers)) { res.writeHead(403); return res.end(); }

    // Slash commands arrive form-encoded, events as JSON.
    const isJson = (req.headers['content-type'] || '').includes('application/json');
    const body = isJson ? JSON.parse(raw) : Object.fromEntries(new URLSearchParams(raw));

    // Slack's one-time endpoint check.
    if (body.type === 'url_verification') {
      res.writeHead(200, { 'content-type': 'text/plain' });
      return res.end(body.challenge);
    }

    try {
      if (req.url.startsWith('/slack/command')) return await slashCommand(body, res);
      if (req.url.startsWith('/slack/events'))  return await event(body, res);
      res.writeHead(404); res.end();
    } catch (e) {
      console.error('[slack]', e?.message);
      respond(res, {
        response_type: 'ephemeral',
        text: 'Something went wrong on my end, and that is not your problem to ' +
              `solve. Try ${SITE}/ask, or say HUMAN here and a person will pick it up.`,
      });
    }
  });
});

/* The two handlers know nothing about how the message arrived. The HTTP server
   and the socket below are just two ways of delivering the same payloads, and
   the rules (DM only, never sends, says where you are standing) live in one
   place regardless of transport. */

/* /curbcut — always ephemeral, and refused outright in a channel. */
async function slashPayload(body) {
  const inChannel = body.channel_name && body.channel_name !== 'directmessage';
  if (inChannel) return { response_type: 'ephemeral', text: IN_CHANNEL_REFUSAL };
  const text = (body.text || '').trim();
  if (!text)     return { response_type: 'ephemeral', text: WHERE_YOU_ARE };
  const first = !seenUsers.has(body.user_id);
  seenUsers.add(body.user_id);
  const answer = await ask(text, body.user_id);
  return { response_type: 'ephemeral',
           text: first ? WHERE_YOU_ARE + '\n\n———\n\n' + answer : answer };
}
async function slashCommand(body, res) { respond(res, await slashPayload(body)); }

/* Direct messages to the app. Channel messages are ignored entirely - not
   answered quietly, ignored - except to say where to find me. */
async function handleDm(e) {
  if (!e || e.type !== 'message' || e.bot_id || e.subtype) return;
  if (e.channel_type !== 'im') return;  // never speak in a channel, at all
  const first = !seenUsers.has(e.user);
  seenUsers.add(e.user);
  const answer = await ask(e.text || '', e.user);
  await post(e.channel, first ? WHERE_YOU_ARE + '\n\n———\n\n' + answer : answer);
}
async function event(body, res) {
  respond(res, { ok: true });          // acknowledge inside Slack's 3s window
  if (!fresh(body.event_id)) return;
  await handleDm(body.event);
}

/* Socket Mode. The relay dials out to Slack over a websocket instead of Slack
   dialling in to a public URL, so a laptop behind a home router can run it
   with no tunnel and nothing exposed. Slack signs nothing on this path because
   nothing arrives unsolicited: the app-level token opened the socket. Each
   envelope must be acknowledged by id, and a slash command's ack carries the
   reply itself. Node 22 has a native WebSocket, so this needs no dependency. */
async function socketMode(appToken) {
  const open = await fetch('https://slack.com/api/apps.connections.open', {
    method: 'POST', headers: { authorization: `Bearer ${appToken}` },
  }).then(r => r.json());
  if (!open.ok) { console.error('[slack] socket open failed:', open.error); return; }

  const ws = new WebSocket(open.url);
  ws.onopen = () => console.log('  socket    connected, listening for DMs and /curbcut');
  ws.onclose = () => { console.log('  socket    closed, reconnecting in 3s'); setTimeout(() => socketMode(appToken), 3000); };
  ws.onerror = (e) => console.error('[slack] socket error', e?.message || e);
  ws.onmessage = async (m) => {
    let env; try { env = JSON.parse(m.data); } catch { return; }
    if (env.type === 'hello' || env.type === 'disconnect') return;
    const ack = (payload) => ws.send(JSON.stringify(
      payload === undefined ? { envelope_id: env.envelope_id } : { envelope_id: env.envelope_id, payload }));
    try {
      if (env.type === 'slash_commands') { ack(await slashPayload(env.payload)); return; }
      if (env.type === 'events_api') {
        ack();
        const id = env.payload?.event_id;
        console.log(`  event     ${id || '(no id)'} retry=${env.retry_attempt || 0}${env.retry_reason ? ' ' + env.retry_reason : ''}`);
        if (!fresh(id)) return;
        await handleDm(env.payload?.event);
        return;
      }
      ack();
    } catch (e) {
      console.error('[slack]', e?.message);
      ack();
    }
  };
}

async function post(channel, text) {
  const token = process.env.SLACK_BOT_TOKEN;
  if (!token) { console.error('[slack] no SLACK_BOT_TOKEN; cannot reply'); return; }
  await fetch('https://slack.com/api/chat.postMessage', {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify({ channel, text }),
  });
}

server.listen(PORT, () => {
  console.log(`Curb Cut Slack app on :${PORT}`);
  console.log(`  org       ${ALIAS}`);
  console.log(`  signature ${SIGNING_SECRET ? 'on' : 'OFF — set SLACK_SIGNING_SECRET'}`);
  console.log(`  reply     ${process.env.SLACK_BOT_TOKEN ? 'on' : 'OFF — set SLACK_BOT_TOKEN'}`);
  console.log(`  POST /slack/command   /curbcut, ephemeral only, refused in channels`);
  console.log(`  POST /slack/events    direct messages only`);
  if (process.env.SLACK_APP_TOKEN) socketMode(process.env.SLACK_APP_TOKEN);
  else console.log(`  socket    OFF — set SLACK_APP_TOKEN (xapp-…) to run without a public URL`);
});
