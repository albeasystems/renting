from strings_part14 import S, k, t
from strings_part12 import _shape
# Occupancy history, contract type and rent insurance, contract-end notice (en, es, de, fr, it, pt, ar, hi, zh-Hans).

LANGS = ("en", "es", "de", "fr", "it", "pt", "ar", "hi", "zh")

def n(key, en, es, de, fr, it, pt, ar, hi, zh, same=()):
    """A new or rewritten key: placeholders must match the English text in every language."""
    for lang, text in zip(LANGS, (en, es, de, fr, it, pt, ar, hi, zh)):
        assert text.strip(), f"{key} [{lang}] is empty"
        assert _shape(text) == _shape(en), f"{key} [{lang}] placeholders differ: {_shape(en)} vs {_shape(text)}"
        if lang not in ("en", "es") and text == en:
            assert lang in same, f"{key} [{lang}] is still English"
    k(key, en, es, de, fr, it, pt, ar, hi, zh)

# ================= occupancy history (the (i) of the Summary tab) =================
n("occ.info.title", "Occupancy history", "Historial de ocupación", "Belegungsverlauf", "Historique d'occupation", "Storico occupazione", "Histórico de ocupação", "سجل الإشغال", "अधिभोग का इतिहास", "入住率历史")
n("occ.info.all", "All homes", "Todas las viviendas", "Alle Wohnungen", "Tous les logements", "Tutti gli immobili", "Todos os imóveis", "كل العقارات", "सभी आवास", "所有房产")
n("occ.info.to_date", "%@ (to date)", "%@ (hasta hoy)", "%@ (bis heute)", "%@ (à ce jour)", "%@ (a oggi)", "%@ (até hoje)", "%@ (حتى اليوم)", "%@ (आज तक)", "%@(截至今日)")
n("occ.info.empty_days", "%1$ld days without a tenant", "%1$ld días sin inquilino", "%1$ld Tage ohne Mieter", "%1$ld jours sans locataire", "%1$ld giorni senza inquilino", "%1$ld dias sem inquilino", "%1$ld يومًا بلا مستأجر", "%1$ld दिन बिना किरायेदार", "%1$ld 天无租客")
n("occ.info.rooms", "Rooms", "Habitaciones", "Zimmer", "Chambres", "Stanze", "Quartos", "الغرف", "कमरे", "房间")
n("occ.info.footer",
  "Share of the days with a tenant, per year. Each room counts from the day it first had a tenant, and the current year up to today. Every room weighs the same.",
  "Porcentaje de días con inquilino, por año. Cada habitación cuenta desde el día en que tuvo su primer inquilino, y el año en curso hasta hoy. Todas las habitaciones pesan igual.",
  "Anteil der Tage mit Mieter, pro Jahr. Jedes Zimmer zählt ab dem Tag, an dem es zum ersten Mal einen Mieter hatte, das laufende Jahr bis heute. Alle Zimmer zählen gleich.",
  "Part des jours avec locataire, par année. Chaque chambre compte à partir du jour où elle a eu son premier locataire, et l'année en cours jusqu'à aujourd'hui. Toutes les chambres pèsent autant.",
  "Quota di giorni con inquilino, per anno. Ogni stanza conta dal giorno in cui ha avuto il primo inquilino e l'anno in corso fino a oggi. Tutte le stanze pesano allo stesso modo.",
  "Percentagem de dias com inquilino, por ano. Cada quarto conta a partir do dia em que teve o primeiro inquilino e o ano em curso até hoje. Todos os quartos pesam o mesmo.",
  "نسبة الأيام التي كان فيها مستأجر، لكل سنة. تُحسب كل غرفة من يوم استقبلت فيه أول مستأجر، والسنة الجارية حتى اليوم. وتتساوى الغرف في الوزن.",
  "हर वर्ष में किरायेदार वाले दिनों का अनुपात। प्रत्येक कमरा उस दिन से गिना जाता है जब उसमें पहला किरायेदार आया, और चालू वर्ष आज तक। सभी कमरों का वज़न समान है।",
  "每年有租客的天数占比。每个房间从首次有租客的那天起计算,当年计算到今天。所有房间权重相同。")
n("occ.info.none", "The history appears once a home has had a tenant.", "El historial aparece cuando una vivienda ha tenido algún inquilino.", "Der Verlauf erscheint, sobald eine Wohnung einen Mieter hatte.", "L'historique apparaît dès qu'un logement a eu un locataire.", "Lo storico compare quando un immobile ha avuto un inquilino.", "O histórico aparece quando um imóvel tiver tido um inquilino.", "يظهر السجل بمجرد أن يكون للعقار مستأجر.", "इतिहास तब दिखेगा जब किसी आवास में कोई किरायेदार रहा हो।", "房产有过租客后才会显示历史。")

