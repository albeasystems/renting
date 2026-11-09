from strings_part18 import S, k, t, n
# The plans: free (3 homes) and the one paid subscription (en, es, de, fr, it, pt, ar, hi, zh-Hans).
# There is no one-time "Pro" any more, so the texts that spoke of Pro now speak of the subscription.

ALL_SAME = ("de", "fr", "it", "pt", "ar", "hi", "zh")

# ================= the paywall =================
n("pro.title", "Renting Cloud", "Renting Cloud", "Renting Cloud", "Renting Cloud", "Renting Cloud", "Renting Cloud", "Renting Cloud", "Renting Cloud", "Renting Cloud", same=ALL_SAME)
n("pro.subtitle",
  "Everything unlocked: unlimited homes, advanced tools for homes, tenants and taxes, no ads and sync across your devices.",
  "Todo desbloqueado: viviendas ilimitadas, herramientas avanzadas para viviendas, inquilinos e impuestos, sin anuncios y sincronización entre tus dispositivos.",
  "Alles freigeschaltet: unbegrenzt viele Wohnungen, erweiterte Werkzeuge für Wohnungen, Mieter und Steuern, keine Werbung und Synchronisierung auf all deinen Geräten.",
  "Tout est débloqué : logements illimités, outils avancés pour les logements, les locataires et les impôts, sans publicité et synchronisation entre vos appareils.",
  "Tutto sbloccato: immobili illimitati, strumenti avanzati per immobili, inquilini e tasse, senza pubblicità e sincronizzazione tra i tuoi dispositivi.",
  "Tudo desbloqueado: imóveis ilimitados, ferramentas avançadas para imóveis, inquilinos e impostos, sem anúncios e sincronização entre os seus dispositivos.",
  "كل شيء مفتوح: عقارات بلا حدود، وأدوات متقدمة للعقارات والمستأجرين والضرائب، بلا إعلانات، ومزامنة بين أجهزتك.",
  "सब कुछ अनलॉक: असीमित आवास, आवास, किरायेदार और कर के लिए उन्नत टूल, विज्ञापन-मुक्त अनुभव और आपके सभी उपकरणों में सिंक।",
  "全部解锁:房产数量不限,房产、租客和税务的高级工具,无广告,并在你的设备间同步。")
n("pro.unlock", "See the plan", "Ver el plan", "Plan ansehen", "Voir l'abonnement", "Vedi il piano", "Ver o plano", "عرض الخطة", "प्लान देखें", "查看方案")
n("pro.footer",
  "Unlimited homes, advanced tools, alerts, no ads and sync with the subscription.",
  "Viviendas ilimitadas, herramientas avanzadas, alertas, sin anuncios y sincronización con la suscripción.",
  "Unbegrenzt viele Wohnungen, erweiterte Werkzeuge, Hinweise, keine Werbung und Synchronisierung mit dem Abo.",
  "Logements illimités, outils avancés, alertes, sans publicité et synchronisation avec l'abonnement.",
  "Immobili illimitati, strumenti avanzati, avvisi, niente pubblicità e sincronizzazione con l'abbonamento.",
  "Imóveis ilimitados, ferramentas avançadas, alertas, sem anúncios e sincronização com a subscrição.",
  "عقارات بلا حدود وأدوات متقدمة وتنبيهات وبلا إعلانات ومزامنة مع الاشتراك.",
  "सदस्यता के साथ असीमित आवास, उन्नत टूल, अलर्ट, विज्ञापन-मुक्त अनुभव और सिंक।",
  "订阅后可享房产数量不限、高级工具、提醒、无广告和同步。")
n("pro.active", "Active", "Activo", "Aktiv", "Actif", "Attivo", "Ativo", "نشط", "सक्रिय", "已启用")

