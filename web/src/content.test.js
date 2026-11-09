// Every language mirrors es.js key for key, except the parts that exist in Spanish and English only; the copy rules hold
// (no em-dash, no invented proof, the {app} placeholder is always filled, figures agree with the engine).
import test from 'node:test';
import assert from 'node:assert/strict';
import { content, PAGE_IDS, VIEWS } from './content/index.js';
import { LANGS, TOOL_LANGS, LEGAL_LANGS } from './site.js';
import { rentUpdate, rentalYield, REDUCTIONS } from './engine.js';

const keys = (o, p = '') => Object.entries(o).flatMap(([k, v]) => (v && typeof v === 'object' && !Array.isArray(v) ? keys(v, `${p}${k}.`) : [`${p}${k}`]));
const ONLY_ES_EN = ['legal.', 'pages.', 'related.', 'sections.', 'ui.lab.', 'ui.nav.tools', 'ui.tryTools', 'home.tools.'];
const common = (l) => keys(content[l]).filter((k) => !ONLY_ES_EN.some((p) => k.startsWith(p)));
const base = common('es');

test('all nine app languages are registered', () => assert.deepEqual(LANGS.filter((l) => content[l]), LANGS));

for (const l of LANGS) {
  test(`${l}: same keys as es`, () => assert.deepEqual(common(l), base));
  test(`${l}: arrays keep their length`, () => {
    assert.equal(content[l].home.faq.items.length, content.es.home.faq.items.length);
    assert.equal(content[l].home.app.views.length, VIEWS.length);
    assert.deepEqual(content[l].home.app.views.map((v) => v.file), VIEWS);
    assert.equal(content[l].home.plans.rows.length, 3);
  });
  test(`${l}: no em-dash, no invented ratings, placeholder filled`, () => {
    const text = JSON.stringify(content[l]);
    assert.ok(!text.includes('—'), 'em-dash found');
    assert.ok(!/aggregateRating|testimonial/i.test(text));
    assert.ok(!text.includes('{app}'), 'unfilled {app}');
  });
}

for (const l of TOOL_LANGS) {
  test(`${l}: tool pages complete, slugs unique and url-safe`, () => {
    const slugs = PAGE_IDS.map((id) => content[l].pages[id].slug);
    assert.equal(new Set(slugs).size, slugs.length);
    for (const s of slugs) assert.match(s, /^[a-z0-9-]+$/);
    for (const id of PAGE_IDS) { assert.equal(content[l].pages[id].faq.length, 4); assert.equal(content[l].pages[id].how.paras.length, 2); }
  });
  test(`${l}: tool pages mirror each other`, () => {
    assert.deepEqual(keys(content[l].ui.lab), keys(content.es.ui.lab));
    assert.deepEqual(keys(content[l].pages), keys(content.es.pages));
  });
}

for (const l of LEGAL_LANGS) {
  test(`${l}: legal pages complete`, () => {
    for (const id of ['privacy', 'terms', 'support']) { const d = content[l].legal[id]; assert.ok(d.title && d.description && d.updated && d.sections.length >= 5, id); }
  });
}

test('the worked examples quoted in the copy agree with the engine', () => {
  const r = rentUpdate({ rent: 800, percent: 3 });
  assert.ok(content.en.pages['rent-update'].answer.includes('824 €') && content.en.pages['rent-update'].answer.includes('288 €') && r.newRent === 824 && r.yearly === 288);
  const y = rentalYield({ income: 12000, expenses: 3000, constructionValue: 80000, rate: REDUCTIONS.general });
  const a = content.en.pages.tax.answer;
  assert.ok(a.includes('2,400') && a.includes('6,600') && a.includes('3,300'));
  assert.deepEqual([y.depreciation, y.net, y.reduced], [2400, 6600, 3300]);
  const e = content.es.pages.tax.answer;
  assert.ok(e.includes('2.400') && e.includes('6.600') && e.includes('3.300'));
});
