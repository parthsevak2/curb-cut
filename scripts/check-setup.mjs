#!/usr/bin/env node
// Curb Cut setup check. Read-only: it only runs queries and a describe.
// Usage: node scripts/check-setup.mjs <org-alias>
// Zero dependencies. Needs Node 18+ and the Salesforce CLI (sf).
import { spawnSync } from 'node:child_process';
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const LABELS_FILE = join(ROOT, 'force-app/main/default/labels/CustomLabels.labels-meta.xml');
const KEYS_CLASS = join(ROOT, 'force-app/main/default/classes/CurbCutKeys.cls');
const MIN_CLI = [2, 149];
const SEED_ROWS = 36;
const alias = process.argv[2];

if (!alias || alias.startsWith('-')) {
  console.error('Usage: node scripts/check-setup.mjs <org-alias>');
  console.error('Example: node scripts/check-setup.mjs curbcut');
  process.exit(2);
}
if (Number(process.versions.node.split('.')[0]) < 18) {
  console.error('This check needs Node 18 or newer. Update Node, then run it again.');
  process.exit(2);
}

// Never let a token or login URL reach the screen.
const clean = (s) => String(s || '')
  .replace(/force:\/\/\S+/g, '[hidden]')
  .replace(/sid=\S+/gi, '[hidden]')
  .replace(/00D[A-Za-z0-9]{12,15}![A-Za-z0-9._]+/g, '[hidden]')
  .replace(/https?:\/\/\S+/g, '[link hidden]');
const firstLine = (s) => clean(s).split('\n').map((l) => l.trim()).filter(Boolean)[0] || 'no detail given';

