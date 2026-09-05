#!/usr/bin/env node
/**
 * Curb Cut — Model Context Protocol server.
 *
 * Why this exists.
 *
 * The argument on /curbcut/why is that the employer's side of an accommodation
 * conversation is automated and the person's side is not. Building one agent
 * only half answers that, because it still asks the person to come to us. Most
 * people who need this are already inside some other assistant, and the useful
 * move is to make the library reachable from there.
 *
 * What this surface deliberately cannot do.
 *
 * It can look things up and it can draft. It CANNOT send anything to anybody.
 * Sending requires an explicit yes from the person in a conversation they are
 * present for, and a tool call made by another model is not that. An MCP client
 * could otherwise be prompt-injected into filing an accommodation request in
 * someone's name, which is a disclosure they did not make and cannot take back.
 *
 * There is also no tool that accepts a diagnosis, because there is nowhere in
 * the system to put one. A caller who sends one gets told so.
 *
 * Zero dependencies. JSON-RPC 2.0 over stdio, framed by Content-Length, which
 * is all MCP actually requires of a server.
 */
import { createInterface } from 'node:readline';
import { execSync } from 'node:child_process';
import { join } from 'node:path';

// The Salesforce CLI bundles @salesforce/core. Find it where the CLI is
// installed, not where one laptop happened to keep it. SF_CLI_MODULES
// overrides the lookup when the CLI lives somewhere unusual.
const SF_CLI_MODULES = process.env.SF_CLI_MODULES
  || join(execSync('npm root -g', { encoding: 'utf8' }).trim(),
          '@salesforce', 'cli', 'node_modules', '@salesforce');
const { Org } = await import(join(SF_CLI_MODULES, 'core', 'lib', 'index.js'));

const ALIAS = process.env.SF_ORG_ALIAS || 'curbcut';
const PROTOCOL = '2024-11-05';

const org = await Org.create({ aliasOrUsername: ALIAS });
const conn = org.getConnection();

const FORBIDDEN = /diagnos|condition|disabilit|medical|severity|prognos/i;

const TOOLS = [
  {
    name: 'curbcut_find_options',
    description:
      'Given what a person says is HARD at work, in their own words, return workplace ' +
      'adjustments they could ask for, with what each typically costs and a source. ' +
      'Describe the difficulty functionally ("cannot type for long", "misses things in ' +
      'meetings"). Never send a diagnosis, condition or medical detail: there is nowhere ' +
      'to store one and the call will be refused. Returns nothing rather than guessing ' +
      'when there is no good match.',
    inputSchema: {
      type: 'object',
      properties: {
        need: { type: 'string', description: 'What is hard, functionally, in the person\'s own words.' },
        limit: { type: 'integer', description: 'Maximum options to return. Default 4.' },
      },
      required: ['need'],
    },
  },
  {
    name: 'curbcut_cost_brief',
    description:
      'Published evidence on what workplace accommodations actually cost employers, ' +
      'with the survey, the sample and the denominator. Use this when someone believes ' +
      'asking will be expensive or burdensome, which is the most common reason people ' +
      'do not ask.',
    inputSchema: { type: 'object', properties: {} },
  },
  {
    name: 'curbcut_draft_request',
    description:
      'Draft an accommodation request in the person\'s own words, describing what would ' +
      'help and never why they need it. Returns text for the PERSON to read and decide ' +
      'about. This does not send anything and cannot: nothing reaches an employer ' +
      'without that person saying yes themselves, in a conversation they are present for.',
    inputSchema: {
      type: 'object',
      properties: {
        need:   { type: 'string', description: 'What is hard, functionally.' },
        option: { type: 'string', description: 'The adjustment being asked for.' },
      },
      required: ['need'],
    },
  },
  {
    name: 'curbcut_reach_human',
    description:
      'Hand this person to a real human being, on the channel they are already using. ' +
      'Use it the moment somebody asks for a person, or when you have misunderstood ' +
      'them twice - do not make them ask three times. This creates a real handoff to a ' +
      'named handler and returns a code they keep; it never routes anyone to a phone ' +
      'call, because for some of the people this serves a phone call is a door that ' +
      'does not open. Send only what they said was hard, never why.',
    inputSchema: {
      type: 'object',
      properties: {
        context: {
          type: 'string',
          description:
            'What they said was hard, in their words, so they never have to explain it ' +
            'twice. Never a diagnosis or condition.',
        },
      },
      required: ['context'],
    },
  },
];

async function apex(path, method = 'GET', body) {
  return conn.request({
    method,
    url: `/services/apexrest${path}`,
    body: body === undefined ? undefined : JSON.stringify(body),
    headers: { 'Content-Type': 'application/json' },
  });
}

/** The library lookup runs in the org, so the MCP surface and the phone get
 *  identical answers from identical code. Two rankers would drift. */
