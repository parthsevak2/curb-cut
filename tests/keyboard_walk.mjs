/* Walk the live page with real Tab presses and read what the focus ring
   actually computes to. :focus-visible does not match a programmatic .focus(),
   which is how a previous audit talked itself into 26 defects that were not
   there. So these are dispatched key events, not scripted focus calls. */
import { launch } from '../video/cdp.mjs';
const BASE='https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut';
const b=await launch(); const wait=ms=>new Promise(r=>setTimeout(r,ms));

const tab = async (shift=false) => {
  for (const type of ['rawKeyDown','keyUp'])
    await b.send('Input.dispatchKeyEvent',{type,key:'Tab',code:'Tab',
      windowsVirtualKeyCode:9,nativeVirtualKeyCode:9,modifiers:shift?8:0});
  await wait(70);
};
const focused = () => b.js(`
  (()=>{const e=document.activeElement;
    if(!e||e===document.body) return null;
    const cs=getComputedStyle(e), r=e.getBoundingClientRect();
    return {tag:e.tagName.toLowerCase(),
      label:(e.getAttribute('aria-label')||e.textContent||e.value||'').trim().slice(0,44),
      outline:cs.outlineStyle+' '+cs.outlineWidth+' '+cs.outlineColor,
      shadow:(cs.boxShadow||'none').slice(0,60),
      w:Math.round(r.width), h:Math.round(r.height), vis:r.width>0&&r.height>0};})()`);

for (const path of ['/ask','']) {
  await b.goto(BASE+path); await wait(1200);
  await b.js('document.body.focus()');
  const seen=[]; const noRing=[]; const small=[];
  for (let i=0;i<45;i++){
    await tab();
    const f=await focused();
    if(!f) continue;
    const key=f.tag+':'+f.label;
    if(seen.includes(key)) break;
    seen.push(key);
    const hasRing = !/none/.test(f.outline.split(' ')[0]) || !/^none/.test(f.shadow);
    if(!hasRing) noRing.push(f.label||f.tag);
    // WCAG 2.5.8 wants 24 by 24 for a control that is not inline in text
    if(f.vis && (f.w<24||f.h<24)) small.push(`${f.label||f.tag} ${f.w}x${f.h}`);
  }
  console.log(`\n${path||'/'}  reached ${seen.length} controls by keyboard`);
  console.log('  no focus indicator :', noRing.length? noRing.join(', ') : 'none');
  console.log('  under 24x24        :', small.length? small.join(', ') : 'none');
  const sample=await b.js(`(()=>{const e=document.querySelector('button');if(!e)return'';
    e.focus();const c=getComputedStyle(e);return c.outlineStyle+' '+c.outlineWidth+' '+c.outlineColor;})()`);
  console.log('  ring on first button:', sample);
}
await b.close();