function sf(args) {
  const r = spawnSync('sf', args, { encoding: 'utf8', shell: process.platform === 'win32', maxBuffer: 32 * 1024 * 1024 });
  if (r.error) return { ok: false, missing: r.error.code === 'ENOENT', message: String(r.error.message), json: null };
  const out = r.stdout || '';
  let json = null;
  const i = out.indexOf('{');
  if (i >= 0) { try { json = JSON.parse(out.slice(i)); } catch { json = null; } }
  const ok = r.status === 0 && (!json || json.status === 0);
  const message = (json && (json.message || (json.result && json.result.message))) || r.stderr || out;
  return { ok, json, message, text: out };
}
const soqlSafe = (s) => String(s).replace(/'/g, "\\'");
function query(soql, tooling = false) {
  const args = ['data', 'query', '--query', soql, '--target-org', alias, '--json'];
  if (tooling) args.push('--use-tooling-api');
  const r = sf(args);
  if (!r.ok) throw new Error(firstLine(r.message));
  return r.json.result.records || [];
}

let failed = 0;
const line = (mark, text) => console.log(`${mark} ${text}`);
const pass = (t) => line('✓', t);
const fail = (t) => { failed++; line('✗', t); };
const optional = (t) => line('○', `(optional) ${t}`);
const note = (t) => line('·', t);
async function check(name, fn) {
  try { await fn(); } catch (e) { fail(`${name}: could not be checked (${firstLine(e.message)}). Run it again, and if it keeps failing, open an issue with this line.`); }
}

// 1. CLI version
const ver = sf(['--version']);
if (ver.missing || !ver.text) {
  fail('The Salesforce CLI is not installed. Install it with: npm install -g @salesforce/cli@latest');
  process.exit(1);
}
const m = /cli\/(\d+)\.(\d+)\.(\d+)/.exec(ver.text);
if (!m) fail('Could not read the Salesforce CLI version. Update it with: npm install -g @salesforce/cli@latest');
else if (+m[1] < MIN_CLI[0] || (+m[1] === MIN_CLI[0] && +m[2] < MIN_CLI[1])) {
  fail(`The Salesforce CLI is ${m[1]}.${m[2]}.${m[3]}. Curb Cut needs 2.149 or later, because older ones silently drop the agent file. Update it with: npm install -g @salesforce/cli@latest`);
} else pass(`Salesforce CLI ${m[1]}.${m[2]}.${m[3]} is new enough.`);

// 2. Org reachable (a real query, so expired logins are caught)
let user = null, orgId = null;
{
  const r = sf(['data', 'query', '--query', 'SELECT Id FROM Organization LIMIT 1', '--target-org', alias, '--json']);
  if (!r.ok) {
    const msg = String(r.message || '');
    if (/NoDefaultEnvError|No authorization|not found|NamedOrgNotFound/i.test(msg)) {
      fail(`No org called "${alias}" is logged in on this machine. Log in with: sf org login web --alias ${alias}`);
    } else {
      fail(`Cannot reach the org "${alias}" (${firstLine(msg)}). Log in again with: sf org login web --alias ${alias}`);
    }
    note('Skipped the other checks, because they all need a reachable org.');
    process.exit(1);
  }
  pass(`Org "${alias}" is reachable.`);
  const d = sf(['org', 'display', '--target-org', alias, '--json']);
  if (d.ok && d.json.result) { user = d.json.result.username; orgId = d.json.result.id; }
}

// 3. Objects deployed
await check('Curb Cut objects', () => {
  const r = sf(['sobject', 'describe', '--sobject', 'Accommodation_Option__c', '--target-org', alias, '--json']);
  if (r.ok) pass('Curb Cut objects are deployed.');
  else fail('Curb Cut objects are not in the org yet. Deploy them with: sf project deploy start --source-dir force-app --target-org ' + alias);
});

// 4. Seed library
await check('Seed library', () => {
  const r = sf(['data', 'query', '--query', 'SELECT COUNT() FROM Accommodation_Option__c', '--target-org', alias, '--json']);
  if (!r.ok) return fail('The accommodation library cannot be read. Deploy first, then assign the Curb_Cut_Access permission set.');
  const n = r.json.result.totalSize;
  if (n === 0) fail(`The accommodation library is empty. Load it with: sf data import bulk --sobject Accommodation_Option__c --file accommodation_options_seed.csv --target-org ${alias} --wait 10`);
  else if (n < SEED_ROWS) fail(`The library has ${n} of ${SEED_ROWS} rows. Delete the rows in Accommodation Options, then import accommodation_options_seed.csv again.`);
  else pass(`The accommodation library has ${n} rows${n === SEED_ROWS ? '' : ` (the seed has ${SEED_ROWS}; extra rows are yours)`}.`);
});

// 5. Permission set on the current user
await check('Curb_Cut_Access', () => {
  if (!user) return fail('Could not tell which user the CLI is logged in as. Log in again with: sf org login web --alias ' + alias);
  const rows = query(`SELECT Id FROM PermissionSetAssignment WHERE Assignee.Username = '${soqlSafe(user)}' AND PermissionSet.Name = 'Curb_Cut_Access'`);
  if (rows.length) pass('Curb_Cut_Access is assigned to the user you are logged in as.');
  else fail(`Curb_Cut_Access is not assigned to you. Run: sf org assign permset --name Curb_Cut_Access --target-org ${alias}`);
});

// 6. Agents and active versions
await check('Agents', () => {
  const bots = query("SELECT Id, DeveloperName FROM BotDefinition WHERE DeveloperName IN ('Curb_Cut','Curb_Cut_Desk')");
  const versions = query("SELECT BotDefinition.DeveloperName, Status FROM BotVersion WHERE BotDefinition.DeveloperName IN ('Curb_Cut','Curb_Cut_Desk')");
  for (const [dev, label] of [['Curb_Cut', 'Curb Cut'], ['Curb_Cut_Desk', 'Curb Cut Desk']]) {
    if (!bots.some((b) => b.DeveloperName === dev)) {
      fail(`The agent ${label} is not in the org. Deploy again, and if it still does not appear, check your CLI is 2.149 or later.`);
    } else if (!versions.some((v) => v.BotDefinition && v.BotDefinition.DeveloperName === dev && v.Status === 'Active')) {
      fail(`The agent ${label} has no active version. In Setup, open Agentforce Builder, open ${label}, save a version, and activate it. If activation says "fetch failed", accept the Einstein Bots terms in Setup first.`);
    } else pass(`The agent ${label} exists and has an active version.`);
  }
});

// 7. Site and guest user
await check('Site', () => {
  const sites = query('SELECT Id, Name, UrlPathPrefix, GuestUserId, Status FROM Site');
  const site = sites.find((s) => /^curbcut$/i.test(s.UrlPathPrefix || '') || /curb_?cut/i.test(s.Name || ''));
  if (!site) return fail('There is no Curb Cut site yet. In Setup, open Sites, create one with the home page CurbCutHome, and give its guest user the Curb_Cut_Guest permission set.');
  if (site.Status && site.Status !== 'Active') fail(`The Curb Cut site exists but is ${site.Status}. In Setup, open Sites and activate it.`);
  else pass('A Curb Cut site exists and is active.');
  if (!site.GuestUserId) return fail('The site has no guest user that I can see. Open the site in Setup and check its Public Access Settings.');
  const held = query(`SELECT PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = '${soqlSafe(site.GuestUserId)}'`).map((r) => r.PermissionSet && r.PermissionSet.Name);
  if (held.includes('Curb_Cut_Access')) fail('The site guest user holds Curb_Cut_Access, which would let anyone on the internet read people\'s requests. Remove it now. The guest should hold only Curb_Cut_Guest.');
  else pass('The site guest user does not hold Curb_Cut_Access.');
  if (held.includes('Curb_Cut_Guest')) pass('The site guest user holds Curb_Cut_Guest.');
  else fail('The site guest user does not hold Curb_Cut_Guest. In Setup, open Sites, open Public Access Settings, and assign the Curb_Cut_Guest permission set.');
});

// 8. Custom labels (names and placeholder values read from the repo's labels file)
await check('Custom labels', () => {
  if (!existsSync(LABELS_FILE)) return fail('Run this from a Curb Cut checkout: the labels file is missing.');
  const xml = readFileSync(LABELS_FILE, 'utf8');
  const shipped = {};
  for (const mm of xml.matchAll(/<fullName>(\w+)<\/fullName>[\s\S]*?<value>([^<]*)<\/value>/g)) shipped[mm[1]] = mm[2].trim();
  const names = Object.keys(shipped);
  const rows = query(`SELECT Name, Value FROM ExternalString WHERE Name IN (${names.map((n) => `'${soqlSafe(n)}'`).join(',')})`, true);
  // A label still holding the value the repository ships is a placeholder, as
  // is anything that still says YOUR-, REPLACE or example.com.
  const isPlaceholder = (name, v) => !v || v.trim() === shipped[name] || /YOUR-|REPLACE|example\.com/i.test(v);
  const valueOf = (name) => (rows.find((r) => r.Name === name) || {}).Value;
  // Doors that are switched on by a label: the site offers them only when set.
  const doors = {
    CurbCut_SMS_Number_Link: (v) => `Text and voice are offered on your site, on ${valueOf('CurbCut_SMS_Number') || v}.`,
    CurbCut_Inbound_Email: () => 'The email door is offered on your site.',
  };
  const doorOff = {
    CurbCut_SMS_Number_Link: 'Text and voice are off, so your site does not offer them. To add them, connect your own number: DEPLOY.md step 7.',
    CurbCut_Inbound_Email: 'The email door is not on your site yet. Copy the address from Setup, Email Services, CurbCutInbound into CurbCut_Inbound_Email and deploy the labels.',
  };
  const companion = new Set(['CurbCut_SMS_Number']);   // reported with its link label
  for (const name of names) {
    if (companion.has(name)) continue;
    const row = rows.find((r) => r.Name === name);
    const placeholder = !row || isPlaceholder(name, row.Value);
    if (doors[name]) {
      if (placeholder) optional(doorOff[name]);
      else pass(doors[name](row.Value));
    } else if (!placeholder) pass(`Label ${name} is set.`);
    else if (!row) fail(`Label ${name} is not in the org. Deploy again with: sf project deploy start --source-dir force-app/main/default/labels --target-org ${alias}`);
    else fail(`Label ${name} still holds the placeholder. Put your real value in force-app/main/default/labels/CustomLabels.labels-meta.xml and deploy the labels again.`);
  }
});

// 9. Inbound email service
await check('Email service', () => {
  const rows = query("SELECT Id, IsActive FROM EmailServicesFunction WHERE FunctionName = 'CurbCutInbound'");
  if (!rows.length) fail('The email service CurbCutInbound is not in the org. Deploy again with: sf project deploy start --source-dir force-app --target-org ' + alias);
  else if (rows[0].IsActive === false) fail('The email service CurbCutInbound is switched off. In Setup, open Email Services and make it active.');
  else pass('The email service CurbCutInbound exists and is active.');
});

// 10. HMAC key (existence only; the value is never selected)
await check('HMAC key', () => {
  if (!existsSync(KEYS_CLASS)) return note('The HMAC key check is skipped, because this version of Curb Cut has no CurbCutKeys class.');
  let rows;
  try {
    rows = query(`SELECT Id FROM Curb_Cut_Secret__c WHERE SetupOwnerId = '${soqlSafe(orgId || '')}' AND Key__c != null LIMIT 1`);
  } catch (e) {
    // The setting itself is missing: this org runs a Curb Cut from before the key.
    if (/Curb_Cut_Secret__c|not supported|INVALID_TYPE/i.test(e.message)) {
      return fail(`The signing key's setting is not in the org yet. Deploy this version (bash scripts/install.sh ${alias}), which also creates the key.`);
    }
    throw e;
  }
  if (rows.length) pass('The per-org HMAC key is configured.');
  else fail(`The per-org HMAC key is not set. Run: sf apex run --file scripts/apex/generate-key.apex --target-org ${alias}`);
});

// Things this script cannot see
note('Einstein Bots terms cannot be checked from the CLI. If activating an agent fails with "fetch failed", accept them in Setup, under Einstein Bots.');
optional('The text and voice relay (Twilio) runs outside Salesforce, so it is not checked here.');
optional('The Slack door runs outside Salesforce, so it is not checked here.');

console.log('');
if (failed) { console.log(`${failed} thing${failed === 1 ? '' : 's'} left to do. Fix them in the order shown, then run this check again.`); process.exit(1); }
console.log('Everything required is in place.');
