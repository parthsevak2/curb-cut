#!/usr/bin/env node
/* One real conversation with the deployed Agentforce agent, saved as it
   happened, for the film. Nothing here is scripted on the agent's side: the
   person's lines are fixed, the agent's replies are whatever the live agent
   says. If a run does not do what the film needs, the run is kept and named,
   not edited. Reads the same CLI-held credential the test runner uses. */
import { execSync } from 'node:child_process';
import { writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';

const ALIAS = process.env.SF_ORG_ALIAS || 'curbcut';
const AGENT = process.env.CURBCUT_AGENT || 'Curb_Cut';
const OUT   = process.env.TAKE_DIR || 'takes';

// The CLI bundles @salesforce/core and @salesforce/agents; find them where the
// CLI is installed rather than where one laptop keeps them.
const root = execSync('npm root -g', { encoding: 'utf8' }).trim();
const cli  = join(root, '@salesforce', 'cli', 'node_modules', '@salesforce');
const { Org }             = await import(join(cli, 'core',   'lib', 'index.js'));
const { ProductionAgent } = await import(join(cli, 'agents', 'lib', 'index.js'));

const TAKES = {
  // The seam the design rests on: a hedge is not a yes.
  yes_gate: [
    'I want to ask for captions in all my meetings.',
    "I guess so, I think that's probably fine?",
    'Yes, send it.',
  ],
  // A volunteered condition is taken out before anything is stored, and the
  // person is told so.
  volunteered: [
    "I have multiple sclerosis and some days I can't type for long.",
  ],
};

const which = process.argv[2] || 'yes_gate';
const lines = TAKES[which];
if (!lines) { console.error('unknown take', which, 'choose from', Object.keys(TAKES)); process.exit(2); }

const org = await Org.create({ aliasOrUsername: ALIAS });
const connection = org.getConnection();
const agent = new ProductionAgent({ connection, apiNameOrId: AGENT });
await agent.preview.start();

const turns = [];
for (const said of lines) {
  const t0 = Date.now();
  const res = await agent.preview.send(said);
  const reply = (res?.messages ?? []).map(m => m.message).filter(Boolean).join('\n\n');
  turns.push({ said, reply, ms: Date.now() - t0 });
  process.stderr.write(`> ${said}\n< ${reply.slice(0, 140).replace(/\n/g, ' ')}\n\n`);
}
try { await agent.preview.end('UserRequest'); } catch {}

mkdirSync(OUT, { recursive: true });
const stamp = new Date().toISOString().replace(/[:.]/g, '-');
const file = join(OUT, `${which}-${stamp}.json`);
writeFileSync(file, JSON.stringify({ agent: AGENT, take: which, when: new Date().toISOString(), turns }, null, 2));
console.log(file);
