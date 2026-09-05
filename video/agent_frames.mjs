#!/usr/bin/env node
/* Turn a saved take into film frames: one frame per turn, the conversation
   accumulating, in the site's own visual language. The words are the take's
   words, unedited; the header says which agent, when, and that it is a live
   transcript. Usage: node agent_frames.mjs <take.json> <outdir> */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { join, basename } from 'node:path';

const [,, takePath, outDir = 'frames'] = process.argv;
const take = JSON.parse(readFileSync(takePath, 'utf8'));
mkdirSync(outDir, { recursive: true });
const CH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\n/g, '<br>');
const when = new Date(take.when).toLocaleString('en-CA', { dateStyle: 'long', timeStyle: 'short' });

const page = (turns, upto) => `<!doctype html><meta charset="utf-8"><style>
html,body{margin:0;width:1920px;height:1080px;background:#F2F3F4;font-family:Helvetica,Arial,sans-serif;overflow:hidden}
.head{height:88px;display:flex;align-items:center;justify-content:space-between;padding:0 110px;border-bottom:1px solid #C6CACE;background:#FFFFFF}
.head .n{font-size:22px;font-weight:700;color:#16181A}
.head .n span{display:inline-block;width:34px;height:10px;background:#8A6115;margin-right:14px;vertical-align:middle;clip-path:polygon(0 100%,60% 100%,100% 0,100% 100%)}
.head .m{font-size:17px;letter-spacing:2.2px;color:#5A6068}
.chat{padding:44px 110px 0;display:flex;flex-direction:column;gap:26px;height:900px;box-sizing:border-box;overflow:hidden}
.row{display:flex;gap:22px;align-items:flex-start}
.who{flex:0 0 150px;font-size:15px;letter-spacing:2.4px;color:#5A6068;padding-top:20px}
.b{max-width:1240px;padding:22px 30px;font-size:29px;line-height:1.42;border-radius:6px}
.said{background:#16181A;color:#F7F5EF}
.reply{background:#FFFFFF;color:#16181A;border:1.5px solid #C6CACE}
.reply.gate{border-color:#A32B22;border-width:2.5px}
.reply.sent{border-color:#1C5245;border-width:2.5px}
/* the previous exchange, one line each, so the eye knows where it is without
   the frame having to hold the whole conversation */
.prev .who{padding-top:6px;opacity:.55}
.prev .b{font-size:20px;line-height:1.3;padding:8px 16px;opacity:.5;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:1240px}
.foot{position:absolute;left:110px;right:110px;bottom:40px;font-size:18px;color:#5A6068;display:flex;justify-content:space-between;background:#F2F3F4;padding-top:10px}
</style>
<div class="head"><div class="n"><span></span>Curb Cut</div><div class="m">AGENTFORCE AGENT ${esc(take.agent.toUpperCase())}  ·  LIVE TRANSCRIPT  ·  ${esc(when.toUpperCase())}</div></div>
<div class="chat">${(() => {
  const t = turns[upto], p = upto > 0 ? turns[upto - 1] : null;
  const cls = /want to be sure/i.test(t.reply) ? 'gate' : /was sent|hear back/i.test(t.reply) ? 'sent' : '';
  const one = s => esc(s.replace(/\s+/g, ' ').trim());
  const prev = p ? `<div class="row prev"><div class="who">THEY SAID</div><div class="b said">${one(p.said)}</div></div>
<div class="row prev"><div class="who">THE AGENT</div><div class="b reply">${one(p.reply)}</div></div>` : '';
  return prev + `<div class="row"><div class="who">THEY SAID</div><div class="b said">${esc(t.said)}</div></div>
<div class="row"><div class="who">THE AGENT</div><div class="b reply ${cls}">${esc(t.reply)}</div></div>`;
})()}</div>
<div class="foot"><div>Nothing in this exchange was edited. The person's lines were fixed in advance; the replies are the live agent's.</div><div>${esc(take.take)} · reply in ${turns[upto].ms} ms</div></div>`;

const stem = basename(takePath).replace(/\.json$/, '');
take.turns.forEach((_, i) => {
  const html = join(outDir, `${stem}-${i + 1}.html`);
  writeFileSync(html, page(take.turns, i));
  const png = join(outDir, `agent-${take.take}-${i + 1}.png`);
  execFileSync(CH, ['--headless', '--disable-gpu', '--no-sandbox', '--hide-scrollbars',
    `--screenshot=${png}`, '--window-size=1920,1080', '--force-device-scale-factor=1', `file://${process.cwd()}/${html}`], { stdio: 'ignore' });
  console.log(png);
});
