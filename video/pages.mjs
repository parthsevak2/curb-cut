import { launch } from './cdp.mjs';
const BASE='https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut';
const b=await launch(); const wait=ms=>new Promise(r=>setTimeout(r,ms));
for (const [path,name] of [['','10-home'],['/why','11-why'],['/privacy','12-privacy'],['/messaging','13-messaging']]) {
  await b.goto(BASE+path); await wait(900);
  await b.shot(`frames/${name}.png`);
  const h1 = await b.js('document.querySelector("h1")?.textContent.trim().slice(0,70)');
  console.log(name, '::', h1);
}
// a phone, because two of the six doors are a phone
await b.send('Emulation.setDeviceMetricsOverride',{width:390,height:844,deviceScaleFactor:3,mobile:true});
await b.goto(BASE+'/ask'); await wait(1200);
await b.shot('frames/14-mobile-ask.png');
await b.js(`[...document.querySelectorAll('button')].find(e=>/back hurts/i.test(e.textContent))?.click()`);
await wait(700);
await b.shot('frames/15-mobile-said.png');
console.log('mobile captured');
await b.close();
