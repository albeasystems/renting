// The landlord's journey as a looping GIF + animated WebP, in two looks, plus single views, social cards and icons:
//   gif/renting-<lang>-framed.gif          phone bezel + caption, for social, README, the App Store product page
//   gif/renting-<lang>-screen.{gif,webp}   the bare screen, so the web can wrap it in CSS
//   ../web/public/media/...                what the site serves (animated WebP, single views, og-<lang>.jpg, icons)
// Run: npm install && node make-gif.mjs   (needs source/<lang>/<step>.png, taken in the iOS Simulator by capture.sh)
import sharp from 'sharp';
import pkg from 'gifenc';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const { GIFEncoder, quantize, applyPalette } = pkg;

const root = path.dirname(fileURLToPath(import.meta.url));
const WEB = path.join(root, '..', 'web');
const { content, VIEWS } = await import(path.join(WEB, 'src', 'content', 'index.js'));
const { SITE_NAME } = await import(path.join(WEB, 'src', 'site.js'));

const SHOT_W = 1206, SHOT_H = 2622;                       // iPhone 17 Pro screenshot
const SCREEN_W = 590, SCREEN_H = Math.round((SCREEN_W * SHOT_H) / SHOT_W);
const TEAL = '#0f756d', TEAL_LIGHT = '#4cc0ae', INK = '#0d1b19', PAPER = '#f4f7f5', NIGHT = '#0b1412';

// name of the capture, hold in ms. The order is the journey: look at the month, then the chart, the homes, collect, the year,
// the receipt, the expenses and finally the tax.
const STEPS = [['01-summary', 2200], ['02-chart', 2200], ['03-homes', 2000], ['04-collections', 2400], ['05-year', 2300], ['06-receipt', 2600], ['07-expenses', 2000], ['08-tax', 2800]];
const LANGS = Object.keys(content).filter((l) => fs.existsSync(path.join(root, 'source', l, '01-summary.png')));
const OUT = path.join(WEB, 'public', 'media');
fs.mkdirSync(path.join(OUT, 'views'), { recursive: true });
fs.mkdirSync(path.join(root, 'gif'), { recursive: true });

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');
const FONT = 'Helvetica Neue, Helvetica, Arial, PingFang SC, Geeza Pro, Kohinoor Devanagari, sans-serif';

