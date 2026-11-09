import { ArrowUpRight } from '@phosphor-icons/react';
import { content, pagesOf, hasTools, captureLang } from '../content/index.js';
import { UPDATED, INTL, PUBLISHER, SITE_NAME, href } from '../site.js';
import { Shell, StoreBadge, toolRoute } from './Layout.jsx';
import { LABS } from './Tools.jsx';

const FaqMark = () => (
  <svg className="faq-mark" viewBox="0 0 16 16" aria-hidden="true"><path d="M2 8h12" /><path className="v" d="M8 2v12" /></svg>
);

function Faq({ items, title, id }) {
  return (
    <section className="zone" id={id} aria-labelledby={`${id}-h`}>
      <div className="wrap grid grid-cols-1 gap-10 lg:grid-cols-12">
        <h2 id={`${id}-h`} className="h2 lg:col-span-4">{title}</h2>
        <div className="lg:col-span-8">
          {items.map(([q, a]) => (
            <details key={q} className="faq" style={{ borderTop: '1px solid var(--rule)' }}>
              <summary className="flex items-start justify-between gap-6 py-5">
                <h3 className="h3 m-0">{q}</h3>
                <FaqMark />
              </summary>
              <p className="muted measure pb-6">{a}</p>
            </details>
          ))}
        </div>
      </div>
    </section>
  );
}

