// The figures of the tool pages, ported from the iOS app so the site and the app agree:
//   Renting/Core/ReportService.swift   (depreciation 3 %, reduction on a positive net yield)
//   Renting/Core/Compliance.swift      (first month at the new rent: the month after the notification, never before the anniversary)
// Pure functions, no DOM: engine.test.js pins the worked examples that the page copy quotes.

const cents = (x) => Math.round((x + Number.EPSILON) * 100) / 100;

/** A month as a number (year * 12 + month index), so months compare and add without Date. */
export const monthIndex = (year, month) => year * 12 + (month - 1);
export const fromMonthIndex = (i) => ({ year: Math.floor(i / 12), month: (i % 12) + 1 });

/** New rent after applying an index (IRAV or CPI/IPC) given as a percentage. */
export function rentUpdate({ rent, percent }) {
  const newRent = cents(rent * (1 + percent / 100));
  return { newRent, monthly: cents(newRent - rent), yearly: cents((newRent - rent) * 12) };
}

/** First month charged at the new rent: the month after the written notification, never before the anniversary month. */
export function firstMonthAtNewRent(anniversary, notified) {
  return fromMonthIndex(Math.max(monthIndex(anniversary.year, anniversary.month), monthIndex(notified.year, notified.month) + 1));
}

/** Rates of the reduction on the net yield of a home let as the tenant's permanent residence. */
export const REDUCTIONS = { none: 0, general: 0.5, old: 0.6, rehab: 0.6, young: 0.7, tensioned: 0.9 };
export const DEPRECIATION_RATE = 0.03;

/**
 * Net rental yield of one home for a year, as the Tax tab computes it:
 * income - deductible expenses - 3 % of the construction value (for the share of the year the home was let);
 * the reduction applies only to a positive net yield.
 */
export function rentalYield({ income, expenses, constructionValue, rate, share = 1 }) {
  const depreciation = cents(constructionValue * DEPRECIATION_RATE * share);
  const net = cents(income - expenses - depreciation);
  const reduction = net > 0 ? cents(net * rate) : 0;
  return { depreciation, net, reduction, reduced: cents(net - reduction) };
}