n("pro.f.reports.title", "Advanced tax figures", "Fiscal avanzado", "Erweiterte Steuerzahlen", "Fiscalité avancée", "Fisco avanzato", "Fiscalidade avançada", "أرقام ضريبية متقدمة", "उन्नत कर आँकड़े", "高级税务数据")
n("pro.f.reports.text",
  "Depreciation, reductions per contract, income imputed to empty days, the deductible expenses you choose and the PDF/CSV report for your tax advisor.",
  "Amortización, reducciones por contrato, rentas imputadas por los días vacíos, los gastos deducibles que elijas y el informe PDF/CSV para tu gestor.",
  "Abschreibung, Ermäßigungen je Vertrag, für Leerstandstage angesetzte Einkünfte, die abziehbaren Ausgaben deiner Wahl und der PDF-/CSV-Bericht für deinen Steuerberater.",
  "Amortissement, réductions par bail, revenus imputés aux jours vacants, les dépenses déductibles de votre choix et le rapport PDF/CSV pour votre conseiller fiscal.",
  "Ammortamento, riduzioni per contratto, redditi imputati ai giorni sfitti, le spese deducibili che scegli e il rapporto PDF/CSV per il tuo commercialista.",
  "Depreciação, reduções por contrato, rendimentos imputados aos dias vazios, as despesas dedutíveis que escolher e o relatório PDF/CSV para o seu contabilista.",
  "الإهلاك، والتخفيضات لكل عقد، والدخل المُحتسب لأيام الشغور، والمصروفات القابلة للخصم التي تختارها، وتقرير PDF/CSV لمستشارك الضريبي.",
  "मूल्यह्रास, प्रति अनुबंध छूट, खाली दिनों की आरोपित आय, आपके चुने कटौती-योग्य खर्च और आपके कर सलाहकार के लिए PDF/CSV रिपोर्ट।",
  "折旧、按合同的减免、空置天数的推定收入、由你选择的可抵扣费用,以及供税务顾问使用的 PDF/CSV 报告。")
n("pro.f.ads.text",
  "No banners or full-screen ads while you are subscribed.",
  "Sin banners ni anuncios a pantalla completa mientras estés suscrito.",
  "Keine Banner und keine Vollbildwerbung, solange du abonniert bist.",
  "Ni bannières ni publicités plein écran tant que vous êtes abonné.",
  "Niente banner né pubblicità a schermo intero finché sei abbonato.",
  "Sem banners nem anúncios em ecrã inteiro enquanto estiver subscrito.",
  "بلا لافتات ولا إعلانات بملء الشاشة طالما اشتراكك فعّال.",
  "सदस्यता सक्रिय रहने तक कोई बैनर या फ़ुल-स्क्रीन विज्ञापन नहीं।",
  "订阅期间不显示横幅和全屏广告。")

n("plan.f.homes.title", "Unlimited homes", "Viviendas ilimitadas", "Unbegrenzt viele Wohnungen", "Logements illimités", "Immobili illimitati", "Imóveis ilimitados", "عقارات بلا حدود", "असीमित आवास", "房产数量不限")
n("plan.f.homes.text %lld",
  "The free plan includes up to %lld. With the subscription, as many as you manage.",
  "El plan gratis incluye hasta %lld. Con la suscripción, todas las que gestiones.",
  "Der kostenlose Plan umfasst bis zu %lld. Mit dem Abo so viele, wie du verwaltest.",
  "Le plan gratuit en comprend jusqu'à %lld. Avec l'abonnement, autant que vous en gérez.",
  "Il piano gratuito ne include fino a %lld. Con l'abbonamento, tutti quelli che gestisci.",
  "O plano gratuito inclui até %lld. Com a subscrição, todos os que gerir.",
  "تشمل الخطة المجانية حتى %lld. ومع الاشتراك، بقدر ما تديره.",
  "मुफ़्त प्लान में %lld तक शामिल हैं। सदस्यता के साथ, जितने आप संभालते हैं उतने।",
  "免费方案最多包含 %lld 处。订阅后,你管理多少就能添加多少。")
n("plan.f.homes_adv.title", "Advanced home tools", "Herramientas avanzadas de viviendas", "Erweiterte Wohnungswerkzeuge", "Outils avancés pour les logements", "Strumenti avanzati per gli immobili", "Ferramentas avançadas para imóveis", "أدوات متقدمة للعقارات", "आवासों के लिए उन्नत टूल", "房产高级工具")
n("plan.f.homes_adv.text",
  "Manager or agency with its fee and VAT, construction and cadastral values, own-home flag.",
  "Gestor o agencia con su comisión e IVA, valores de construcción y catastral, vivienda habitual del propietario.",
  "Verwalter oder Agentur mit Gebühr und MwSt., Bau- und Katasterwerte, eigene Wohnung des Eigentümers.",
  "Gestionnaire ou agence avec ses honoraires et la TVA, valeurs de construction et cadastrale, résidence du propriétaire.",
  "Gestore o agenzia con commissione e IVA, valori di costruzione e catastale, abitazione del proprietario.",
  "Gestor ou agência com a sua comissão e IVA, valores de construção e catastral, habitação do proprietário.",
  "المدير أو الوكالة مع عمولته وضريبة القيمة المضافة، وقيمتا البناء والتسجيل العقاري، وإشارة سكن المالك.",
  "प्रबंधक या एजेंसी, उनकी फ़ीस और VAT के साथ, निर्माण और कैडस्ट्रल मूल्य, और मालिक का अपना निवास चिह्न।",
  "管理人或中介及其佣金和增值税、建筑价值与地籍价值、业主自住标记。")
