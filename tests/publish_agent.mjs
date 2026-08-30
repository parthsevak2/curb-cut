/**
 * Publishes the Curb_Cut authoring bundle using the CLI's own library, with the
 * underlying error surfaced. `sf agent publish` swallows the cause as
 * "fetch failed".
 */
import { Org, SfProject } from '/Users/drashtipathak/.nvm/versions/node/v22.22.2/lib/node_modules/@salesforce/cli/node_modules/@salesforce/core/lib/index.js';
import { ScriptAgent } from '/Users/drashtipathak/.nvm/versions/node/v22.22.2/lib/node_modules/@salesforce/cli/node_modules/@salesforce/agents/lib/index.js';

const org = await Org.create({ aliasOrUsername: 'curbcut' });
const project = await SfProject.resolve('/Users/drashtipathak/Downloads/curbcut_check');
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
