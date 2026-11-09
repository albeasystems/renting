// Content registry. A language appears on the site only once its file exists here, so the build never publishes
// a half-translated tree and hreflang never points at a missing page. "{app}" is replaced by SITE_NAME everywhere.
import es from './es.js';
import en from './en.js';
import fr from './fr.js';
import it from './it.js';
import de from './de.js';
import pt from './pt.js';
import ar from './ar.js';
import hi from './hi.js';
import zh from './zh.js';
import { legal } from './legal.js';
import { SITE_NAME } from '../site.js';

const fill = (v) => {
  if (typeof v === 'string') return v.replaceAll('{app}', SITE_NAME);
  if (Array.isArray(v)) return v.map(fill);
  if (v && typeof v === 'object') return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, fill(x)]));
  return v;
};

// Tool pages and legal pages exist in Spanish and English only: the rules they explain are Spanish.
export const content = fill({
  es: { ...es, legal: legal.es },
  en: { ...en, legal: legal.en },
  fr, it, de, pt, ar, hi, zh,
});

/** The tool pages, in the order the index shows them. */
export const PAGE_IDS = ['rent-update', 'tax', 'receipt'];
/** The pages of a language that really exist (the other languages have none). */
export const pagesOf = (lang) => PAGE_IDS.filter((id) => content[lang]?.pages?.[id]);
export const hasTools = (lang) => pagesOf(lang).length > 0;
/** Single captures per language live in public/media/views/<lang>/. All nine app languages are captured (marketing/capture.sh). */
export const CAPTURE_LANGS = ['es', 'en', 'fr', 'it', 'de', 'pt', 'ar', 'hi', 'zh'];
export const captureLang = (lang) => (CAPTURE_LANGS.includes(lang) ? lang : 'en');
/** The eight screens, in the order of the journey; `file` is the name in media/views/<lang>/<file>.webp. */
export const VIEWS = ['summary', 'chart', 'homes', 'collections', 'year', 'receipt', 'expenses', 'tax'];
