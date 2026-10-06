#!/usr/bin/env node
/**
 * Launcher for the npm-distributed Curb Cut MCP server.
 *
 * This file exists so the packaged copy of channels/mcp-server.mjs never has
 * to change. The server is the single source of truth and packaging must not
 * touch its behavior. All this wrapper does is check the ground the server is
 * about to stand on and say, in a sentence a person can act on, what is
 * missing.
 *
 * A missing Salesforce CLI is a warning, not a stop. The server answers
 * initialize and tools/list without the CLI or an org, so a directory can
 * check that it starts, and a tool call that does need the org returns the
 * setup steps as its result. Only a Node too old to run the server at all
 * still exits.
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

const major = Number(process.versions.node.split('.')[0]);
if (major < 22) {
  process.stderr.write(`curb-cut-mcp needs Node 22 or newer; this is ${process.versions.node}.\n`);
  process.exit(1);
}

// The server reads @salesforce/core out of the globally installed Salesforce
// CLI, because the CLI is the thing that holds the org login. Find it the
// same way the server will. stdout must stay clean: it is the MCP channel.
let modules = process.env.SF_CLI_MODULES;
if (!modules) {
  let root = '';
  try {
    root = execSync('npm root -g', { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
  } catch { /* no npm on PATH; treated as no CLI below */ }
  if (root) modules = join(root, '@salesforce', 'cli', 'node_modules', '@salesforce');
}
if (modules && existsSync(join(modules, 'core'))) {
  // Hand the resolved path to the server so it does not repeat the lookup.
  process.env.SF_CLI_MODULES = modules;
} else {
  const alias = process.env.SF_ORG_ALIAS || 'curbcut';
  process.stderr.write(
    'Curb Cut tools need the Salesforce CLI and an org login: npm i -g @salesforce/cli, ' +
    `then sf org login web --alias ${alias}\n`);
}

await import(new URL('../server.mjs', import.meta.url));
