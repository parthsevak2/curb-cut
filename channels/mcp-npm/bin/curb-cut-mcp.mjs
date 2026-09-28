#!/usr/bin/env node
/**
 * Launcher for the npm-distributed Curb Cut MCP server.
 *
 * This file exists so the packaged copy of channels/mcp-server.mjs never has
 * to change. The server is the single source of truth and packaging must not
 * touch its behavior. All this wrapper does is check the ground the server is
 * about to stand on, so a missing Salesforce CLI or a missing org login fails
 * with a sentence a person can act on instead of a stack trace.
 *
 * It hands over by importing ../server.mjs resolved from this file's own URL.
 * There is no comparison against process.argv[1], on purpose: Recordist 0.1.0
 * shipped a direct-run guard that compared basenames and silently started
 * nothing under the npx shim symlink. Resolving from import.meta.url cannot
 * be fooled that way.
 */
import { existsSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { join } from 'node:path';

function fail(lines) {
  process.stderr.write(lines.join('\n') + '\n');
  process.exit(1);
}

const major = Number(process.versions.node.split('.')[0]);
if (major < 22) {
  fail([`curb-cut-mcp needs Node 22 or newer; this is ${process.versions.node}.`]);
}

// The server reads @salesforce/core out of the globally installed Salesforce
// CLI, because the CLI is the thing that holds the org login. Find it the
// same way the server will, and say something useful if it is not there.
let modules = process.env.SF_CLI_MODULES;
if (!modules) {
  let root = '';
  try { root = execSync('npm root -g', { encoding: 'utf8' }).trim(); } catch { /* checked below */ }
  modules = join(root, '@salesforce', 'cli', 'node_modules', '@salesforce');
}
if (!existsSync(join(modules, 'core'))) {
  fail([
    'curb-cut-mcp needs the Salesforce CLI. The CLI holds the org login, so this',
    'package deliberately ships no Salesforce dependencies of its own.',
    '',
    '  npm install -g @salesforce/cli',
    '  sf org login web --alias curbcut',
    '',
    'If the CLI is installed somewhere unusual, set SF_CLI_MODULES to its',
    'node_modules/@salesforce directory.',
  ]);
}
// Hand the resolved path to the server so it does not repeat the lookup.
process.env.SF_CLI_MODULES = modules;

try {
  await import(new URL('../server.mjs', import.meta.url));
} catch (e) {
  const msg = String(e?.message ?? e);
  if (/NamedOrgNotFound|No authorization information|No AuthInfo found/i.test(msg)) {
    const alias = process.env.SF_ORG_ALIAS || 'curbcut';
    fail([
      `The Salesforce CLI has no login for "${alias}".`,
      '',
      `  sf org login web --alias ${alias}`,
      '',
      'Or set SF_ORG_ALIAS to an alias you are already logged in to.',
    ]);
  }
  throw e;
}