async function findOptions(need, limit) {
  const soql =
    `SELECT Option__c, Plain_Language_Summary__c, Typical_Cost__c, Zero_Cost__c, ` +
    `Precedent_Count__c, Source_URL__c FROM Accommodation_Option__c LIMIT 500`;
  const res = await conn.query(soql);
  const STOP = new Set(['the','a','an','and','or','but','i','im','my','me','to','for','of','in','on',
    'at','it','is','am','are','was','were','be','been','with','that','this','have','has','had','do',
    'does','did','can','cant','cannot','not','no','when','what','very','really','just','so','too',
    'get','got','because','they','them','after','before','while','during','than','then','rather',
    'into','from','out','own','one','some','all','any','each','more','less','most','much','also',
    'still','about','over','under','without','you','your','their','there','here','keep','keeps',
    'keeping','need','needs','needed','make','makes','made','thing','things','right','now','way',
    'ways','use','uses','using','used','like','lot','bit','day','days','time','times','work',
    'works','working','job']);
  const stem = (w) => {
    if (w.length < 4) return w;
    if (/(ses|xes|zes)$/.test(w)) w = w.slice(0, -2);
    else if (/s$/.test(w) && !/ss$/.test(w)) w = w.slice(0, -1);
    if (w.length >= 5 && w.endsWith('ing')) w = w.slice(0, -3);
    else if (w.length >= 4 && w.endsWith('ed')) w = w.slice(0, -2);
    if (w.length >= 4 && w.endsWith('e')) w = w.slice(0, -1);
    return w;
  };
  const words = (t) => new Set((t || '').toLowerCase().split(/[^a-z0-9]+/)
    .filter(w => w.length >= 3).map(stem).filter(w => w.length >= 3));
  const keys = new Set([...words(need)].filter(w => ![...STOP].map(stem).includes(w)));
  const raw  = (need || '').toLowerCase().split(/[^a-z]+/).filter(w => !STOP.has(w));
  const keywords = new Set(raw.filter(w => w.length >= 3).map(stem).filter(w => w.length >= 3));

  const scored = [];
  for (const o of res.records) {
    const title = words(o.Option__c), body = words(o.Plain_Language_Summary__c);
    let score = 0;
    for (const k of keywords) { if (title.has(k)) score += 3; else if (body.has(k)) score += 1; }
    if (score > 0) scored.push({ o, score });
  }
  scored.sort((a, b) => b.score - a.score ||
    (b.o.Precedent_Count__c || 0) - (a.o.Precedent_Count__c || 0) ||
    String(a.o.Option__c).localeCompare(String(b.o.Option__c)));
  // Cost and precedent are stated only when actually known, and the guards
  // matter more here than anywhere. A placeholder zero in the library once made
  // this answer "typically about $0, once" for a booked ASL interpreter. Somebody
  // could repeat that to their employer and lose the argument, and their footing,
  // on a number we invented. Silence is the correct answer to a fact we lack.
  return scored.slice(0, limit || 4).map(({ o }) => {
    const row = {
      option: o.Option__c,
      what_it_is: o.Plain_Language_Summary__c,
      source: o.Source_URL__c,
    };
    if (o.Zero_Cost__c) row.cost = 'typically costs the employer nothing';
    else if (o.Typical_Cost__c > 0) row.cost = `typically about $${Math.round(o.Typical_Cost__c)}, once`;
    else row.cost = 'no published figure; do not state one';
    if (o.Precedent_Count__c > 0) row.workplaces_known_to_have_done_it = o.Precedent_Count__c;
    return row;
  });
}

const COST_BRIEF = {
  headline: 'Most accommodations cost the employer nothing.',
  survey: 'Job Accommodation Network, employers contacted 1 January 2019 to 31 December 2024',
  employers_surveyed: 26028,
  employers_responded: 5406,
  gave_cost_figures: 1425,
  of_those_no_cost_percent: 61,
  one_time_cost_percent: 33,
  one_time_median_usd: 300,
  ongoing_cost_percent: 6,
  ongoing_median_usd_per_year: 2400,
  very_or_extremely_effective_percent: 66,
  ineffective_percent: 12,
  caveat:
    'The 61% is of the 1,425 employers who gave cost figures, not of all respondents. ' +
    'Everyone surveyed had already contacted JAN for guidance, so they are employers ' +
    'already trying. This describes employers in general and says nothing about any ' +
    'particular employer.',
  source: 'https://askjan.org/topics/costs.cfm',
};

function draft(need, option) {
  return [
    'I am asking for a change to how I work.',
    '',
    `What is hard right now: ${need}`,
    option ? `\nWhat would help: ${option}` : '',
    '',
    'I am not sharing a diagnosis, and I am not required to. This is about what I ' +
    'need to do my job.',
  ].filter(l => l !== null).join('\n');
}