n("plan.f.tenants_adv.title", "Advanced tenant tools", "Herramientas avanzadas de inquilinos", "Erweiterte Mieterwerkzeuge", "Outils avancés pour les locataires", "Strumenti avanzati per gli inquilini", "Ferramentas avançadas para inquilinos", "أدوات متقدمة للمستأجرين", "किरायेदारों के लिए उन्नत टूल", "租客高级工具")
n("plan.f.tenants_adv.text",
  "Contract type and rent insurance, yearly rent update (IRAV/CPI) with its letter, deposit filing, income-tax reduction per contract and rent receipts.",
  "Tipo de contrato y seguro de impago, actualización anual de renta (IRAV/IPC) con su carta, control del depósito de la fianza, reducción del IRPF por contrato y recibos de alquiler.",
  "Vertragsart und Mietausfallversicherung, jährliche Mietanpassung (IRAV/VPI) mit Schreiben, Kautionshinterlegung, Steuerminderung je Vertrag und Mietquittungen.",
  "Type de contrat et assurance loyers impayés, révision annuelle du loyer (IRAV/IPC) avec son courrier, suivi du dépôt de la caution, réduction d'impôt par bail et quittances de loyer.",
  "Tipo di contratto e assicurazione sul mancato pagamento, adeguamento annuale del canone (IRAV/IPC) con la lettera, deposito della cauzione, riduzione fiscale per contratto e ricevute d'affitto.",
  "Tipo de contrato e seguro de incumprimento, atualização anual da renda (IRAV/IPC) com a carta, depósito da caução, redução fiscal por contrato e recibos de aluguel.",
  "نوع العقد وتأمين عدم سداد الإيجار، والتحديث السنوي للإيجار (IRAV/IPC) مع خطابه، ومتابعة إيداع التأمين، والتخفيض الضريبي لكل عقد، وإيصالات الإيجار.",
  "अनुबंध का प्रकार और किराया चूक बीमा, पत्र सहित वार्षिक किराया अद्यतन (IRAV/IPC), जमा राशि का पंजीकरण, प्रति अनुबंध आयकर कटौती और किराया रसीदें।",
  "合同类型与租金违约保险、含函件的年度租金调整(IRAV/IPC)、押金备案、按合同的个税减免,以及租金收据。")

# ================= the free plan's limit =================
n("plan.locked", "Included in the subscription", "Incluido en la suscripción", "Im Abo enthalten", "Inclus dans l'abonnement", "Incluso nell'abbonamento", "Incluído na subscrição", "مشمول في الاشتراك", "सदस्यता में शामिल", "包含在订阅中")
n("plan.homes.reason %lld",
  "The free plan includes up to %lld homes. Subscribe to add as many as you need.",
  "El plan gratis incluye hasta %lld viviendas. Suscríbete para añadir todas las que necesites.",
  "Der kostenlose Plan umfasst bis zu %lld Wohnungen. Abonniere, um beliebig viele hinzuzufügen.",
  "Le plan gratuit comprend jusqu'à %lld logements. Abonnez-vous pour en ajouter autant que nécessaire.",
  "Il piano gratuito include fino a %lld immobili. Abbonati per aggiungerne quanti ti servono.",
  "O plano gratuito inclui até %lld imóveis. Subscreva para adicionar quantos precisar.",
  "تشمل الخطة المجانية حتى %lld عقارات. اشترك لإضافة العدد الذي تحتاجه.",
  "मुफ़्त प्लान में %lld आवास तक शामिल हैं। जितने चाहें जोड़ने के लिए सदस्यता लें।",
  "免费方案最多包含 %lld 处房产。订阅后可按需添加更多。")
n("plan.homes.full %lld",
  "The free plan allows up to %lld homes. Tap to see how to add more.",
  "El plan gratis permite hasta %lld viviendas. Toca para ver cómo añadir más.",
  "Der kostenlose Plan erlaubt bis zu %lld Wohnungen. Tippe, um zu sehen, wie du mehr hinzufügst.",
  "Le plan gratuit permet jusqu'à %lld logements. Touchez pour voir comment en ajouter.",
  "Il piano gratuito consente fino a %lld immobili. Tocca per vedere come aggiungerne altri.",
  "O plano gratuito permite até %lld imóveis. Toque para ver como adicionar mais.",
  "تتيح الخطة المجانية حتى %lld عقارات. اضغط لمعرفة كيفية إضافة المزيد.",
  "मुफ़्त प्लान में अधिकतम %lld आवास की अनुमति है। और जोड़ने का तरीका देखने के लिए टैप करें।",
  "免费方案最多允许 %lld 处房产。点按查看如何添加更多。")

