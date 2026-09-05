/* Caption cards in the same language as the hero image: cool institutional
   grey for the world as it is, warm green for the way out. No stock imagery,
   no gradients, no drop shadows. Type and rules only. */
import { writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';

const W=1920, H=1080;
const GROUND='#F2F3F4', DARK='#1B1E22', INK='#16181A', PAPER='#F7F5EF',
      GREEN='#1C5245', GOLD='#8A6115', GOLDLT='#D9B25F', SOFT='#42474C',
      DIM='#A9B0B6', RED='#A32B22', LINE='#C6CACE';
const esc = s => s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');

function card({kicker, lines, sub, foot, dark, accent, big}) {
  const bg = dark ? DARK : GROUND;
  const fg = dark ? PAPER : INK;
  const subc = dark ? DIM : SOFT;
  const acc = accent || (dark ? GOLDLT : GREEN);
  let y = 486 - (lines.length-1)*52;
  const size = big || (lines.length > 2 ? 74 : 88);
  let out = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">
  <rect width="${W}" height="${H}" fill="${bg}"/>`;
  if (kicker) out += `\n  <text x="150" y="205" font-family="Helvetica, Arial, sans-serif" font-size="24" letter-spacing="4.5" fill="${acc}">${esc(kicker)}</text>
  <line x1="150" y1="240" x2="1770" y2="240" stroke="${dark?'#3A4048':LINE}" stroke-width="1"/>`;
  lines.forEach((l,i)=>{
    const c = (typeof l === 'object') ? (l.c||fg) : fg;
    const t = (typeof l === 'object') ? l.t : l;
    out += `\n  <text x="150" y="${y + i*(size+22)}" font-family="Georgia, 'Times New Roman', serif" font-size="${size}" font-weight="bold" fill="${c}">${esc(t)}</text>`;
  });
  const afterY = y + (lines.length-1)*(size+22);
  if (sub) sub.forEach((s,i)=>{
    out += `\n  <text x="150" y="${afterY + 92 + i*44}" font-family="Helvetica, Arial, sans-serif" font-size="31" fill="${subc}">${esc(s)}</text>`;
  });
  if (foot) {
    out += `\n  <line x1="150" y1="930" x2="1770" y2="930" stroke="${dark?'#3A4048':LINE}" stroke-width="1"/>
  <text x="150" y="985" font-family="Helvetica, Arial, sans-serif" font-size="27" fill="${acc}">${esc(foot)}</text>`;
  }
  return out + '\n</svg>\n';
}

const CARDS = [
 ['c01', {dark:true, kicker:'AGENTFORCE FOR GOOD  ·  DREAMFORCE 2026  ·  ABILITYFORCE',
   lines:['Curb Cut'], big:150,
   sub:['Accommodation without disclosure.'],
   foot:'Asking for help was the hard part. So we made the asking easy.'}],

 ['c02', {dark:true, lines:['You\u2019ve done this yourself.'], big:82,
   sub:['Think of the last time something at work was quietly hard.',
        'The chair. The light. A meeting at the wrong hour for your body.',
        'You worked out what it would cost to ask, and you said nothing.'],
   foot:'Now make it permanent, and make it about your body.'}],

 ['c03', {kicker:'THE USUAL WAY', accent:RED,
   lines:['To get a chair that doesn\u2019t hurt,','first tell them what\u2019s wrong with you.'], big:64,
   sub:['Nature of your disability, required.','A letter from a doctor, required. And that\u2019s page one of three.'],
   foot:'One in four adults has a disability. Three in a hundred tell their employer.'}],

 ['c04', {kicker:'THE WHOLE FORM',
   lines:['You say what\u2019s hard.','You never have to say why.'],
   sub:['No name, no login, and no diagnosis, because there\u2019s nowhere to put one.'],
   foot:'Nothing is written down while you\u2019re anonymous.'}],

 ['c05', {kicker:'GROUNDED, NOT GENERATED',
   lines:['It cannot invent an option,','a cost, or a precedent.'], big:64,
   sub:['Twenty-eight rows. Every one carries the source it came from.',
        'If nothing fits, it says so rather than guessing.'],
   foot:'A confident wrong suggestion costs somebody their one ask.'}],

 ['c06', {kicker:'THE GATE', accent:GOLD,
   lines:['Nothing is sent until she says yes.'], big:70,
   sub:['\u201cI guess so, I think that\u2019s probably fine?\u201d isn\u2019t a yes.',
        'The code refuses it, and a second rule refuses it again.'],
   foot:'Two separate locks, because one on its own is a bug away from silent.'}],

 ['c07', {dark:true, kicker:'SIX DOORS, ONE CONTRACT',
   lines:['Web. Voice. Text. Email.','Slack. Any AI assistant.'], big:64,
   sub:['One router behind all of them, so OFF can\u2019t mean one thing on a phone',
        'and something else in an inbox.'],
   foot:'Two of them work on a basic phone, with no internet at all.'}],

 ['c08', {kicker:'WHAT IS NOT HERE',
   lines:['There\u2019s no field','for a diagnosis.'],
   sub:['It isn\u2019t encrypted or hidden behind a permission. It simply isn\u2019t there.',
        'Encryption keeps outsiders out. Here, the risk is the employer.'],
   foot:'A field that was never created can\u2019t be leaked.'}],

 ['c09', {kicker:'WHAT TWO AUDITS FOUND', accent:RED,
   lines:['We say what the tools','couldn\u2019t decide.'], big:64,
   sub:['Salesforce Sa11y: 131 checks, 0 WCAG violations, 2 real defects fixed.',
        'Responsible AI: 21 checks against Salesforce’s own five guidelines.'],
   foot:'We don\u2019t count an undecided check as a pass.'}],

 ['c10', {dark:true, kicker:'THE OFFER',
   lines:['Free for the first ten.'], big:82,
   sub:['Name one owner. Answer in five working days.',
        'Publish what you said yes to. Let a disabled employee test it first.'],
   foot:'Sixty-one in a hundred cost nothing. After that, nobody can say it was the money.'}],

 ['c11', {dark:true, lines:['They only have to be','able to ask.'], big:88,
   sub:['curbcut  ·  built on Agentforce  ·  every figure verifiable against a live org'],
   foot:'The captions are in the film and the words are in the script, because not everyone can hear this.'}],
];

for (const [name, spec] of CARDS) {
  writeFileSync(`cards/${name}.svg`, card(spec));
}
console.log('svgs:', CARDS.length);
for (const [name] of CARDS) {
  execFileSync('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    ['--headless','--disable-gpu','--no-sandbox','--hide-scrollbars',
     `--screenshot=cards/${name}.png`,`--window-size=${W},${H}`,
     `file://${process.cwd()}/cards/${name}.svg`], {stdio:'ignore'});
}
console.log('pngs rendered');
