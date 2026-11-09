import { useId, useState } from 'react';
import { Printer } from '@phosphor-icons/react';
import { rentUpdate, firstMonthAtNewRent, rentalYield, REDUCTIONS } from '../engine.js';
import { money, pct } from '../format.js';
import { INTL } from '../site.js';

/** Number input that keeps what the visitor typed and hands the page a clamped number. */
function Field({ label, value, onChange, unit, type = 'number', step = 'any', min = 0, max, wide }) {
  const id = useId();
  return (
    <label className={`field ${wide ? 'sm:col-span-2' : ''}`} htmlFor={id}>
      <span className="k">{label}</span>
      <span className="input">
        <input id={id} type={type} inputMode={type === 'number' ? 'decimal' : undefined} step={type === 'number' ? step : undefined} min={type === 'number' ? min : undefined} max={max} value={value} onChange={(e) => onChange(e.target.value)} />
        {unit && <span className="unit">{unit}</span>}
      </span>
    </label>
  );
}

function Select({ label, value, onChange, options, wide }) {
  const id = useId();
  return (
    <label className={`field ${wide ? 'sm:col-span-2' : ''}`} htmlFor={id}>
      <span className="k">{label}</span>
      <span className="input">
        <select id={id} value={value} onChange={(e) => onChange(e.target.value)}>
          {options.map(([v, t]) => <option key={v} value={v}>{t}</option>)}
        </select>
      </span>
    </label>
  );
}

const Line = ({ k, v }) => <div className="line"><span className="k">{k}</span><span className="v">{v}</span></div>;
const n = (s, d = 0, lo = 0, hi = Infinity) => { const x = parseFloat(String(s).replace(',', '.')); return Number.isFinite(x) ? Math.min(hi, Math.max(lo, x)) : d; };

function Layout({ form, results, live = true }) {
  return (
    <div className="grid items-start gap-10 lg:grid-cols-[5fr_7fr] lg:gap-16">
      <div className="grid content-start gap-5 sm:grid-cols-2 lg:grid-cols-1">{form}</div>
      <div className="min-w-0" aria-live={live ? 'polite' : undefined}>{results}</div>
    </div>
  );
}

const monthLabel = (ym, lang) => {
  const [y, m] = ym.split('-').map(Number);
  return new Intl.DateTimeFormat(INTL[lang], { month: 'long', year: 'numeric', timeZone: 'UTC' }).format(new Date(Date.UTC(y, m - 1, 1)));
};
const parseYM = (s, fallback) => { const m = /^(\d{4})-(\d{2})$/.exec(s || ''); return m ? { year: +m[1], month: +m[2] } : fallback; };

export function RentUpdateLab({ lang, ui }) {
  const t = ui.lab.rentUpdate;
  const [rent, setRent] = useState('800');
  const [index, setIndex] = useState('3');
  const [anniv, setAnniv] = useState('2026-12');
  const [notified, setNotified] = useState('2026-10');
  const r = rentUpdate({ rent: n(rent, 0), percent: n(index, 0, -100, 100) });
  const first = firstMonthAtNewRent(parseYM(anniv, { year: 2026, month: 12 }), parseYM(notified, { year: 2026, month: 10 }));
  const firstLabel = monthLabel(`${first.year}-${String(first.month).padStart(2, '0')}`, lang);
  return (
    <Layout
      form={<>
        <Field label={t.rent} value={rent} onChange={setRent} unit={ui.lab.currency} />
        <Field label={t.index} value={index} onChange={setIndex} unit="%" min={-100} />
        <Field label={t.anniversary} type="month" value={anniv} onChange={setAnniv} />
        <Field label={t.notified} type="month" value={notified} onChange={setNotified} />
        <p className="label sm:col-span-2">{t.note}</p>
      </>}
      results={<>
        <Line k={t.perMonth} v={money(r.monthly, lang, ui.lab.currency)} />
        <Line k={t.perYear} v={money(r.yearly, lang, ui.lab.currency)} />
        <Line k={t.firstMonth} v={firstLabel} />
        <div className="answer"><span className="k">{t.newRent}</span><span className="v">{money(r.newRent, lang, ui.lab.currency)}</span></div>
      </>}
    />
  );
}

export function TaxLab({ lang, ui }) {
  const t = ui.lab.tax;
  const [income, setIncome] = useState('12000');
  const [expenses, setExpenses] = useState('3000');
  const [construction, setConstruction] = useState('80000');
  const [months, setMonths] = useState('12');
  const [kind, setKind] = useState('general');
  const y = rentalYield({ income: n(income), expenses: n(expenses), constructionValue: n(construction), rate: REDUCTIONS[kind], share: n(months, 12, 0, 12) / 12 });
  const cur = ui.lab.currency;
  return (
    <Layout
      form={<>
        <Field label={t.income} value={income} onChange={setIncome} unit={cur} />
        <Field label={t.expenses} value={expenses} onChange={setExpenses} unit={cur} />
        <Field label={t.construction} value={construction} onChange={setConstruction} unit={cur} />
        <Field label={t.months} value={months} onChange={setMonths} unit="/ 12" min={0} max={12} step={1} />
        <Select wide label={t.reduction} value={kind} onChange={setKind} options={[['general', t.general], ['old', t.old], ['rehab', t.rehab], ['young', t.young], ['tensioned', t.tensioned], ['none', t.none]]} />
        <p className="label sm:col-span-2">{t.note}</p>
      </>}
      results={<>
        <Line k={t.income} v={money(n(income), lang, cur)} />
        <Line k={t.expenses} v={money(-n(expenses), lang, cur)} />
        <Line k={`${t.depreciation}`} v={money(-y.depreciation, lang, cur)} />
        <Line k={t.net} v={money(y.net, lang, cur)} />
        <Line k={`${t.reductionAmount} (${pct(REDUCTIONS[kind] * 100, lang, 0)})`} v={money(-y.reduction, lang, cur)} />
        <div className="answer"><span className="k">{t.reduced}</span><span className="v">{money(y.reduced, lang, cur)}</span></div>
      </>}
    />
  );
}

