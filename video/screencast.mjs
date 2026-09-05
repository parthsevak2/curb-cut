/* A real recording of the real site: cursor moving, text appearing, sections
   opening. Page.startScreencast streams JPEG frames as the page changes; the
   flow is driven with mouse and keyboard events so what is recorded is what a
   person would see, not a sequence of stills. */
import { launch } from './cdp.mjs';
import { writeFileSync, mkdirSync } from 'node:fs';
const BASE = 'https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut';
const b = await launch(); const wait = ms => new Promise(r => setTimeout(r, ms));
mkdirSync('rec', { recursive: true });

let n = 0; const stamps = [];
b.ws.addEventListener('message', (m) => {
  const msg = JSON.parse(m.data);
  if (msg.method === 'Page.screencastFrame') {
    writeFileSync(`rec/f${String(n++).padStart(5, '0')}.jpg`, Buffer.from(msg.params.data, 'base64'));
    stamps.push(msg.params.metadata.timestamp);
    b.send('Page.screencastFrameAck', { sessionId: msg.params.sessionId }).catch(() => {});
  }
});

const rect = sel => b.js(`(()=>{const e=[...document.querySelectorAll('button,a,textarea')].find(x=>${sel});
  if(!e) return null; e.scrollIntoView({block:'center',behavior:'instant'}); const r=e.getBoundingClientRect();
  return {x:r.x+r.width/2,y:r.y+r.height/2};})()`);
const glide = async (to, steps = 28) => {
  const from = glide.last || { x: 800, y: 450 };
  for (let i = 1; i <= steps; i++) {
    const t = i / steps, e = 1 - Math.pow(1 - t, 3);
    await b.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: from.x + (to.x - from.x) * e, y: from.y + (to.y - from.y) * e });
    await wait(16);
  }
  glide.last = to;
};
const click = async (to) => {
  if (!to) throw new Error('target not found');
  await glide(to); await wait(180);
  await b.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: to.x, y: to.y, button: 'left', clickCount: 1 });
  await wait(70);
  await b.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: to.x, y: to.y, button: 'left', clickCount: 1 });
};
const typeText = async (s) => { for (const ch of s) { await b.send('Input.insertText', { text: ch }); await wait(55 + Math.random() * 60); } };
const settle = async (sel) => { for (let i = 0; i < 14; i++) { await wait(500); if (await b.js(`!!document.querySelector(${JSON.stringify(sel)})?.innerText.trim()`)) return true; } return false; };
const scrollTo = async (sel) => { await b.js(`document.querySelector(${JSON.stringify(sel)})?.scrollIntoView({block:'start',behavior:'smooth'})`); };

await b.goto(BASE + '/ask'); await wait(800);
await b.send('Page.startScreencast', { format: 'jpeg', quality: 85, maxWidth: 1600, maxHeight: 900, everyNthFrame: 1 });
await wait(1500);

// 1. read the page a moment, then move to the box and type in her own words
await click(await rect(`x.tagName==='TEXTAREA'`)); await wait(400);
await typeText('My back hurts by the afternoon'); await wait(1400);

// 2. ask what she could ask for
await click(await rect(`/Show me what I could ask for/i.test(x.textContent)`));
console.log('options:', await settle('#optionsBox'));
await wait(600); await scrollTo('#results'); await wait(1800);

// 3. help me ask
await click(await rect(`/Help me ask for one of these/i.test(x.textContent)`));
console.log('draft  :', await settle('#draftBox'));
await wait(600); await scrollTo('#draftSection'); await wait(2600);

// 4. the yes
await click(await rect(`/Yes, send this/i.test(x.textContent)`));
console.log('sent   :', await settle('#doneBox'));
await scrollTo('#doneSection'); await wait(2400);

await b.send('Page.stopScreencast'); await wait(300);
await b.close();
const dur = stamps.length > 1 ? stamps[stamps.length - 1] - stamps[0] : 0;
writeFileSync('rec/stamps.json', JSON.stringify(stamps));
console.log(`frames ${n}  span ${dur.toFixed(1)}s  ~${(n / Math.max(dur, 1)).toFixed(1)} fps`);
