/* A mockup SVG carries its own width and height, so Chrome draws it at that
   size in the corner of the window instead of filling the frame. Inline it with
   those attributes stripped and let CSS size it to the viewport. */
import { readFileSync, writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';

const M='/Users/drashtipathak/Downloads/curbcut_check/submission/devpost/mockups';
const CH='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const W=1920, H=1080, PAD=70;

for (const [file,out] of [['07-console-refusal.svg','frames/20-console-refusal.png'],
                          ['08-signed-video-no-captions.svg','frames/21-signed-video.png']]) {
  let svg = readFileSync(`${M}/${file}`,'utf8')
    .replace(/\swidth="\d+"/,'').replace(/\sheight="\d+"/,'');
  const html = `<!doctype html><meta charset="utf-8">
<style>html,body{margin:0;height:100%;background:#F2F3F4}
body{display:flex;align-items:center;justify-content:center}
svg{width:${W-PAD*2}px;height:auto;max-height:${H-PAD*2-60}px}
.tag{position:absolute;left:0;right:0;bottom:0;height:54px;background:#16181A;color:#F7F5EF;font:500 20px Helvetica,Arial,sans-serif;display:flex;align-items:center;justify-content:center;letter-spacing:.3px}</style>${svg}
<div class="tag">Illustration of the operator console, drawn from the deployed org. Every sentence on it is what the system said.</div>`;
  writeFileSync('tmp.html', html);
  execFileSync(CH,['--headless','--disable-gpu','--no-sandbox','--hide-scrollbars',
    `--screenshot=${out}`,`--window-size=${W},${H}`,'--force-device-scale-factor=1',
    `file://${process.cwd()}/tmp.html`],{stdio:'ignore'});
  console.log('rendered', out);
}