# ================= Fiscal and receipts =================
n("fiscal.net_basic", "Net rent before reductions", "Rendimiento neto antes de reducciones", "Nettoeinkünfte vor Ermäßigungen", "Revenu net avant réductions", "Reddito netto prima delle riduzioni", "Rendimento líquido antes das reduções", "صافي الإيجار قبل التخفيضات", "छूट से पहले शुद्ध किराया आय", "减免前净租金收入")
n("fiscal.adv.title", "Advanced tax figures", "Fiscal avanzado", "Erweiterte Steuerzahlen", "Fiscalité avancée", "Fisco avanzato", "Fiscalidade avançada", "أرقام ضريبية متقدمة", "उन्नत कर आँकड़े", "高级税务数据")
n("fiscal.adv.text",
  "Depreciation, reductions per contract, income imputed to empty days and choosing which expenses are deductible are included in the subscription.",
  "La amortización, las reducciones por contrato, la imputación de rentas por días vacíos y elegir qué gastos son deducibles van incluidas en la suscripción.",
  "Abschreibung, Ermäßigungen je Vertrag, Einkünfte für Leerstandstage und die Wahl der absetzbaren Ausgaben sind im Abo enthalten.",
  "L'amortissement, les réductions par bail, les revenus imputés aux jours vacants et le choix des dépenses déductibles sont inclus dans l'abonnement.",
  "Ammortamento, riduzioni per contratto, redditi imputati ai giorni sfitti e la scelta delle spese deducibili sono inclusi nell'abbonamento.",
  "A depreciação, as reduções por contrato, a imputação de rendimentos por dias vazios e a escolha das despesas dedutíveis estão incluídas na subscrição.",
  "الإهلاك والتخفيضات لكل عقد والدخل المُحتسب لأيام الشغور واختيار المصروفات القابلة للخصم مشمولة في الاشتراك.",
  "मूल्यह्रास, प्रति अनुबंध छूट, खाली दिनों की आरोपित आय और कटौती-योग्य खर्च चुनने की सुविधा सदस्यता में शामिल हैं।",
  "折旧、按合同的减免、空置天数的推定收入,以及选择哪些费用可抵扣,均包含在订阅中。")
n("reports.locked", "The fiscal report is included in the subscription", "El informe fiscal va incluido en la suscripción", "Der Steuerbericht ist im Abo enthalten", "Le rapport fiscal est inclus dans l'abonnement", "Il rapporto fiscale è incluso nell'abbonamento", "O relatório fiscal está incluído na subscrição", "التقرير الضريبي مشمول في الاشتراك", "कर रिपोर्ट सदस्यता में शामिल है", "税务报告包含在订阅中")
n("receipt.locked", "Rent receipts are included in the subscription.", "Los recibos de alquiler van incluidos en la suscripción.", "Mietquittungen sind im Abo enthalten.", "Les quittances de loyer sont incluses dans l'abonnement.", "Le ricevute d'affitto sono incluse nell'abbonamento.", "Os recibos de aluguel estão incluídos na subscrição.", "إيصالات الإيجار مشمولة في الاشتراك.", "किराया रसीदें सदस्यता में शामिल हैं।", "租金收据包含在订阅中。")

# ================= alerts and the subscription screen =================
n("alerts.locked", "Alerts are included in the subscription", "Las alertas van incluidas en la suscripción", "Hinweise sind im Abo enthalten", "Les alertes sont incluses dans l'abonnement", "Gli avvisi sono inclusi nell'abbonamento", "Os alertas estão incluídos na subscrição", "التنبيهات مشمولة في الاشتراك", "अलर्ट सदस्यता में शामिल हैं", "提醒包含在订阅中")
n("alerts.teaser",
  "Overdue rent, expenses coming up, contracts ending and deposits to return — all in one list with the subscription.",
  "Alquileres impagados, gastos que vencen, contratos que terminan y fianzas por devolver, todo en una lista con la suscripción.",
  "Überfällige Mieten, anstehende Ausgaben, auslaufende Verträge und zurückzugebende Kautionen – alles in einer Liste mit dem Abo.",
  "Loyers impayés, dépenses à venir, baux qui se terminent et cautions à rendre, le tout dans une seule liste avec l'abonnement.",
  "Affitti non pagati, spese in arrivo, contratti in scadenza e cauzioni da restituire, tutto in un'unica lista con l'abbonamento.",
  "Rendas em atraso, despesas a vencer, contratos a terminar e cauções a devolver, tudo numa só lista com a subscrição.",
  "إيجارات متأخرة ومصروفات قادمة وعقود تنتهي وتأمينات للإرجاع، كلها في قائمة واحدة مع الاشتراك.",
  "बकाया किराया, आने वाले खर्च, समाप्त होते अनुबंध और लौटाई जाने वाली जमा राशियाँ, सब एक सूची में, सदस्यता के साथ।",
  "逾期租金、即将到期的支出、即将结束的合同和待退押金,订阅后集中在一个列表中。")
