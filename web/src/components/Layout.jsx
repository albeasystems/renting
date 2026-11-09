import { useEffect, useRef } from 'react';
import { Globe, CaretDown } from '@phosphor-icons/react';
import { LANGS, LANG_NAMES, HREFLANG, LEGAL_LANGS, CONTACT, PUBLISHER, SITE_NAME, APP_STORE, href } from '../site.js';
import { content, hasTools } from '../content/index.js';

/** The same page in another language, for the language menu. Tool pages exist in es and en only: other languages go to the home. */
export function counterpart(r, lang) {
  if (r.page === 'home') return `${lang}/`;
  if (r.page === 'tool') return content[lang].pages?.[r.id] ? `${lang}/${content[lang].pages[r.id].slug}/` : `${lang}/`;
  return LEGAL_LANGS.includes(lang) ? `${lang}/${r.id}/` : `en/${r.id}/`;
}
export const toolRoute = (lang, id) => `${lang}/${content[lang].pages[id].slug}/`;

export function Logo({ lang }) {
  return (
    <a href={href(`${lang}/`)} className="flex items-center gap-3 no-underline" aria-label={SITE_NAME}>
      <img src={href('media/icon-96.png')} width="34" height="34" alt="" style={{ borderRadius: 9, boxShadow: '0 0 0 1px var(--rule-strong)' }} />
      <span className="text-xl font-bold tracking-tight">{SITE_NAME}</span>
    </a>
  );
}

/** Remembered by the root page (the language chooser), which sends returning visitors to this language. */
export const LANG_KEY = 'renting-lang';

/** Real links inside a <details>, so it works without JavaScript; with it, it also closes on outside click and Escape. */
function LangMenu({ r, ui }) {
  const langs = LANGS.filter((l) => content[l]);
  const box = useRef(null);
  useEffect(() => {
    const el = box.current;
    const close = () => { el.open = false; };
    const onDown = (e) => { if (el.open && !el.contains(e.target)) close(); };
    const onKey = (e) => { if (e.key === 'Escape' && el.open) { close(); el.querySelector('summary').focus(); } };
    document.addEventListener('pointerdown', onDown);
    document.addEventListener('keydown', onKey);
    return () => { document.removeEventListener('pointerdown', onDown); document.removeEventListener('keydown', onKey); };
  }, []);
  const remember = (l) => { try { localStorage.setItem(LANG_KEY, l); } catch { /* private mode: the choice just is not remembered */ } };
  return (
    <details className="relative" ref={box}>
      <summary className="lang-btn" aria-label={`${ui.langLabel}: ${LANG_NAMES[r.lang]}`}>
        <Globe size={18} aria-hidden="true" />
        <span className="hidden sm:inline" lang={HREFLANG[r.lang]}>{LANG_NAMES[r.lang]}</span>
        <span className="sm:hidden">{r.lang.toUpperCase()}</span>
        <CaretDown size={12} weight="bold" aria-hidden="true" />
      </summary>
      <ul className="lang-list absolute end-0 z-30 mt-2 list-none p-2" aria-label={ui.langLabel}>
        {langs.map((l) => (
          <li key={l}>
            <a lang={HREFLANG[l]} hrefLang={HREFLANG[l]} href={href(counterpart(r, l))} className="lang-item" onClick={() => remember(l)} aria-current={l === r.lang ? 'true' : undefined}>
              {LANG_NAMES[l]}
            </a>
          </li>
        ))}
      </ul>
    </details>
  );
}

/** The store badge: a link once the app is published, a plain "coming soon" until then. */
export function StoreBadge({ ui, className = '' }) {
  return APP_STORE
    ? <a href={APP_STORE} className={`btn ${className}`} rel="noopener">{ui.download}</a>
    : <span className="soon">{ui.soon}</span>;
}

export function Nav({ r, ui }) {
  const home = href(`${r.lang}/`);
  const links = [[ui.nav.app, `${home}#app`], ...(hasTools(r.lang) ? [[ui.nav.tools, `${home}#tools`]] : []), [ui.nav.plans, `${home}#plans`], [ui.nav.faq, `${home}#faq`]];
  return (
    <header style={{ borderBottom: '1px solid var(--rule)' }}>
      <div className="wrap flex items-center justify-between gap-4 py-3">
        <Logo lang={r.lang} />
        <nav aria-label="Principal" className="flex items-center gap-6">
          <ul className="hidden list-none items-center gap-6 p-0 text-[0.9375rem] md:flex">
            {links.map(([l, h]) => <li key={h}><a href={h} className="no-underline hover:underline">{l}</a></li>)}
          </ul>
          <LangMenu r={r} ui={ui} />
          {APP_STORE
            ? <a href={APP_STORE} className="btn btn-sm" rel="noopener">{ui.downloadShort}</a>
            : <span className="label hidden whitespace-nowrap lg:inline">{ui.soonShort}</span>}
        </nav>
      </div>
    </header>
  );
}

export function Footer({ r, ui }) {
  const f = ui.footer;
  const legal = LEGAL_LANGS.includes(r.lang) ? r.lang : 'en';
  return (
    <footer className="mt-auto" style={{ borderTop: '1px solid var(--rule)', background: 'var(--paper-2)' }}>
      <div className="wrap py-10">
        <div className="grid grid-cols-1 gap-10 md:grid-cols-[1.4fr_1fr_1fr_1.4fr]">
          <div>
            <Logo lang={r.lang} />
            <p className="muted mt-4 max-w-xs text-sm">{f.project}</p>
          </div>
          <div className="text-sm"><span className="label mb-1 block">{f.publisher}</span>{PUBLISHER}<br /><a href={`mailto:${CONTACT}`}>{CONTACT}</a></div>
          <div className="grid content-start gap-1.5 text-sm"><span className="label mb-1 block">{f.legal}</span>
            <a href={href(`${legal}/privacy/`)} hrefLang={legal}>{f.privacy}</a>
            <a href={href(`${legal}/terms/`)} hrefLang={legal}>{f.terms}</a>
            <a href={href(`${legal}/support/`)} hrefLang={legal}>{f.support}</a>
          </div>
          <div className="grid grid-cols-2 content-start gap-x-6 gap-y-1.5 text-sm"><span className="label col-span-2 mb-1 block">{f.languages}</span>
            {LANGS.filter((l) => content[l]).map((l) => <a key={l} lang={HREFLANG[l]} hrefLang={HREFLANG[l]} href={href(counterpart(r, l))}>{LANG_NAMES[l]}</a>)}
          </div>
        </div>
        <p className="muted mt-10 border-t pt-6 text-sm measure" style={{ borderColor: 'var(--rule)' }}>{f.disclaimer}</p>
      </div>
    </footer>
  );
}

export function Shell({ r, children }) {
  const { ui } = content[r.lang];
  return (
    <div className="sheet">
      <a href="#main" className="sr-only focus:not-sr-only focus:absolute focus:z-50 focus:p-3" style={{ background: 'var(--paper)' }}>{ui.skip}</a>
      <Nav r={r} ui={ui} />
      <main id="main">{children}</main>
      <Footer r={r} ui={ui} />
    </div>
  );
}