export function ReceiptLab({ lang, ui }) {
  const t = ui.lab.receipt;
  const [f, setF] = useState({ landlord: 'Marta Iglesias Vidal', taxId: '12345678Z', tenant: 'Lucía Fernández', property: 'Calle Gran Vía 14, 3ºB, Madrid. Habitación 1', month: '2026-11', rent: '420', utilities: '35', paidOn: '2026-11-04', city: 'Madrid' });
  const set = (k) => (v) => setF((p) => ({ ...p, [k]: v }));
  const rent = n(f.rent), utilities = n(f.utilities), cur = ui.lab.currency;
  const day = /^\d{4}-\d{2}-\d{2}$/.test(f.paidOn) ? new Intl.DateTimeFormat(INTL[lang], { dateStyle: 'long', timeZone: 'UTC' }).format(new Date(`${f.paidOn}T00:00:00Z`)) : '';
  const blank = (s) => s || <span style={{ color: '#8a8a8a' }}>{t.empty}</span>;
  return (
    <Layout
      live={false}
      form={<>
        <Field wide type="text" label={t.landlord} value={f.landlord} onChange={set('landlord')} />
        <Field type="text" label={t.taxId} value={f.taxId} onChange={set('taxId')} />
        <Field type="text" label={t.city} value={f.city} onChange={set('city')} />
        <Field wide type="text" label={t.tenant} value={f.tenant} onChange={set('tenant')} />
        <Field wide type="text" label={t.property} value={f.property} onChange={set('property')} />
        <Field type="month" label={t.month} value={f.month} onChange={set('month')} />
        <Field type="date" label={t.paidOn} value={f.paidOn} onChange={set('paidOn')} />
        <Field label={t.rent} value={f.rent} onChange={set('rent')} unit={cur} />
        <Field label={t.utilities} value={f.utilities} onChange={set('utilities')} unit={cur} />
        <p className="label sm:col-span-2">{t.note}</p>
      </>}
      results={<>
        <div className="mb-4 flex items-center justify-between gap-4">
          <span className="label">{t.preview}</span>
          <button type="button" className="btn btn-sm" onClick={() => window.print()}><Printer size={18} aria-hidden="true" />{t.print}</button>
        </div>
        <div className="receipt" role="group" aria-label={t.title}>
          <div style={{ borderTop: '4px solid #0f756d', paddingTop: '0.9rem' }} className="flex items-baseline justify-between gap-4">
            <strong style={{ fontSize: '1.2rem' }}>{t.title}</strong>
            <span style={{ color: '#555' }}>{t.period}: {f.month ? monthLabel(f.month, lang) : ''}</span>
          </div>
          <dl className="mt-5 grid gap-3 sm:grid-cols-2" style={{ margin: 0 }}>
            <div><dt style={{ color: '#555', fontSize: '0.8125rem' }}>{t.landlordLabel}</dt><dd style={{ margin: 0 }}>{blank(f.landlord)}{f.taxId ? ` · ${f.taxId}` : ''}</dd></div>
            <div><dt style={{ color: '#555', fontSize: '0.8125rem' }}>{t.tenantLabel}</dt><dd style={{ margin: 0 }}>{blank(f.tenant)}</dd></div>
            <div className="sm:col-span-2"><dt style={{ color: '#555', fontSize: '0.8125rem' }}>{t.propertyLabel}</dt><dd style={{ margin: 0 }}>{blank(f.property)}</dd></div>
          </dl>
          <table className="mt-5 w-full" style={{ borderCollapse: 'collapse' }}>
            <caption className="sr-only">{t.concepts}</caption>
            <tbody>
              <tr><td style={{ padding: '0.35rem 0' }}>{t.rentLine}</td><td style={{ textAlign: 'end' }}>{money(rent, lang, cur)}</td></tr>
              <tr><td style={{ padding: '0.35rem 0' }}>{t.utilitiesLine}</td><td style={{ textAlign: 'end' }}>{money(utilities, lang, cur)}</td></tr>
              <tr style={{ borderTop: '2px solid #111', fontWeight: 700 }}><td style={{ padding: '0.5rem 0' }}>{t.total}</td><td style={{ textAlign: 'end' }}>{money(rent + utilities, lang, cur)}</td></tr>
            </tbody>
          </table>
          <p className="mt-4">{t.received}</p>
          <p style={{ color: '#555' }}>{[f.city, day && `${t.paidLabel} ${day}`].filter(Boolean).join(', ')}</p>
          <div className="mt-10 w-1/2 border-t pt-1" style={{ borderColor: '#111', color: '#555', fontSize: '0.8125rem' }}>{t.signature}</div>
          <p className="mt-6" style={{ color: '#777', fontSize: '0.75rem' }}>{t.legal}</p>
        </div>
      </>}
    />
  );
}

export const LABS = { rentUpdate: RentUpdateLab, tax: TaxLab, receipt: ReceiptLab };
