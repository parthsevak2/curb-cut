#!/usr/bin/env node
/*
 * Make Curb Cut yours without editing XML.
 *
 *   node scripts/configure.mjs <org-alias>            asks only what it cannot find out
 *   node scripts/configure.mjs <org-alias> --yes      no questions: detected values and env
 *   node scripts/configure.mjs <org-alias> --dry-run  shows what it would write, writes nothing
 *
 * It reads your org (queries only, nothing in the org changes) to find what it
 * can: your organisation's name, your site's address, the inbound email address
 * Salesforce generated, and your agent user. Then it asks plain questions for
 * the rest and writes the answers into this checkout: the six labels in
 * force-app/main/default/labels/CustomLabels.labels-meta.xml and the agent user
 * in both .agent files. Run it again any time; values already set are kept.
 *
 * Text and voice stay off unless you give a number from your own Twilio
 * account, and the site only offers the email door once Salesforce has made
 * the inbound address. Nobody is ever pointed at a door that does not answer.
 *
 * Without a terminal (CI), answers come from the environment:
 *   CURB_CUT_OPERATOR, CURB_CUT_SUPPORT_EMAIL, CURB_CUT_SMS_NUMBER, CURB_CUT_AGENT_USER
 *
 * Your values belong in your copy, not in the public repository: the invariant
 * suite fails a commit that carries them, so they cannot leak by accident.
 */
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createInterface } from 'node:readline/promises';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const LABELS = join(ROOT, 'force-app/main/default/labels/CustomLabels.labels-meta.xml');
const AGENTS = ['Curb_Cut', 'Curb_Cut_Desk'].map((n) =>
  join(ROOT, `force-app/main/default/aiAuthoringBundles/${n}/${n}.agent`));

const args = process.argv.slice(2);
const alias = args.find((a) => !a.startsWith('--'));
const YES = args.includes('--yes') || !process.stdin.isTTY;
const DRY = args.includes('--dry-run');
if (!alias) {
  console.log('Tell me which org to configure for. Use: node scripts/configure.mjs <org-alias>');
  process.exit(2);
}

// Placeholders are the values the repository ships. A value matching one of
// these has not been set yet.
const PLACEHOLDER = /YOUR-|REPLACE|example\.com|000 000 0000|^\+10000000000$|Your organisation, City/i;
const isSet = (v) => Boolean(v && v.trim()) && !PLACEHOLDER.test(v);

// ---------------------------------------------------------------- the org
function sf(argv) {
  const r = spawnSync('sf', argv, { encoding: 'utf8', shell: process.platform === 'win32', maxBuffer: 16 * 1024 * 1024 });
  if (r.error) return null;
  try { return JSON.parse(r.stdout); } catch { return null; }
}
function query(soql) {
  const d = sf(['data', 'query', '--query', soql, '--target-org', alias, '--json']);
  return d && d.status === 0 ? (d.result.records || []) : null;
}
if (!query('SELECT Id FROM Organization LIMIT 1')) {
  console.log(`I cannot reach the org "${alias}". Log in with: sf org login web --alias ${alias}`);
  process.exit(1);
}

function detectOperator() {
  const r = query('SELECT Name FROM Organization LIMIT 1');
  return r && r[0] ? r[0].Name : '';
}
function detectSiteUrl() {
  const rows = query('SELECT Domain.Domain, PathPrefix, Site.UrlPathPrefix FROM DomainSite') || [];
  const ours = rows.find((r) => /curbcut/i.test(`${r.PathPrefix || ''} ${(r.Site || {}).UrlPathPrefix || ''}`)) || (rows.length === 1 ? rows[0] : null);
  return ours && ours.Domain ? `https://${ours.Domain.Domain}${ours.PathPrefix || ''}`.replace(/\/$/, '') : '';
}
function detectInboundEmail() {
  const rows = query("SELECT (SELECT LocalPart, EmailDomainName, IsActive FROM Addresses) FROM EmailServicesFunction WHERE FunctionName = 'CurbCutInbound'") || [];
  for (const f of rows) {
    for (const a of ((f.Addresses || {}).records || [])) {
      if (a.IsActive) return `${a.LocalPart}@${a.EmailDomainName}`;
    }
  }
  return '';
}
function detectAgentUsers() {
  const rows = query("SELECT Username FROM User WHERE IsActive = true AND Profile.UserLicense.Name = 'Einstein Agent' ORDER BY CreatedDate LIMIT 10") || [];
  return rows.map((r) => r.Username);
}

// ---------------------------------------------------------------- the files
const xmlEscape = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&apos;');
const xmlUnescape = (s) => String(s).replace(/&apos;/g, "'").replace(/&quot;/g, '"').replace(/&gt;/g, '>').replace(/&lt;/g, '<').replace(/&amp;/g, '&');
let labelsXml = readFileSync(LABELS, 'utf8');
function labelValue(name) {
  const m = new RegExp(`<fullName>${name}</fullName>[\\s\\S]*?<value>([^<]*)</value>`).exec(labelsXml);
  return m ? xmlUnescape(m[1]) : '';
}
function setLabel(name, value) {
  const re = new RegExp(`(<fullName>${name}</fullName>[\\s\\S]*?<value>)([^<]*)(</value>)`);
  if (!re.test(labelsXml)) throw new Error(`The labels file has no ${name}. Update your checkout, then run this again.`);
  labelsXml = labelsXml.replace(re, (_, a, __, c) => a + xmlEscape(value) + c);
}
function agentUser() {
  const m = /default_agent_user:\s*"([^"]*)"/.exec(readFileSync(AGENTS[0], 'utf8'));
  return m ? m[1] : '';
}