# ================= type of contract =================
n("contract.title", "Contract", "Contrato", "Vertrag", "Contrat", "Contratto", "Contrato", "العقد", "अनुबंध", "合同")
n("contract.regime", "Legal regime", "Régimen legal", "Rechtsgrundlage", "Régime juridique", "Regime giuridico", "Regime legal", "النظام القانوني", "कानूनी व्यवस्था", "适用法律")
n("contract.regime.lauHousing", "LAU · primary residence", "LAU · vivienda habitual", "LAU · Hauptwohnsitz", "LAU · résidence principale", "LAU · abitazione principale", "LAU · residência permanente", "LAU · سكن دائم", "LAU · स्थायी निवास", "LAU · 常住住房")
n("contract.regime.lauSeasonal", "LAU · seasonal or other use", "LAU · temporada u otro uso", "LAU · Saison- oder andere Nutzung", "LAU · saisonnier ou autre usage", "LAU · stagionale o altro uso", "LAU · sazonal ou outro uso", "LAU · موسمي أو استخدام آخر", "LAU · मौसमी या अन्य उपयोग", "LAU · 季节性或其他用途")
n("contract.regime.civil", "Civil Code", "Código Civil", "Zivilgesetzbuch (Código Civil)", "Code civil (Código Civil)", "Codice civile (Código Civil)", "Código Civil", "القانون المدني (Código Civil)", "सिविल कोड (Código Civil)", "民法典(Código Civil)", same=("pt",))
n("contract.term", "Duration", "Duración", "Laufzeit", "Durée", "Durata", "Duração", "المدة", "अवधि", "期限")
n("contract.term.annual", "Annual (1 year)", "Anual (1 año)", "Jährlich (1 Jahr)", "Annuel (1 an)", "Annuale (1 anno)", "Anual (1 ano)", "سنوي (سنة واحدة)", "वार्षिक (1 वर्ष)", "一年期")
n("contract.term.multiYear", "Several years", "Varios años", "Mehrere Jahre", "Plusieurs années", "Più anni", "Vários anos", "عدة سنوات", "कई वर्ष", "多年")
n("contract.term.shortTerm", "Less than a year", "Menos de un año", "Weniger als ein Jahr", "Moins d'un an", "Meno di un anno", "Menos de um ano", "أقل من سنة", "एक वर्ष से कम", "不足一年")
n("contract.term.monthly", "Month to month", "Mes a mes", "Monatlich kündbar", "Mois par mois", "Mese per mese", "Mês a mês", "شهرًا بشهر", "माह-दर-माह", "按月")
n("contract.insurance", "Rent default insurance", "Seguro de impago", "Mietausfallversicherung", "Assurance loyers impayés", "Assicurazione mancato pagamento", "Seguro de incumprimento da renda", "تأمين عدم سداد الإيجار", "किराया चूक बीमा", "租金违约保险")
n("contract.unset", "Add the contract type", "Indicar el tipo de contrato", "Vertragsart angeben", "Indiquer le type de contrat", "Indica il tipo di contratto", "Indicar o tipo de contrato", "حدّد نوع العقد", "अनुबंध का प्रकार जोड़ें", "填写合同类型")
n("contract.footer",
  "The type decides which rules apply: only a LAU primary-residence lease follows the annual update (IRAV) and the income-tax reduction.",
  "El tipo decide qué reglas se aplican: solo un contrato LAU de vivienda habitual sigue la actualización anual (IRAV) y la reducción del IRPF.",
  "Die Vertragsart entscheidet, welche Regeln gelten: Nur ein LAU-Mietvertrag über den Hauptwohnsitz folgt der jährlichen Anpassung (IRAV) und der Steuerminderung.",
  "Le type détermine les règles applicables : seul un bail LAU de résidence principale suit la révision annuelle (IRAV) et la réduction d'impôt.",
  "Il tipo decide quali regole si applicano: solo un contratto LAU di abitazione principale segue l'adeguamento annuale (IRAV) e la riduzione fiscale.",
  "O tipo decide que regras se aplicam: só um contrato LAU de residência permanente segue a atualização anual (IRAV) e a redução fiscal.",
  "يحدد النوع القواعد المطبَّقة: وحده عقد LAU للسكن الدائم يخضع للتحديث السنوي (IRAV) والتخفيض الضريبي.",
  "प्रकार तय करता है कि कौन-से नियम लागू होंगे: केवल LAU के स्थायी-निवास अनुबंध पर वार्षिक अद्यतन (IRAV) और आयकर कटौती लागू होती है।",
  "合同类型决定适用的规则:只有 LAU 常住住房租约才适用年度调整(IRAV)和个税减免。")
n("common.yes", "Yes", "Sí", "Ja", "Oui", "Sì", "Sim", "نعم", "हाँ", "是")
n("common.no", "No", "No", "Nein", "Non", "No", "Não", "لا", "नहीं", "否", same=("it",))

# ================= rent insurance as an expense =================
n("cat.rentInsurance", "Rent default insurance", "Seguro de impago", "Mietausfallversicherung", "Assurance loyers impayés", "Assicurazione mancato pagamento", "Seguro de incumprimento da renda", "تأمين عدم سداد الإيجار", "किराया चूक बीमा", "租金违约保险")

# ================= contract end =================
n("tenant.ends_in %lld", "Ends in %lld days", "Termina en %lld días", "Endet in %lld Tagen", "Se termine dans %lld jours", "Scade tra %lld giorni", "Termina em %lld dias", "ينتهي بعد %lld يومًا", "%lld दिन में समाप्त", "%lld 天后到期")
n("tenant.contract_expired", "Contract expired", "Contrato vencido", "Vertrag abgelaufen", "Contrat expiré", "Contratto scaduto", "Contrato expirado", "انتهى العقد", "अनुबंध समाप्त हो गया", "合同已到期")
# The notice now says how many days are left (it used to say "30" whatever the rule was).
n("notif.contract.title", "%1$@'s contract ends in %2$ld days", "El contrato de %1$@ termina en %2$ld días", "Der Vertrag von %1$@ endet in %2$ld Tagen", "Le contrat de %1$@ se termine dans %2$ld jours", "Il contratto di %1$@ scade tra %2$ld giorni", "O contrato de %1$@ termina em %2$ld dias", "ينتهي عقد %1$@ بعد %2$ld يومًا", "%1$@ का अनुबंध %2$ld दिन में समाप्त हो रहा है", "%1$@ 的合同将在 %2$ld 天后到期")
