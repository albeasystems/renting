// Pins the figures that the page copy quotes, so the text cannot drift away from the formulas.
import test from 'node:test';
import assert from 'node:assert/strict';
import { rentUpdate, firstMonthAtNewRent, rentalYield, REDUCTIONS } from './engine.js';

test('rent update: 800 EUR with a 3 % index', () => {
  const r = rentUpdate({ rent: 800, percent: 3 });
  assert.equal(r.newRent, 824);
  assert.equal(r.monthly, 24);
  assert.equal(r.yearly, 288);
});

test('rent update: rounds to cents', () => {
  assert.equal(rentUpdate({ rent: 950, percent: 2.54 }).newRent, 974.13);
});

test('first month at the new rent: the month after the notification, never before the anniversary', () => {
  // notified in time (before the anniversary month): the anniversary month
  assert.deepEqual(firstMonthAtNewRent({ year: 2026, month: 9 }, { year: 2026, month: 7 }), { year: 2026, month: 9 });
  // notified late: the month after the notification
  assert.deepEqual(firstMonthAtNewRent({ year: 2026, month: 9 }, { year: 2026, month: 9 }), { year: 2026, month: 10 });
  // across a year end
  assert.deepEqual(firstMonthAtNewRent({ year: 2026, month: 12 }, { year: 2026, month: 12 }), { year: 2027, month: 1 });
});

test('rental yield: 12,000 income, 3,000 expenses, 80,000 construction value, 50 % reduction', () => {
  const y = rentalYield({ income: 12000, expenses: 3000, constructionValue: 80000, rate: REDUCTIONS.general });
  assert.equal(y.depreciation, 2400);
  assert.equal(y.net, 6600);
  assert.equal(y.reduction, 3300);
  assert.equal(y.reduced, 3300);
});

test('rental yield: the reduction never applies to a loss', () => {
  const y = rentalYield({ income: 5000, expenses: 6000, constructionValue: 60000, rate: REDUCTIONS.old });
  assert.ok(y.net < 0);
  assert.equal(y.reduction, 0);
  assert.equal(y.reduced, y.net);
});

test('rental yield: a home let part of the year depreciates for that share', () => {
  const y = rentalYield({ income: 6000, expenses: 1000, constructionValue: 100000, rate: 0, share: 0.5 });
  assert.equal(y.depreciation, 1500);
  assert.equal(y.net, 3500);
});