// ---------------------------------------------------------------- questions
const rl = YES ? null : createInterface({ input: process.stdin, output: process.stdout });
async function ask(question, fallback) {
  if (YES) return fallback;
  const hint = fallback ? ` [${fallback}]` : '';
  const a = (await rl.question(`${question}${hint}\n> `)).trim();
  return a || fallback;
}
const looksLikeEmail = (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
// Accepts "+1 416 555 0123", "(416) 555-0123", "14165550123", "+447700900123".
function toE164(v) {
  const digits = String(v).replace(/[^\d+]/g, '');
  if (/^\+\d{8,15}$/.test(digits)) return digits;
  const d = digits.replace(/\D/g, '');
  if (d.length === 10) return `+1${d}`;
  if (d.length === 11 && d.startsWith('1')) return `+${d}`;
  return '';
}

const result = [];   // [mark, sentence]
const ok = (t) => result.push(['✓', t]);
const off = (t) => result.push(['○', t]);
const todo = (t) => result.push(['!', t]);

console.log(`Configuring Curb Cut for "${alias}". I only read your org; nothing there changes.\n`);

// 1. Who runs it
{
  const now = labelValue('CurbCut_Operator');
  const v = isSet(now) ? now : await ask('Who runs this deployment, as people should read it? Your organisation, and where it is.', process.env.CURB_CUT_OPERATOR || detectOperator());
  if (isSet(v)) { setLabel('CurbCut_Operator', v); ok(`Run by: ${v}`); }
  else todo('Who runs this is not set yet. Run this again and answer the first question.');
}

// 2. The access desk's mailbox
{
  const now = labelValue('CurbCut_Support_Email');
  let v = isSet(now) ? now : await ask('Which mailbox does your access desk read? Use a shared inbox, never one person\'s own.', process.env.CURB_CUT_SUPPORT_EMAIL || '');
  while (!YES && v && !looksLikeEmail(v)) v = await ask('That does not look like an email address. Try again, or press Enter to leave it for now.', '');
  if (v && looksLikeEmail(v) && isSet(v)) { setLabel('CurbCut_Support_Email', v); ok(`Access desk: ${v}`); }
  else todo('The access desk mailbox is not set yet. Every reply that cannot reach a person points here, so set it before you go live.');
}

// 3. The site's address: found, never asked
{
  const now = labelValue('CurbCut_Site_URL');
  const v = detectSiteUrl() || (isSet(now) ? now : '');
  if (v) { setLabel('CurbCut_Site_URL', v); ok(`Site: ${v}`); }
  else todo('No Curb Cut site in the org yet. Create it (DEPLOY.md step 5), then run this again and I will find its address.');
}

// 4. The inbound email address: found, never asked
{
  const now = labelValue('CurbCut_Inbound_Email');
  const v = detectInboundEmail() || (isSet(now) ? now : '');
  if (v) { setLabel('CurbCut_Inbound_Email', v); ok('Email door: on. The site offers the address Salesforce made for CurbCutInbound.'); }
  else off('Email door: off for now. Salesforce makes the address once CurbCutInbound is deployed; run this again after the deploy.');
}

// 5. Text and voice: only with a number of their own
{
  const nowLink = labelValue('CurbCut_SMS_Number_Link');
  let link = isSet(nowLink) ? nowLink : '';
  let display = isSet(labelValue('CurbCut_SMS_Number')) ? labelValue('CurbCut_SMS_Number') : '';
  if (!link) {
    let typed = await ask('Text and voice need a number from your own Twilio account. Type it, or press Enter to leave texting and calling off.', process.env.CURB_CUT_SMS_NUMBER || '');
    while (!YES && typed && !toE164(typed)) typed = await ask('I could not read that as a phone number. Try again with the country code, or press Enter to skip.', '');
    if (typed && toE164(typed)) { link = toE164(typed); display = typed.trim(); }
  }
  if (link) {
    setLabel('CurbCut_SMS_Number_Link', link);
    setLabel('CurbCut_SMS_Number', display || link);
    ok(`Text and voice: on, at ${display || link}. Connect the relay next: DEPLOY.md step 7.`);
  } else {
    off('Text and voice: off. The site will not offer them until you add a number. DEPLOY.md step 7 shows how.');
  }
}

// 6. The agent user
{
  const now = agentUser();
  let v = isSet(now) ? now : '';
  if (!v) {
    const found = detectAgentUsers();
    if (found.length && !YES) console.log(`\nAgent users in your org: ${found.join(', ')}`);
    v = await ask('Which user should the agents run as? It must be an Einstein Agent user.', process.env.CURB_CUT_AGENT_USER || found[0] || '');
  }
  if (isSet(v)) {
    for (const f of AGENTS) {
      if (!existsSync(f)) continue;
      const s = readFileSync(f, 'utf8').replace(/(default_agent_user:\s*")[^"]*(")/, `$1${v.replace(/"/g, '')}$2`);
      if (!DRY) writeFileSync(f, s);
    }
    ok(`Agents run as: ${v}`);
  } else {
    todo('No agent user yet. Create one with the Einstein Agent licence (Setup, Users), then run this again. The agents deploy without it, but cannot be activated.');
  }
}

if (rl) rl.close();
if (!DRY) writeFileSync(LABELS, labelsXml);

console.log('');
for (const [mark, text] of result) console.log(`${mark} ${text}`);
const left = result.filter(([m]) => m === '!').length;
console.log(DRY ? '\nDry run: nothing was written.'
  : `\nWritten to your checkout. ${left ? `${left} thing${left > 1 ? 's' : ''} still to do, above.` : 'Everything I need is set.'} Deploy the labels with:\n  sf project deploy start --source-dir force-app/main/default/labels --target-org ${alias}`);
