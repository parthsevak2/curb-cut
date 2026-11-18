// Delivery receipts, proved with no network and no org.
import assert from 'node:assert/strict';
import { createHmac, createHash } from 'node:crypto';
import { makeTwiml, makeSignatureValid, receiptFor, handleStatus } from '../channels/relay-lib.mjs';

const TOKEN = 'test-token';
const URL_ = 'https://relay.example.test';
const sign = (url, params) => createHmac('sha1', TOKEN)
  .update(Buffer.from(Object.keys(params).sort().reduce((a, k) => a + k + params[k], url)))
  .digest('base64');
const handleFor = (n) => createHash('sha256').update('salt' + n).digest('hex').slice(0, 32);
const safeHandle = (h) => (/^[0-9a-f]{32}$/.test(h) ? h : null);

// 1. The TwiML carries the callback only when there is a public URL.
const withUrl = makeTwiml(URL_)('hello', 'disclosure');
assert.equal((withUrl.match(/statusCallback="https:\/\/relay\.example\.test\/sms\/status"/g) || []).length, 2);
assert.match(withUrl, /method="POST"/);
assert.ok(!makeTwiml('')('hello').includes('statusCallback'));

// 2. Status mapping.
const map = (s) => receiptFor({ MessageStatus: s })?.status ?? null;
assert.equal(map('delivered'), 'Delivered');
assert.equal(map('undelivered'), 'Undelivered');
assert.equal(map('failed'), 'Undelivered');
for (const s of ['sent', 'queued', 'sending', 'accepted']) assert.equal(map(s), null);
assert.equal(receiptFor({ MessageStatus: 'undelivered', ErrorCode: '30005', MessageSid: 'SM123' }).detail,
  'carrier: undelivered, error 30005, sid SM123');

// 3. The route: refused when badly signed, writes one clean row when signed.
const rows = [];
const ledger = async (...r) => { rows.push(r); };
const base = { publicUrl: URL_, allowUnverified: false, signatureValid: makeSignatureValid(TOKEN),
               handleFor, safeHandle, ledger };
const params = { MessageStatus: 'undelivered', ErrorCode: '30005', MessageSid: 'SM123',
                 To: '+15551234567', Body: 'secret words' };

assert.equal(await handleStatus({ ...base, params, header: 'forged' }), 403);
assert.equal(await handleStatus({ ...base, params, header: undefined }), 403);
assert.equal(await handleStatus({ ...base, signatureValid: makeSignatureValid(''), params,
  header: sign(URL_ + '/sms/status', params) }), 403, 'no token fails closed');
assert.equal(rows.length, 0);

assert.equal(await handleStatus({ ...base, params, header: sign(URL_ + '/sms/status', params) }), 204);
assert.equal(rows.length, 1);
const [ch, dir, st, hash, detail] = rows[0];
assert.deepEqual([ch, dir, st], ['SMS', 'Outbound', 'Undelivered']);
assert.equal(hash, handleFor('+15551234567'));
assert.ok(!JSON.stringify(rows[0]).includes('5551234567') && !detail.includes('secret'));

const queued = { ...params, MessageStatus: 'queued' };
assert.equal(await handleStatus({ ...base, params: queued, header: sign(URL_ + '/sms/status', queued) }), 204);
assert.equal(rows.length, 1, 'non-terminal status writes no row');

// A ledger that throws must not escape the handler.
const boom = { ...base, ledger: async () => { throw new Error('down'); } };
assert.equal(await handleStatus({ ...boom, params, header: sign(URL_ + '/sms/status', params) }), 204);

console.log('delivery receipts: all checks passed');