/** The free tools, as large rows with one rule under each. */
export function ToolsIndex({ lang, title, lede, skip }) {
  const c = content[lang];
  const ids = pagesOf(lang).filter((id) => id !== skip);
  return (
    <section className="zone" id="tools" aria-labelledby="tools-h">
      <div className="wrap">
        <h2 id="tools-h" className="h2 max-w-3xl">{title}</h2>
        {lede && <p className="lede mt-4 measure">{lede}</p>}
        <ul className="mt-10 list-none p-0" style={{ borderTop: '1px solid var(--rule)' }}>
          {ids.map((id) => (
            <li key={id}>
              <a href={href(toolRoute(lang, id))} className="tool-row">
                <span>
                  <span className="t block">{c.pages[id].short}</span>
                  <span className="muted mt-1 block text-[0.9375rem]">{c.pages[id].blurb}</span>
                </span>
                <span className="go" aria-hidden="true"><ArrowUpRight size={20} /></span>
              </a>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}

// ---------- home ----------

export function Home({ r }) {
  const c = content[r.lang];
  const { ui, home } = c;
  const lang = r.lang;
  const cl = captureLang(lang);
  const tools = hasTools(lang);
  return (
    <Shell r={r}>
      <section className="zone !pt-10 md:!pt-14" aria-labelledby="h1">
        <div className="wrap grid grid-cols-1 items-start gap-12 lg:grid-cols-12 lg:gap-14">
          <div className="rise grid grid-cols-1 content-start justify-items-start gap-7 lg:col-span-7 lg:pt-16">
            <h1 id="h1" className="h1" style={{ fontSize: 'clamp(2.1rem, 3.9vw, 3.4rem)' }}>{home.h1}</h1>
            <p className="lede measure">{home.lede}</p>
            <div className="flex flex-wrap items-center gap-x-6 gap-y-2">
              {tools ? <a href="#tools" className="btn">{ui.tryTools}</a> : <a href="#app" className="btn">{ui.seeApp}</a>}
              <StoreBadge ui={ui} />
            </div>
          </div>
          <figure className="relative m-0 mx-auto w-full max-w-[16.5rem] lg:col-span-5 lg:max-w-[19.5rem] lg:justify-self-center">
            <div className="device">
              <picture>
                <source media="(prefers-reduced-motion: reduce)" srcSet={href(`media/views/${cl}/summary.webp`)} />
                <img src={href(`media/renting-${cl}-screen.webp`)} width="590" height="1283" alt={home.gifAlt} fetchPriority="high" />
              </picture>
            </div>
            <figcaption className="label mt-4">{home.caption}</figcaption>
          </figure>
        </div>
      </section>

      <section className="zone" id="app" aria-labelledby="app-h">
        <div className="wrap">
          <h2 id="app-h" className="h2 max-w-3xl">{home.app.title}</h2>
          <p className="lede mt-4 measure">{home.app.lede}</p>
        </div>
        <ul className="rail mt-12" tabIndex={0} aria-label={home.app.title}>
          {home.app.views.map((v) => (
            <li key={v.file} className="w-[13.5rem] sm:w-[15rem]">
              <figure className="m-0">
                <div className="device"><img src={href(`media/views/${cl}/${v.file}.webp`)} width="600" height="1304" loading="lazy" decoding="async" alt={v.alt} /></div>
                <figcaption className="mt-4 text-sm font-medium">{v.caption}</figcaption>
              </figure>
            </li>
          ))}
        </ul>
      </section>

      <section className="zone" id="ledger" aria-labelledby="ledger-h">
        <div className="wrap grid grid-cols-1 items-center gap-10 lg:grid-cols-12 lg:gap-14">
          <div className="grid content-center gap-5 lg:col-span-5">
            <h2 id="ledger-h" className="h2">{home.ledger.title}</h2>
            <p className="lede">{home.ledger.text}</p>
          </div>
          <div className="band lg:col-span-7">
            <img src={href(`media/views/${cl}/year-band.webp`)} width="1000" height="829" loading="lazy" decoding="async" alt={home.ledger.alt} />
          </div>
        </div>
      </section>

      <section className="zone" id="tax" aria-labelledby="tax-h">
        <div className="wrap grid grid-cols-1 items-center gap-10 lg:grid-cols-12 lg:gap-14">
          <figure className="m-0 mx-auto w-full max-w-[15rem] lg:col-span-4 lg:max-w-[17rem]">
            <div className="device"><img src={href(`media/views/${cl}/tax.webp`)} width="600" height="1304" loading="lazy" decoding="async" alt={home.tax.alt} /></div>
          </figure>
          <div className="grid content-center gap-5 lg:col-span-7">
            <h2 id="tax-h" className="h2">{home.tax.title}</h2>
            <p className="lede measure">{home.tax.text}</p>
            <p className="label measure">{home.tax.note}</p>
          </div>
        </div>
      </section>

      {tools && <ToolsIndex lang={lang} title={home.tools.title} lede={home.tools.lede} />}

      <section className="zone" id="plans" aria-labelledby="plans-h">
        <div className="wrap">
          <h2 id="plans-h" className="h2 max-w-3xl">{home.plans.title}</h2>
          <p className="lede mt-4 measure">{home.plans.lede}</p>
          <dl className="m-0 mt-12 grid grid-cols-1 gap-x-10 gap-y-10 md:grid-cols-3">
            {home.plans.rows.map(([k, v], i) => (
              <div key={k} className="pt-5" style={{ borderTop: `${i === 1 ? 3 : 1}px solid ${i === 1 ? 'var(--teal)' : 'var(--rule-strong)'}` }}>
                <dt className="h3 mb-3">{k}</dt>
                <dd className="muted m-0 text-[0.9375rem]">{v}</dd>
              </div>
            ))}
          </dl>
        </div>
      </section>

      <Faq id="faq" title={home.faq.title} items={home.faq.items} />

      <section className="zone !pb-20" aria-labelledby="close-h">
        <div className="wrap grid grid-cols-1 items-end gap-8 lg:grid-cols-12">
          <div className="lg:col-span-8">
            <h2 id="close-h" className="h1" style={{ fontSize: 'clamp(2rem, 4.2vw, 3.4rem)' }}>{home.close.title}</h2>
            <p className="lede mt-4 measure">{home.close.lede}</p>
          </div>
          <div className="flex flex-wrap items-center gap-x-6 gap-y-2 lg:col-span-4 lg:justify-end">
            {tools ? <a href="#tools" className="btn">{ui.tryTools}</a> : <StoreBadge ui={ui} />}
          </div>
        </div>
      </section>
    </Shell>
  );
}

// ---------- tool pages ----------

export function ToolPage({ r }) {
  const c = content[r.lang];
  const { ui } = c;
  const p = c.pages[r.id];
  const Lab = LABS[p.lab];
  const updated = new Intl.DateTimeFormat(INTL[r.lang], { dateStyle: 'long', timeZone: 'UTC' }).format(new Date(UPDATED));
  return (
    <Shell r={r}>
      <section className="zone !pt-10 md:!pt-14" aria-labelledby="h1">
        <div className="wrap">
          <nav aria-label="breadcrumb" className="label mb-8">
            <a href={href(`${r.lang}/`)}>{SITE_NAME}</a> / <a href={href(`${r.lang}/#tools`)}>{ui.nav.tools}</a>
          </nav>
          <div className="rise grid grid-cols-1 gap-6">
            <h1 id="h1" className="h1 max-w-[22ch]" style={{ fontSize: 'clamp(2rem, 4.4vw, 3.5rem)' }}>{p.h1}</h1>
            <p className="lede max-w-[62ch]" style={{ color: 'var(--ink)' }}>{p.answer}</p>
            <p className="num inline-block max-w-fit rounded-xl px-3 py-2 text-[0.9375rem]" style={{ color: 'var(--ink-2)', background: 'var(--paper-2)' }}>{p.formula}</p>
            <p className="label">{ui.updated}: <time dateTime={UPDATED}>{updated}</time> · {PUBLISHER}</p>
          </div>
        </div>
      </section>

      <section className="zone" aria-label={p.short}>
        <div className="wrap"><Lab lang={r.lang} ui={ui} /></div>
      </section>

      <section className="zone" aria-labelledby="how-h">
        <div className="wrap grid grid-cols-1 gap-10 lg:grid-cols-12">
          <h2 id="how-h" className="h2 lg:col-span-4">{p.how.title}</h2>
          <div className="grid grid-cols-1 gap-5 lg:col-span-7">
            {p.how.paras.map((t) => <p key={t} className="measure">{t}</p>)}
            <div className="mt-4 grid justify-items-start gap-3"><p className="muted text-[0.9375rem]">{ui.cta.text}</p><StoreBadge ui={ui} /></div>
          </div>
        </div>
      </section>

      <Faq id="faq" title={c.sections.faq} items={p.faq} />
      <ToolsIndex lang={r.lang} title={c.related.title} skip={r.id} />
    </Shell>
  );
}

// ---------- legal ----------

export function LegalPage({ r }) {
  const doc = content[r.lang].legal[r.id];
  return (
    <Shell r={r}>
      <section className="zone !pt-12">
        <div className="wrap grid grid-cols-1 gap-10 lg:grid-cols-12">
          <div className="lg:col-span-4">
            <h1 className="h1" style={{ fontSize: 'clamp(2rem, 4vw, 3rem)' }}>{doc.title}</h1>
            <p className="label mt-4">{doc.updated}</p>
          </div>
          <div className="grid grid-cols-1 gap-9 lg:col-span-8">
            {doc.sections.map(([h, ...ps]) => (
              <div key={h}>
                <h2 className="h3 mb-3">{h}</h2>
                <div className="grid gap-3">{ps.map((t) => <p key={t} className="measure">{t}</p>)}</div>
              </div>
            ))}
          </div>
        </div>
      </section>
    </Shell>
  );
}

export function Page({ r }) {
  if (r.page === 'home') return <Home r={r} />;
  if (r.page === 'tool') return <ToolPage r={r} />;
  return <LegalPage r={r} />;
}
