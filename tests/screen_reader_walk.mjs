/* What a screen reader is handed at each step of /ask, as a transcript.
   This is not a person using a screen reader, and the document it writes says
   so in its first line. It reads the same accessibility tree NVDA, JAWS and
   VoiceOver read, walks the flow with real key and click events, and records,
   after every step, where focus landed (its role and accessible name), what the
   live regions announced, and the reading order of everything new on screen. */
import { launch } from '../video/cdp.mjs';
import { writeFileSync } from 'node:fs';

const SITE = process.env.CURB_CUT_SITE || 'https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut';
const b = await launch();
const out = [];
const say = (s) => out.push(s);
const role = n => n.role?.value || '';
const name = n => (n.name?.value || '').trim();
const desc = n => (n.description?.value || '').trim();

async function tree() {
  const { nodes } = await b.send('Accessibility.getFullAXTree');
  return nodes.filter(n => !n.ignored && role(n) && !['none','generic','InlineTextBox','StaticText','LineBreak','RootWebArea'].includes(role(n)));
}
async function snapshot(label) {
  const focus = await b.js(`(() => { const e = document.activeElement; if (!e || e === document.body) return 'body'; const n = e.getAttribute('aria-label') || e.getAttribute('aria-labelledby') && document.getElementById(e.getAttribute('aria-labelledby'))?.textContent || e.textContent || e.value || ''; return e.tagName.toLowerCase() + (e.id ? '#' + e.id : '') + ' "' + n.trim().replace(/\\s+/g,' ').slice(0,90) + '"'; })()`);
  const live = await b.js(`[...document.querySelectorAll('[role=status],[aria-live]')].map(e => e.textContent.trim().replace(/\\s+/g,' ')).filter(Boolean)`);
  say(`\n### ${label}\n`);
  say(`- Focus is on: ${focus}`);
  say(`- Live regions announce: ${live.length ? live.map(t => `"${t}"`).join('; ') : 'nothing new'}`);
}
async function readingOrder(label, limit = 60) {
  const nodes = await tree();
  say(`\nReading order, ${label} (${Math.min(limit, nodes.length)} of ${nodes.length} nodes):\n`);
  for (const n of nodes.slice(0, limit)) {
    const bits = [role(n), name(n) ? `"${name(n)}"` : '(no name)'];
    const lvl = (n.properties || []).find(p => p.name === 'level')?.value?.value;
    if (lvl) bits.push(`level ${lvl}`);
    if (desc(n)) bits.push(`described as "${desc(n).slice(0, 80)}"`);
    say(`- ${bits.join(' ')}`);
  }
}

say('# What a screen reader is handed on /ask, step by step');
say('');
say('This transcript was produced by a script, not by a person who uses a screen reader. It reads the same accessibility tree that NVDA, JAWS and VoiceOver read, drives the page with real key and click events, and records what a screen reader would be given at each step: where focus lands, what the live regions announce, and the order things are read. It cannot tell you what it is like to use. One session with a daily screen-reader user still comes before the next five features.');
say('');
say(`Page: ${SITE}/ask. Generated ${new Date().toISOString().slice(0, 16).replace('T', ' ')} UTC.`);

await b.goto(`${SITE}/ask`);
await b.js(`new Promise(r => setTimeout(r, 1500))`);
await snapshot('Step 0: the page loads');
await readingOrder('on load', 45);

// Tab from the top: the first three stops a keyboard user meets.
const stops = [];
for (let i = 0; i < 6; i++) {
  await b.send('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Tab', code: 'Tab', windowsVirtualKeyCode: 9 });
  await b.send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Tab', code: 'Tab', windowsVirtualKeyCode: 9 });
  stops.push(await b.js(`(() => { const e = document.activeElement; return e.tagName.toLowerCase() + (e.id ? '#' + e.id : '') + ' "' + (e.getAttribute('aria-label') || e.textContent || e.value || '').trim().replace(/\\s+/g,' ').slice(0,70) + '"'; })()`));
}
say('\n### Step 1: six presses of Tab from the top\n');
stops.forEach((s, i) => say(`${i + 1}. ${s}`));

// Type a need and submit with Enter, the way a keyboard user would.
await b.js(`(() => { const t = document.querySelector('textarea'); t.focus(); t.value = 'The office lights give me a headache by lunch and I stop being able to think.'; t.dispatchEvent(new Event('input', {bubbles:true})); })()`);
await b.js(`(() => { const f = document.getElementById('askForm'); if (f) f.requestSubmit(); })()`);
await b.js(`new Promise(r => setTimeout(r, 9000))`);
await snapshot('Step 2: after typing what is hard and pressing Enter');
await readingOrder('the options that arrived', 30);

const draftBtn = await b.js(`(() => { const b = [...document.querySelectorAll('button')].find(x => /help me ask/i.test(x.textContent)); if (b) { b.click(); return b.textContent.trim(); } return null; })()`);
if (draftBtn) {
  await b.js(`new Promise(r => setTimeout(r, 9000))`);
  await snapshot(`Step 3: after pressing "${draftBtn}"`);
  await readingOrder('the draft', 25);
} else say('\n### Step 3: no draft button was found (the options step may have returned nothing)');

say('\n### What this transcript can and cannot tell you\n');
say('- It can show that every control has a name, that focus moves to the new heading after each step, and that the status line announces what happened.');
say('- It cannot show whether the wording is clear when heard rather than read, whether the pace is right, or what a person would do when confused. Only a person can.');
writeFileSync('docs/SCREEN-READER-WALK.md', out.join('\n') + '\n');
console.log('wrote docs/SCREEN-READER-WALK.md,', out.length, 'lines');
b.proc.kill();
