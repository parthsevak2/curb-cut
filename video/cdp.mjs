/* A tiny Chrome DevTools Protocol driver.
   Node 22+ has a native WebSocket, so this needs no dependencies at all. */
import { spawn } from 'node:child_process';
import { writeFileSync } from 'node:fs';

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const PORT = 9333;
const W = 1600, H = 900;

export async function launch() {
  const proc = spawn(CHROME, [
    '--headless=new', `--remote-debugging-port=${PORT}`, '--no-first-run',
    '--no-default-browser-check', '--disable-gpu', '--hide-scrollbars',
    `--window-size=${W},${H}`, '--force-device-scale-factor=2',
    '--user-data-dir=/tmp/curbcut-cdp-profile', 'about:blank',
  ], { stdio: 'ignore' });

  let target = null;
  for (let i = 0; i < 60 && !target; i++) {
    await new Promise(r => setTimeout(r, 500));
    try {
      const r = await fetch(`http://127.0.0.1:${PORT}/json/list`);
      const list = await r.json();
      target = list.find(t => t.type === 'page');
    } catch { /* not up yet */ }
  }
  if (!target) { proc.kill(); throw new Error('chrome did not expose a page target'); }

  const ws = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((res, rej) => { ws.onopen = res; ws.onerror = rej; });

  let id = 0;
  const pending = new Map();
  const events = [];
  ws.onmessage = (m) => {
    const msg = JSON.parse(m.data);
    if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); }
    else if (msg.method) events.push(msg);
  };
  const send = (method, params = {}) => new Promise((res, rej) => {
    const n = ++id;
    pending.set(n, (m) => m.error ? rej(new Error(method + ': ' + m.error.message)) : res(m.result));
    ws.send(JSON.stringify({ id: n, method, params }));
    setTimeout(() => rej(new Error('timeout ' + method)), 60000);
  });

  await send('Page.enable');
  await send('Runtime.enable');
  // An audit that reads a cached page audits the past. This cost me one wrong
  // conclusion: a fix was live and measured correct, while the walk still saw
  // the stale stylesheet and reported the defect as unfixed.
  await send('Network.enable');
  await send('Network.setCacheDisabled', { cacheDisabled: true });
  await send('Emulation.setDeviceMetricsOverride',
             { width: W, height: H, deviceScaleFactor: 2, mobile: false });

  return {
    send, events, proc, ws,
    async goto(url) {
      await send('Page.navigate', { url });
      await new Promise(r => setTimeout(r, 2500));
    },
    async js(expr) {
      const r = await send('Runtime.evaluate',
        { expression: expr, returnByValue: true, awaitPromise: true });
      if (r.exceptionDetails) throw new Error(r.exceptionDetails.text + ' :: ' + expr.slice(0, 80));
      return r.result?.value;
    },
    async shot(path, opts = {}) {
      const r = await send('Page.captureScreenshot',
        { format: 'png', captureBeyondViewport: !!opts.full });
      writeFileSync(path, Buffer.from(r.data, 'base64'));
      return path;
    },
    async close() { try { ws.close(); } catch {} proc.kill(); },
  };
}
