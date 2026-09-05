/**
 * Publishes the Curb_Cut authoring bundle using the CLI's own library, with the
 * underlying error surfaced. `sf agent publish` swallows the cause as
 * "fetch failed".
 */
import { execSync } from 'node:child_process';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

// The Salesforce CLI bundles @salesforce/core and @salesforce/agents. Find
// them where the CLI is installed, not where one laptop happened to keep them.
// SF_CLI_MODULES overrides the lookup when the CLI lives somewhere unusual.
const SF_CLI_MODULES = process.env.SF_CLI_MODULES
  || join(execSync('npm root -g', { encoding: 'utf8' }).trim(),
          '@salesforce', 'cli', 'node_modules', '@salesforce');
const { Org, SfProject } = await import(join(SF_CLI_MODULES, 'core',   'lib', 'index.js'));
const { ScriptAgent }    = await import(join(SF_CLI_MODULES, 'agents', 'lib', 'index.js'));

// The project is the folder above tests/, wherever this checkout lives.
const PROJECT_DIR = fileURLToPath(new URL('..', import.meta.url));
const ALIAS = process.env.SF_ORG_ALIAS || 'curbcut';

const org = await Org.create({ aliasOrUsername: ALIAS });
const project = await SfProject.resolve(PROJECT_DIR);
const agent = new ScriptAgent({
  connection: org.getConnection(),
  project,
  aabName: 'Curb_Cut',
});
try {
  const res = await agent.publish(false);
  console.log('PUBLISH OK:', JSON.stringify(res, null, 2).slice(0, 1200));
} catch (e) {
  console.error('PUBLISH FAILED:', e?.name, '|', e?.message);
  let c = e?.cause;
  let depth = 0;
  while (c && depth++ < 5) {
    console.error('  cause:', c?.name, '|', c?.message, '|', c?.code, '|', c?.errno);
    c = c.cause;
  }
  if (e?.stack) console.error(e.stack.split('\n').slice(0, 6).join('\n'));
}
