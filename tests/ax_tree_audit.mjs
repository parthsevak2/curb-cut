#!/usr/bin/env node
/* What a screen reader is actually given.
 *
 * No screen reader user has tested Curb Cut, and this does not change that. But
 * a screen reader does not read the HTML; it reads the accessibility tree the
 * browser builds from it. Chrome will hand that tree over, so this walks it for
 * the live pages and checks the things a person navigating by ear depends on:
 * that every control has a name, that the landmarks a person jumps between
 * exist and are distinct, that headings form a real outline, that live regions
 * exist for the things that change, and that nothing focusable is announced as
 * nothing. It is the closest a machine gets, and it says so.
 */
import { launch } from '../video/cdp.mjs';

const BASE = 'https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut';
const PAGES = ['/ask', '', '/why', '/privacy', '/docs'];
const b = await launch();
const wait = ms => new Promise(r => setTimeout(r, ms));

let fails = 0, checks = 0;
const check = (name, ok, detail = '') => { checks++; if (!ok) { fails++; console.log(`  FAIL  ${name}: ${detail}`); } };

for (const path of PAGES) {
  await b.goto(BASE + path); await wait(1200);
  await b.send('Accessibility.enable');
  const { nodes } = await b.send('Accessibility.getFullAXTree');
  const role = n => n.role?.value || '';
  const name = n => (n.name?.value || '').trim();
  const live = nodes.filter(n => !n.ignored);

  // 1. every control is announced as something
  const controls = live.filter(n => ['button', 'link', 'textbox', 'combobox', 'checkbox', 'radio'].includes(role(n)));
  const unnamed = controls.filter(n => !name(n));
  check(`${path || '/'} every-control-has-a-name`, unnamed.length === 0,
        `${unnamed.length} of ${controls.length} controls have no accessible name`);

  // 2. the landmarks a person jumps between, and each region distinct
  const landmarks = live.filter(n => ['banner', 'navigation', 'main', 'contentinfo', 'region', 'form'].includes(role(n)));
  const roles = new Set(landmarks.map(role));
  check(`${path || '/'} has-main-landmark`, roles.has('main'), 'no <main> for a screen reader to jump to');
  check(`${path || '/'} has-navigation-landmark`, roles.has('navigation'), 'no navigation landmark');
  const regions = landmarks.filter(n => role(n) === 'region');
  const anon = regions.filter(n => !name(n));
  check(`${path || '/'} every-region-is-named`, anon.length === 0,
        `${anon.length} of ${regions.length} regions would be announced as just "region"`);

  // 3. headings form an outline: one h1, no level skipped downward
  const heads = live.filter(n => role(n) === 'heading')
    .map(n => ({ lvl: Number((n.properties || []).find(p => p.name === 'level')?.value?.value || 0), t: name(n) }));
  check(`${path || '/'} one-h1`, heads.filter(h => h.lvl === 1).length === 1,
        `${heads.filter(h => h.lvl === 1).length} h1 headings`);
  let skipped = [];
  for (let i = 1; i < heads.length; i++) if (heads[i].lvl > heads[i - 1].lvl + 1) skipped.push(`${heads[i - 1].lvl}->${heads[i].lvl} at "${heads[i].t.slice(0, 30)}"`);
  check(`${path || '/'} no-heading-level-skipped`, skipped.length === 0, skipped.join('; '));

  // 4. things that change are announced. Not "do live regions exist", which
  //    counts empty ones and misses the point, but: after each step of the
  //    real flow, did focus land on the new section's heading, and did a live
  //    region carry a sentence a screen reader would read out. First written
  //    as a static count; it failed on a page that was doing this correctly.
  if (path === '/ask') {
    const click = t => b.js(`(()=>{const e=[...document.querySelectorAll('button')].find(x=>new RegExp(${JSON.stringify(t)},'i').test(x.textContent)&&x.offsetParent);if(!e)return false;e.click();return true;})()`);
    const settle = sel => (async () => { for (let i = 0; i < 14; i++) { await wait(500); if (await b.js(`!!document.querySelector(${JSON.stringify(sel)})?.innerText.trim()`)) return true; } return false; })();
    const announced = () => b.js(`(()=>{const a=document.activeElement;
      const onHeading=!!a&&/^H[1-6]$/.test(a.tagName);
      const said=[...document.querySelectorAll('[role=status],[role=alert],[aria-live]')].some(e=>e.offsetParent&&e.textContent.trim().length>20);
      return {onHeading,said,heading:a?a.textContent.trim().slice(0,40):''};})()`);
    await click('back hurts by the afternoon'); await wait(400);
    for (const [step, btn, sel] of [['results', 'Show me what I could ask for', '#optionsBox'],
                                    ['draft', 'Help me ask for one of these', '#draftBox'],
                                    ['sent', 'Yes, send this', '#doneBox']]) {
      const pressed = await click(btn); await settle(sel); await wait(400);
      const a = await announced();
      check(`/ask ${step}-moves-focus-to-its-heading`, pressed && a.onHeading, `focus is on ${a.heading || 'nothing'}`);
      check(`/ask ${step}-is-announced-by-a-live-region`, pressed && a.said, 'no live region carries the update');
    }
  }

  // 5. images carry a description or are marked decorative
  const imgs = live.filter(n => role(n) === 'image' || role(n) === 'img');
  const mute = imgs.filter(n => !name(n));
  check(`${path || '/'} images-are-described-or-hidden`, mute.length === 0, `${mute.length} images with no name and not hidden`);

  console.log(`${path || '/'}  nodes ${live.length}  controls ${controls.length}  landmarks ${landmarks.length}  headings ${heads.length}`);
}
await b.close();
console.log(`\n${checks - fails}/${checks} accessibility-tree checks pass`);
process.exit(fails ? 1 : 0);