async function callTool(name, args) {
  if (name === 'curbcut_reach_human') {
    const ctx = String(args.context ?? '');
    if (FORBIDDEN.test(ctx)) {
      return { refused: true, reason:
        'That reads like a diagnosis or condition. There is nowhere in this system ' +
        'to put one, and a handoff does not need it. Send what they said was hard.' };
    }
  }
  if (name === 'curbcut_find_options' || name === 'curbcut_draft_request') {
    const need = String(args?.need ?? '');
    if (FORBIDDEN.test(need)) {
      return {
        refused: true,
        reason:
          'That reads as medical information. Curb Cut has no field for a diagnosis, ' +
          'condition, disability type, severity or prognosis anywhere in the system, so ' +
          'there is nothing to store it in and nothing was stored. Describe what is ' +
          'functionally hard instead, and you will get the same answer without anyone ' +
          'ever knowing why.',
      };
    }
    if (!need.trim()) return { refused: true, reason: 'Say what is hard, in the person\'s own words.' };
  }

  switch (name) {
    case 'curbcut_find_options': {
      const options = await findOptions(args.need, args.limit);
      return options.length
        ? { options, note: 'Knowing is allowed and asking is optional. Nothing has been sent to anyone.' }
        : { options: [], note:
            'No good match in the sourced library. Saying so is deliberate: this returns ' +
            'nothing rather than improvising, because a confident wrong suggestion costs ' +
            'someone their one ask.' };
    }
    case 'curbcut_cost_brief':
      return COST_BRIEF;
    case 'curbcut_draft_request':
      return {
        draft: draft(args.need, args.option),
        sent: false,
        note:
          'This has not been sent and cannot be sent from here. Give it to the person to ' +
          'read. If they want it to go, they send it themselves at ' +
          'https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/ask or by texting ' +
          '+1 276 495 9311. A hedge is not a yes.',
      };
    case 'curbcut_reach_human': {
      /* Routed through the same Apex door as SMS, Slack and email, so an
         assistant handing somebody over gets exactly the handoff a text message
         would have created - not a polite sentence with nothing behind it. That
         was the bug: every channel advertised a way out and none of them
         routed it. */
      const answer = await apex('/curbcut/v1/message/', 'POST', {
        channel: 'External', text: 'human', handle: null,
      });
      return {
        handedOff: Boolean(answer?.handedOff),
        handler: answer?.handlerName ?? null,
        note: answer?.message ??
          'I could not reach a person just now, and will not pretend otherwise. ' +
          'Tell them to write to parth.sevak2@gmail.com.',
      };
    }
    default:
      throw new Error(`no such tool: ${name}`);
  }
}

// ---- JSON-RPC over stdio -------------------------------------------------
function send(msg) {
  const body = JSON.stringify(msg);
  process.stdout.write(`Content-Length: ${Buffer.byteLength(body, 'utf8')}\r\n\r\n${body}`);
}

async function handle(req) {
  const { id, method, params } = req;
  try {
    if (method === 'initialize') {
      return send({ jsonrpc: '2.0', id, result: {
        protocolVersion: PROTOCOL,
        capabilities: { tools: {} },
        serverInfo: { name: 'curb-cut', version: '1.0.0' },
        instructions:
          'Curb Cut helps a person find out what workplace adjustments they could ask ' +
          'for, and draft the ask, without ever disclosing a medical condition. Never ' +
          'pass a diagnosis to these tools. Nothing here can send anything to an ' +
          'employer; only the person can do that, themselves.',
      }});
    }
    if (method === 'tools/list') return send({ jsonrpc: '2.0', id, result: { tools: TOOLS } });
    if (method === 'tools/call') {
      const out = await callTool(params?.name, params?.arguments ?? {});
      return send({ jsonrpc: '2.0', id, result: {
        content: [{ type: 'text', text: JSON.stringify(out, null, 2) }],
        isError: !!out.refused,
      }});
    }
    if (method === 'ping') return send({ jsonrpc: '2.0', id, result: {} });
    if (method?.startsWith('notifications/')) return;      // no reply expected
    send({ jsonrpc: '2.0', id, error: { code: -32601, message: `unknown method ${method}` } });
  } catch (e) {
    send({ jsonrpc: '2.0', id, error: { code: -32603, message: e?.message ?? 'internal error' } });
  }
}

// Content-Length framing, and bare newline-delimited JSON as a fallback so the
// server can be driven from a shell for testing.
let buf = '';
process.stdin.on('data', (chunk) => {
  buf += chunk.toString('utf8');
  for (;;) {
    const m = /Content-Length:\s*(\d+)\r?\n\r?\n/i.exec(buf);
    if (m) {
      const start = m.index + m[0].length, len = Number(m[1]);
      if (buf.length < start + len) return;
      const body = buf.slice(start, start + len);
      buf = buf.slice(start + len);
      handle(JSON.parse(body));
      continue;
    }
    const nl = buf.indexOf('\n');
    if (nl === -1) return;
    const line = buf.slice(0, nl).trim();
    buf = buf.slice(nl + 1);
    if (line) handle(JSON.parse(line));
  }
});

process.stderr.write(`curb-cut MCP server ready (org ${ALIAS}, ${TOOLS.length} tools)\n`);
