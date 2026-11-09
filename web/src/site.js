// Where the site lives and what it is called. Every fact that is still undecided is ONE constant here
// (see PRODUCT.md, "Undecided facts"): the name, the store link and the origin.

// The app's name is provisional ("Renting" is the working name; candidates: Casero, Llavero, Rentia).
// In Spanish "renting" also means vehicle leasing, so decide before investing in brand SEO.
// Copy writes "{app}" wherever the name appears; content/index.js replaces it with this constant.
export const SITE_NAME = 'Renting';

// The app is not on the App Store yet. When it is, set the numeric id: the "coming soon" badge turns into
// the download link everywhere, and the pages declare the store URL, the smart banner and the install link.
export const APP_ID = null;
export const APP_STORE = APP_ID ? `https://apps.apple.com/app/id${APP_ID}` : null;

// No domain exists yet, so the site is published from the repository albeasystems/renting
// at https://albeasystems.github.io/renting/. With a custom domain build with VITE_SITE_ORIGIN and BASE_PATH=/.
export const ORIGIN = import.meta.env?.VITE_SITE_ORIGIN || 'https://albeasystems.github.io';
export const BASE = import.meta.env?.BASE_URL || '/renting/';
export const PUBLISHER = 'Albea Systems';
export const CONTACT = 'albeasystems@gmail.com';

// The nine languages of the app (Localizable.xcstrings): ar de en es fr hi it pt zh-Hans. Spain first.
export const LANGS = ['es', 'en', 'fr', 'it', 'de', 'pt', 'ar', 'hi', 'zh'];
export const LOCALES = { es: 'es_ES', en: 'en_US', fr: 'fr_FR', it: 'it_IT', de: 'de_DE', pt: 'pt_BR', ar: 'ar_AE', hi: 'hi_IN', zh: 'zh_CN' };
export const INTL = { es: 'es-ES', en: 'en-GB', fr: 'fr-FR', it: 'it-IT', de: 'de-DE', pt: 'pt-BR', ar: 'ar-u-nu-latn', hi: 'hi-IN', zh: 'zh-CN' };
export const HREFLANG = { es: 'es', en: 'en', fr: 'fr', it: 'it', de: 'de', pt: 'pt', ar: 'ar', hi: 'hi', zh: 'zh-Hans' };
export const LANG_NAMES = { es: 'Español', en: 'English', fr: 'Français', it: 'Italiano', de: 'Deutsch', pt: 'Português', ar: 'العربية', hi: 'हिन्दी', zh: '简体中文' };
// Bump UPDATED when copy or figures change: it feeds the visible date, JSON-LD dateModified and the sitemap lastmod.
export const PUBLISHED = '2026-11-09';
export const UPDATED = '2026-11-09';
export const RTL = new Set(['ar']);
/** Tool pages and legal pages exist in Spanish and English only: the rules they explain are Spanish. */
export const TOOL_LANGS = ['es', 'en'];
export const LEGAL_LANGS = ['es', 'en'];

export const url = (route = '') => `${ORIGIN}${BASE}${route}`;
export const href = (route = '') => `${BASE}${route}`;
