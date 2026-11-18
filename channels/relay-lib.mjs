/**
 * Curb Cut — pure pieces of the SMS relay.
 *
 * Split out so a test can load them without the Salesforce CLI, an org, or a
 * listening port. Nothing here touches the network or reads the environment;
 * the relay passes in what each piece needs.
 */
import { createHmac } from 'node:crypto';

export const xmlEscape = (s) => String(s)
  .replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;')
  .replaceAll('"','&quot;').replaceAll("'",'&apos;');

/* Twilio's own attribute is statusCallback, on <Message>. With it, Twilio
   POSTs the carrier outcome here later. Without a public URL there is nowhere
   to send it, so the attribute is left off rather than emitted broken. */
export const statusCallbackUrl = (publicUrl) => (publicUrl ? `${publicUrl}/sms/status` : '');

// More than one <Message> is allowed, and the order matters. The useful answer
// goes first and the disclosure second, because someone who is having a hard
// enough week to be texting this number should not have to read carrier
// boilerplate before they read the help.
export const makeTwiml = (publicUrl) => (...bodies) => {
  const cb = statusCallbackUrl(publicUrl);
  const attrs = cb ? ` statusCallback="${xmlEscape(cb)}" method="POST"` : '';
  return `<?xml version="1.0" encoding="UTF-8"?><Response>` +
    bodies.filter(Boolean).map(b => `<Message${attrs}>${xmlEscape(b)}</Message>`).join('') +
    `</Response>`;
};

// Twilio signs each request with the auth token over URL + sorted params.
/* Fails CLOSED. This used to return true when no token was configured, which
   meant an empty TWILIO_AUTH_TOKEN - exactly what was sitting in channels/.env -
   turned every unsigned request into a valid one. Anyone who learned the URL
   could post a forged From and Body, drive the agent, create handoffs and write
   to the ledger. An unverified webhook must refuse, not wave things through. */
export const verifySignature = (token, url, params, header) => {
  if (!token) return false;
  const data = Object.keys(params).sort()
    .reduce((acc, k) => acc + k + params[k], url);
  const expected = createHmac('sha1', token).update(Buffer.from(data,'utf-8')).digest('base64');
  return header === expected;
};
export const makeSignatureValid = (token) => (url, params, header) =>
  verifySignature(token, url, params, header);

/* Only the carrier's last word is worth a row. queued, sent and the rest are
   steps on the way, and one row per step would bury the one that matters.
   Returns null for anything that is not final. Never reads the body or prints
   the number; the detail is the outcome, the error code and the message sid. */
export function receiptFor(params) {
  const carrier = String(params.MessageStatus || params.SmsStatus || '').toLowerCase();
  const status = carrier === 'delivered' ? 'Delivered'
    : (carrier === 'undelivered' || carrier === 'failed') ? 'Undelivered' : null;
  if (!status) return null;
  const err = params.ErrorCode ? `, error ${String(params.ErrorCode).slice(0, 10)}` : '';
  const sid = params.MessageSid ? `, sid ${String(params.MessageSid).slice(0, 40)}` : '';
  return { status, detail: `carrier: ${carrier}${err}${sid}` };
}

/* The status webhook. Same guard as the inbound ones, same refusal. Returns
   the HTTP status to send. A failure to log is swallowed here as well as in
   ledger(), because Twilio retries on errors and a retry storm helps no one. */
export async function handleStatus({ params, header, publicUrl, allowUnverified,
                                     signatureValid, handleFor, safeHandle, ledger }) {
  if (!allowUnverified && !signatureValid(publicUrl + '/sms/status', params, header)) return 403;
  const receipt = receiptFor(params);
  if (!receipt) return 204;
  try {
    await ledger('SMS', 'Outbound', receipt.status, safeHandle(handleFor(params.To || '')), receipt.detail);
  } catch (e) {
    console.error('[status]', e?.message);
  }
  return 204;
}