n("cloud.active.includes",
  "Your subscription includes unlimited homes, the advanced tools, receipts, alerts and no ads while it is active.",
  "Tu suscripción incluye viviendas ilimitadas, las herramientas avanzadas, recibos, alertas y sin anuncios mientras esté activa.",
  "Dein Abo umfasst unbegrenzt viele Wohnungen, die erweiterten Werkzeuge, Quittungen, Hinweise und keine Werbung, solange es aktiv ist.",
  "Votre abonnement comprend des logements illimités, les outils avancés, les quittances, les alertes et l'absence de publicité tant qu'il est actif.",
  "Il tuo abbonamento include immobili illimitati, gli strumenti avanzati, le ricevute, gli avvisi e nessuna pubblicità finché è attivo.",
  "A sua subscrição inclui imóveis ilimitados, as ferramentas avançadas, recibos, alertas e ausência de anúncios enquanto estiver ativa.",
  "يشمل اشتراكك عقارات بلا حدود والأدوات المتقدمة والإيصالات والتنبيهات وبلا إعلانات طالما هو فعّال.",
  "आपकी सदस्यता सक्रिय रहने तक असीमित आवास, उन्नत टूल, रसीदें, अलर्ट और विज्ञापन-मुक्त अनुभव शामिल करती है।",
  "订阅有效期间包含房产数量不限、高级工具、收据、提醒和无广告。")
n("cloud.active.pro_hint",
  "If you cancel, you go back to the free plan. You keep all your data; the advanced fields keep their values but cannot be edited, and sync stops.",
  "Si cancelas, vuelves al plan gratis. Conservas todos tus datos; los campos avanzados mantienen sus valores pero no se pueden editar, y la sincronización se detiene.",
  "Wenn du kündigst, kehrst du zum kostenlosen Plan zurück. Alle Daten bleiben erhalten; die erweiterten Felder behalten ihre Werte, lassen sich aber nicht mehr bearbeiten, und die Synchronisierung endet.",
  "Si vous résiliez, vous revenez au plan gratuit. Vous gardez toutes vos données ; les champs avancés conservent leurs valeurs mais ne sont plus modifiables, et la synchronisation s'arrête.",
  "Se annulli, torni al piano gratuito. Conservi tutti i dati; i campi avanzati mantengono i valori ma non si possono più modificare, e la sincronizzazione si interrompe.",
  "Se cancelar, volta ao plano gratuito. Mantém todos os dados; os campos avançados conservam os valores mas já não podem ser editados, e a sincronização para.",
  "إذا ألغيت الاشتراك تعود إلى الخطة المجانية. تحتفظ بجميع بياناتك؛ تبقى قيم الحقول المتقدمة كما هي لكن لا يمكن تعديلها، وتتوقف المزامنة.",
  "यदि आप रद्द करते हैं तो मुफ़्त प्लान पर लौट जाते हैं। आपका सारा डेटा सुरक्षित रहता है; उन्नत फ़ील्ड अपने मान रखते हैं पर संपादित नहीं हो सकते, और सिंक रुक जाता है।",
  "取消后将回到免费方案。你的所有数据都会保留;高级字段保留原有数值但不能再编辑,同步也会停止。")
n("settings.test_unlock.cloud", "Test unlock: subscription on", "Desbloqueo de prueba: suscripción activada", "Testfreischaltung: Abo aktiv", "Déblocage de test : abonnement actif", "Sblocco di prova: abbonamento attivo", "Desbloqueio de teste: subscrição ativa", "فتح تجريبي: الاشتراك مفعّل", "टेस्ट अनलॉक: सदस्यता सक्रिय", "测试解锁:订阅已开启")

# ================= the one-time Pro is gone =================
for key in ("cloud.lifetime.note", "cloud.active.lifetime", "cloud.f.pro.title", "cloud.f.pro.text",
            "pro.buy", "pro.buy_price %@", "pro.lifetime.title", "pro.one_time", "pro.or"):
    S.pop(key, None)
