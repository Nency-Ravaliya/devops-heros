// Headless-Chrome screenshot via the DevTools protocol, with optional cookie (for Grafana / Argo CD logins).
// usage: node shot.mjs <url> <out.png> [cookieName=cookieValue] [waitMs]
import { spawn } from 'node:child_process';
import { writeFileSync } from 'node:fs';
const [url, out, cookie, waitMs = '4000'] = process.argv.slice(2);
const port = 19222 + Math.floor(Math.random() * 500);
const chrome = spawn('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  ['--headless=new', `--remote-debugging-port=${port}`, '--window-size=1400,900', '--ignore-certificate-errors',
   '--no-first-run', '--user-data-dir=/tmp/shot-profile-' + port, 'about:blank'], { stdio: 'ignore' });
const sleep = ms => new Promise(r => setTimeout(r, ms));
let ws;
for (let i = 0; i < 50; i++) { try { const l = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); const p = l.find(t => t.type === 'page'); if (p) { ws = new WebSocket(p.webSocketDebuggerUrl); break; } } catch {} await sleep(200); }
await new Promise(r => ws.onopen = r);
let id = 0; const pending = {};
ws.onmessage = e => { const m = JSON.parse(e.data); if (m.id && pending[m.id]) { pending[m.id](m.result); delete pending[m.id]; } };
const send = (method, params = {}) => new Promise(r => { pending[++id] = r; ws.send(JSON.stringify({ id, method, params })); });
await send('Page.enable'); await send('Network.enable');
await send('Emulation.setDeviceMetricsOverride', { width: 1400, height: 900, deviceScaleFactor: 1, mobile: false });
if (cookie) { const [name, ...rest] = cookie.split('='); const u = new URL(url);
  await send('Network.setCookie', { name, value: rest.join('='), domain: u.hostname, path: '/', secure: u.protocol === 'https:' }); }
await send('Page.navigate', { url });
await sleep(Number(waitMs));
const { data } = await send('Page.captureScreenshot', { format: 'png' });
writeFileSync(out, Buffer.from(data, 'base64'));
ws.close(); chrome.kill(); console.log(`saved ${out}`);