async function framed(screenPng, caption, idx, total, rtl) {
  const W = 720, H = 1560, padX = 62, top = 235, bez = 12;
  const pw = W - padX * 2;
  const ph = Math.round((pw * SHOT_H) / SHOT_W);
  const screen = await sharp(screenPng).resize({ width: pw - bez * 2 }).toBuffer();
  const sh = (await sharp(screen).metadata()).height;
  const r = 78, ri = r - bez;
  const mask = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${pw - bez * 2}" height="${sh}"><rect width="100%" height="100%" rx="${ri}" fill="#fff"/></svg>`);
  const rounded = await sharp(screen).composite([{ input: mask, blend: 'dest-in' }]).png().toBuffer();
  const dots = Array.from({ length: total }, (_, i) => `<circle cx="${W / 2 - (total - 1) * 13 + i * 26}" cy="150" r="${i === idx ? 6 : 4}" fill="${i === idx ? TEAL_LIGHT : '#31433f'}"/>`).join('');
  const bg = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}">
    <rect width="100%" height="100%" fill="${NIGHT}"/>
    <text x="${W / 2}" y="105" text-anchor="middle" font-family="${FONT}" font-weight="700" font-size="${caption.length > 30 ? 38 : 44}" fill="#e8f1ee" letter-spacing="-1" ${rtl ? 'direction="rtl"' : ''}>${esc(caption)}</text>
    ${dots}
    <rect x="${padX}" y="${top}" width="${pw}" height="${ph}" rx="${r}" fill="#050505" stroke="#ffffff" stroke-opacity=".16" stroke-width="2"/>
  </svg>`);
  return sharp(bg).composite([{ input: rounded, left: padX + bez, top: top + bez }]).raw().toBuffer({ resolveWithObject: true });
}

// 1200x630 social card: the headline on the left, a crop of the yearly matrix on the right.
async function og(lang) {
  const c = content[lang], rtl = lang === 'ar', cjk = lang === 'zh' || lang === 'hi' || lang === 'ar';
  const max = lang === 'zh' ? 11 : cjk ? 18 : 22;
  const words = c.home.h1.split(lang === 'zh' ? '' : ' ');
  const lines = []; let cur = '';
  for (const w of words) { const t = cur ? (lang === 'zh' ? cur + w : `${cur} ${w}`) : w; if (t.length > max && cur) { lines.push(cur); cur = w; } else cur = t; }
  if (cur) lines.push(cur);
  const size = lines.length > 4 ? 52 : 60, x = rtl ? 640 : 70, anchor = rtl ? 'end' : 'start';
  const text = lines.map((l, i) => `<text x="${x}" y="${190 + i * (size + 12)}" font-family="${FONT}" font-size="${size}" font-weight="700" fill="${INK}" text-anchor="${anchor}" ${rtl ? 'direction="rtl"' : ''}>${esc(l)}</text>`).join('');
  const shot = await sharp(path.join(root, 'source', lang, '05-year.png')).resize({ width: 360 }).extract({ left: 0, top: 190, width: 360, height: 520 }).toBuffer();
  const sm = await sharp(shot).metadata();
  const mask = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${sm.width}" height="${sm.height}"><rect width="100%" height="${sm.height + 60}" rx="34" fill="#fff"/></svg>`);
  const rounded = await sharp(shot).composite([{ input: mask, blend: 'dest-in' }]).png().toBuffer();
  const px = rtl ? 70 : 1200 - 70 - sm.width, py = 100;
  const bg = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630"><rect width="1200" height="630" fill="${PAPER}"/>
    <rect x="${px - 8}" y="${py - 8}" width="${sm.width + 16}" height="${sm.height + 80}" rx="42" fill="#fff" stroke="#c9d6d2" stroke-width="2"/>
    ${text}
    <text x="${x}" y="565" font-family="${FONT}" font-size="30" font-weight="700" fill="${TEAL}" text-anchor="${anchor}" ${rtl ? 'direction="rtl"' : ''}>${esc(SITE_NAME)}</text></svg>`);
  const out = await sharp(bg).composite([{ input: rounded, left: px, top: py }]).jpeg({ quality: 86 }).toBuffer();
  fs.writeFileSync(path.join(OUT, `og-${lang}.jpg`), out);
}

// the app icon, in the sizes the site needs
const icon = path.join(root, '..', 'Renting', 'Assets.xcassets', 'AppIcon.appiconset', 'AppIcon-1024.png');
await sharp(icon).resize(256, 256).png().toFile(path.join(OUT, 'icon-256.png'));
await sharp(icon).resize(96, 96).png().toFile(path.join(OUT, 'icon-96.png'));
await sharp(icon).resize(48, 48).png().toFile(path.join(OUT, 'favicon.png'));

for (const lang of LANGS) {
  const rtl = lang === 'ar';
  const captions = content[lang].home.app.views.map((v) => v.caption);
  const screenGif = GIFEncoder(), framedGif = GIFEncoder();
  const webpFrames = [], delays = [];
  fs.mkdirSync(path.join(OUT, 'views', lang), { recursive: true });
  for (let i = 0; i < STEPS.length; i++) {
    const [name, hold] = STEPS[i];
    const src = fs.readFileSync(path.join(root, 'source', lang, `${name}.png`));
    const a = await sharp(src).resize({ width: SCREEN_W, height: SCREEN_H, fit: 'cover' }).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    const pa = quantize(a.data, 256, { format: 'rgb565' });
    screenGif.writeFrame(applyPalette(a.data, pa, 'rgb565'), a.info.width, a.info.height, { palette: pa, delay: hold });
    const f = await framed(src, captions[i], i, STEPS.length, rtl);
    const pf = quantize(f.data, 256, { format: 'rgb565' });
    framedGif.writeFrame(applyPalette(f.data, pf, 'rgb565'), f.info.width, f.info.height, { palette: pf, delay: hold });
    webpFrames.push(await sharp(src).resize({ width: SCREEN_W }).png().toBuffer());
    delays.push(hold);
    await sharp(src).resize({ width: 600 }).webp({ quality: 82 }).toFile(path.join(OUT, 'views', lang, `${VIEWS[i]}.webp`));
    // the yearly matrix, wide and cropped, for the ledger band of the home page
    if (name === '05-year') await sharp(src).extract({ left: 0, top: 520, width: SHOT_W, height: 1000 }).resize({ width: 1000 }).webp({ quality: 84 }).toFile(path.join(OUT, 'views', lang, 'year-band.webp'));
  }
  screenGif.finish(); framedGif.finish();
  fs.writeFileSync(path.join(root, 'gif', `renting-${lang}-screen.gif`), screenGif.bytes());
  fs.writeFileSync(path.join(root, 'gif', `renting-${lang}-framed.gif`), framedGif.bytes());
  fs.writeFileSync(path.join(OUT, `renting-${lang}-framed.gif`), framedGif.bytes());
  const webp = await sharp(webpFrames, { join: { animated: true } }).webp({ quality: 74, effort: 5, loop: 0, delay: delays }).toBuffer();
  fs.writeFileSync(path.join(root, 'gif', `renting-${lang}-screen.webp`), webp);
  fs.writeFileSync(path.join(OUT, `renting-${lang}-screen.webp`), webp);
  await og(lang);
  console.log(lang, 'framed', (framedGif.bytes().length / 1024).toFixed(0), 'KB, screen webp', (webp.length / 1024).toFixed(0), 'KB');
}
