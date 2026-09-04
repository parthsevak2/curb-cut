import { launch } from './cdp.mjs';
const BASE='https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut';
const b=await launch(); const wait=ms=>new Promise(r=>setTimeout(r,ms));
const click = t => b.js(`(()=>{const e=[...document.querySelectorAll('button,a')].find(x=>new RegExp(${JSON.stringify(t)},'i').test(x.textContent||'')&&x.offsetParent);if(!e)return 'MISS';e.click();return 'ok';})()`);
const waitFor = async (sel, minLen=80, tries=14) => {
  for(let i=0;i<tries;i++){ await wait(1200);
    const n = await b.js(`(()=>{const e=document.querySelector(${JSON.stringify(sel)});return e&&e.offsetParent?e.innerText.replace(/\\s+/g,' ').length:0;})()`);
    if(n>=minLen) return n;
  } return 0;
};
const focus = sel => b.js(`(()=>{const e=document.querySelector(${JSON.stringify(sel)});if(!e)return 0;
  const y=e.getBoundingClientRect().top+scrollY-90; scrollTo(0,Math.max(0,y)); return Math.round(y);})()`);

await b.goto(BASE+'/ask');
await b.shot('frames/01-ask-empty.png');

await click('back hurts by the afternoon'); await wait(700);
await focus('textarea'); await wait(300);
await b.shot('frames/02-said.png');

await click('Show me what I could ask for');
console.log('options chars:', await waitFor('#optionsBox', 120));
await focus('#results'); await wait(500);
await b.shot('frames/03-options.png');
console.log('OPTIONS TEXT:', (await b.js(`document.querySelector('#optionsBox').innerText.replace(/\\s+/g,' ').slice(0,420)`)));

await click('Help me ask for one of these');
console.log('draft chars:', await waitFor('#draftBox', 120));
await focus('#draftSection'); await wait(500);
await b.shot('frames/04-draft.png');
console.log('DRAFT TEXT:', (await b.js(`document.querySelector('#draftBox').innerText.replace(/\\s+/g,' ').slice(0,420)`)));

await click('Yes, send this');
console.log('done chars:', await waitFor('#doneBox', 40));
await focus('#doneSection'); await wait(600);
await b.shot('frames/05-sent.png');
console.log('DONE TEXT:', (await b.js(`document.querySelector('#doneBox')?.innerText.replace(/\\s+/g,' ').slice(0,320)`)));
await b.close();
