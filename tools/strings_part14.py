from strings_part13 import S, k, t
# KPIs: the info screen behind the monthly net profit on the Summary tab (de, fr, it, pt, ar, hi, zh-Hans).

t("kpi.info", "Wie wird das berechnet?", "Comment est-ce calculé ?", "Come si calcola?", "Como é calculado?", "كيف يُحسب؟", "यह कैसे निकाला जाता है?", "如何计算?")
t("kpi.title %@", "Deine Zahlen · %@", "Vos chiffres · %@", "I tuoi numeri · %@", "Os seus números · %@", "أرقامك · %@", "आपके आँकड़े · %@", "你的数据 · %@")
t("kpi.how_title", "So wird es berechnet und so verbesserst du es", "Comment c'est calculé et comment l'améliorer", "Come si calcola e come migliorarlo", "Como é calculado e como melhorar", "كيف يُحسب وكيف تحسّنه", "यह कैसे निकाला जाता है और इसे कैसे सुधारें", "如何计算以及如何改善")
t("kpi.footer",
  "Die Diagramme zeigen die letzten 12 Monate bis zum angezeigten Monat. Die gestrichelte Linie markiert den Durchschnitt oder ein gesundes Ziel.",
  "Les graphiques montrent les 12 derniers mois jusqu'au mois affiché. La ligne pointillée indique la moyenne ou un objectif sain.",
  "I grafici mostrano gli ultimi 12 mesi fino al mese che stai guardando. La linea tratteggiata indica la media o un obiettivo sano.",
  "Os gráficos mostram os últimos 12 meses até ao mês que está a ver. A linha tracejada marca a média ou um objetivo saudável.",
  "تعرض الرسوم البيانية آخر 12 شهرًا حتى الشهر الذي تشاهده. يشير الخط المتقطع إلى المتوسط أو إلى هدف سليم.",
  "चार्ट आपके देखे जा रहे माह तक के पिछले 12 महीने दिखाते हैं। बिंदीदार रेखा औसत या स्वस्थ लक्ष्य दर्शाती है।",
  "图表显示截至当前所查看月份的最近 12 个月。虚线表示平均值或健康目标。")

# ================= how the net profit is made =================
t("kpi.eq.title", "Wie sich dein Nettogewinn zusammensetzt", "Comment se forme votre bénéfice net", "Come si forma il tuo utile netto", "Como se forma o seu lucro líquido", "كيف يتكوّن صافي ربحك", "आपका शुद्ध लाभ कैसे बनता है", "你的净利润是如何形成的")
t("kpi.eq.split %lld %lld",
  "Von je 100 €, die du einnimmst: %1$lld € gehen für Ausgaben drauf, %2$lld € bleiben dir.",
  "Sur 100 € encaissés : %1$lld € partent en dépenses et %2$lld € vous restent.",
  "Ogni 100 € incassati: %1$lld € se ne vanno in spese e %2$lld € restano a te.",
  "De cada 100 € que recebe: %1$lld € vão para despesas e ficam %2$lld € para si.",
  "من كل 100 € تحصّلها: يذهب %1$lld € إلى المصروفات ويبقى لك %2$lld €.",
  "हर 100 € की वसूली में से: %1$lld € खर्चों में जाते हैं और %2$lld € आपके पास बचते हैं।",
  "每收取 100 €:%1$lld € 用于支出,%2$lld € 留给你。")
t("kpi.eq.what",
  "Der Nettogewinn ist eine Kassengröße: was im Monat tatsächlich eingegangen ist, abzüglich dessen, was du für denselben Monat bezahlt hast oder noch zahlen musst.",
  "Le bénéfice net est un chiffre de trésorerie : ce qui est réellement entré dans le mois moins ce que vous avez payé ou devez payer pour ce même mois.",
  "L'utile netto è una cifra di cassa: ciò che è entrato davvero nel mese meno ciò che hai pagato o devi pagare per lo stesso mese.",
  "O lucro líquido é um valor de caixa: o que realmente entrou no mês menos o que pagou ou tem de pagar nesse mesmo mês.",
  "صافي الربح رقم نقدي: ما دخل فعليًا خلال الشهر ناقص ما دفعته أو يجب أن تدفعه عن الشهر نفسه.",
  "शुद्ध लाभ एक नकद आँकड़ा है: माह में वास्तव में जो आया, उसमें से उसी माह के लिए जो आपने चुकाया या चुकाना है, घटाकर।",
  "净利润是现金口径:当月实际收到的款项,减去你为同一个月已付或应付的费用。")
t("kpi.eq.rent %@", "Miete %@", "Loyer %@", "Canone %@", "Renda %@", "الإيجار %@", "किराया %@", "租金 %@")
t("kpi.eq.supplies %@", "Nebenkosten %@", "Charges %@", "Utenze %@", "Consumos %@", "المرافق %@", "उपयोगिताएँ %@", "水电杂费 %@")
t("kpi.eq.note",
  "Das ist nicht das steuerliche Ergebnis: Der Reiter „Steuern“ berücksichtigt abzugsfähige Ausgaben, Abschreibung, die Minderung jedes Vertrags und die Leerstandstage einer Wohnung.",
  "Ce n'est pas le résultat fiscal : l'onglet Fiscal applique les dépenses déductibles, l'amortissement, la réduction de chaque contrat et les jours où un logement est resté vide.",
  "Non è il risultato fiscale: la scheda Fisco applica le spese deducibili, l'ammortamento, la riduzione di ogni contratto e i giorni in cui un immobile è rimasto sfitto.",
  "Não é o resultado fiscal: o separador Fiscal aplica as despesas dedutíveis, a amortização, a redução de cada contrato e os dias em que um imóvel esteve vazio.",
  "هذه ليست النتيجة الضريبية: يطبّق تبويب الضرائب المصروفات القابلة للخصم والإهلاك وتخفيض كل عقد وأيام بقاء العقار شاغرًا.",
  "यह कर-परिणाम नहीं है: कर टैब कटौती-योग्य खर्च, मूल्यह्रास, प्रत्येक अनुबंध की कटौती और आवास के खाली रहने के दिन लागू करता है।",
  "这不是税务结果:「税务」标签页会计入可抵扣支出、折旧、每份合同的减免,以及房产空置的天数。")

# ================= net profit =================
t("kpi.net.title", "Nettogewinn", "Bénéfice net", "Utile netto", "Lucro líquido", "صافي الربح", "शुद्ध लाभ", "净利润")
t("kpi.net.avg", "Durchschnitt der letzten 12 Monate: %@", "Moyenne des 12 derniers mois : %@", "Media degli ultimi 12 mesi: %@", "Média dos últimos 12 meses: %@", "متوسط آخر 12 شهرًا: %@", "पिछले 12 महीनों का औसत: %@", "最近 12 个月平均:%@")
t("kpi.net.what",
  "Vergleiche den Monat mit der gestrichelten Linie: darüber ein guter Monat, darunter hat sich etwas geändert (eine verspätete Zahlung, eine einmalige Reparatur, ein leeres Zimmer).",
  "Comparez le mois à la ligne pointillée : au-dessus, un bon mois ; en dessous, quelque chose a changé (un retard de paiement, une réparation ponctuelle, une chambre vide).",
  "Confronta il mese con la linea tratteggiata: sopra, un buon mese; sotto, qualcosa è cambiato (un ritardo nel pagamento, una riparazione una tantum, una stanza sfitta).",
  "Compare o mês com a linha tracejada: acima, um bom mês; abaixo, algo mudou (um atraso no pagamento, uma reparação pontual, um quarto vazio).",
  "قارن الشهر بالخط المتقطع: فوقه شهر جيد، وتحته تغيّر شيء ما (دفعة متأخرة، إصلاح لمرة واحدة، غرفة شاغرة).",
  "महीने की तुलना बिंदीदार रेखा से करें: उसके ऊपर अच्छा महीना; नीचे कुछ बदला है (देर से भुगतान, एक बार की मरम्मत, खाली कमरा)।",
  "把当月与虚线比较:高于虚线是好月份;低于虚线说明有变化(延迟付款、一次性维修、空置房间)。")
t("kpi.net.how",
  "Netto = eingenommen (Miete + Nebenkosten) − Ausgaben (Steuern, Hausgeld, Nebenkosten, Versicherung, Verwaltergebühr, Reparaturen …). Jährliche Ausgaben wie die IBI belasten den Monat, in dem sie fällig werden; ein Einbruch in diesem Monat ist also normal. So steigerst du es: pünktlich einkassieren, leere Zimmer vermieten, die Miete jedes Jahr anpassen und die größten Ausgaben überprüfen.",
  "Net = encaissé (loyer + charges) − dépenses (impôts, copropriété, charges, assurance, commission du gestionnaire, réparations…). Les dépenses annuelles comme l'IBI pèsent sur le mois de leur échéance : une baisse ce mois-là est donc normale. Pour l'augmenter : encaissez à temps, remplissez les chambres vides, révisez le loyer chaque année et examinez les plus grosses dépenses.",
  "Netto = incassato (canone + utenze) − spese (tasse, condominio, utenze, assicurazione, commissione del gestore, riparazioni…). Le spese annuali come l'IBI pesano sul mese di scadenza, quindi un calo in quel mese è normale. Per aumentarlo: incassa puntualmente, affitta le stanze vuote, aggiorna il canone ogni anno e rivedi le spese maggiori.",
  "Líquido = recebido (renda + consumos) − despesas (impostos, condomínio, consumos, seguro, comissão do gestor, reparações…). As despesas anuais, como o IBI, pesam no mês em que vencem, por isso uma queda nesse mês é normal. Para o aumentar: receba a tempo, ocupe os quartos vazios, atualize a renda todos os anos e reveja as maiores despesas.",
  "الصافي = المحصَّل (الإيجار + المرافق) − المصروفات (الضرائب، رسوم المجتمع، المرافق، التأمين، عمولة المدير، الإصلاحات…). تؤثر المصروفات السنوية مثل IBI في الشهر الذي تستحق فيه، لذا فالانخفاض في ذلك الشهر طبيعي. لرفعه: حصّل في الموعد، وأشغل الغرف الشاغرة، وحدّث الإيجار كل سنة، وراجع أكبر المصروفات.",
  "शुद्ध = वसूला (किराया + उपयोगिताएँ) − खर्च (कर, सोसायटी शुल्क, उपयोगिताएँ, बीमा, प्रबंधक शुल्क, मरम्मत…)। IBI जैसे वार्षिक खर्च उसी माह पर भार डालते हैं जब वे देय होते हैं, इसलिए उस माह में गिरावट सामान्य है। इसे बढ़ाने के लिए: समय पर वसूली करें, खाली कमरे भरें, हर साल किराया अद्यतन करें और सबसे बड़े खर्चों की समीक्षा करें।",
  "净额 = 已收(租金 + 水电杂费)− 支出(税费、物业费、水电杂费、保险、管理人佣金、维修等)。IBI 等年度支出会压在到期当月,因此该月下降属正常。提升方法:按时收款、租出空置房间、每年调整租金、复查最大的几项支出。")

# ================= collection rate =================
t("kpi.coll.title", "Zahlungsquote", "Taux d'encaissement", "Tasso di incasso", "Taxa de cobrança", "نسبة التحصيل", "वसूली दर", "收款率")
t("kpi.coll.of", "%1$@ eingenommen von %2$@ erwartet", "%1$@ encaissés sur %2$@ attendus", "%1$@ incassati su %2$@ attesi", "%1$@ recebidos de %2$@ esperados", "تم تحصيل %1$@ من %2$@ المتوقعة", "अपेक्षित %2$@ में से %1$@ वसूले", "已收 %1$@ / 预计 %2$@")
t("kpi.coll.what",
  "Der Anteil dessen, was du einnehmen solltest, der tatsächlich ankommt. Über 95 % ist gesund; fällt er, finanzierst du deine Mieter.",
  "La part de ce que vous devriez encaisser qui arrive réellement. Au-dessus de 95 %, c'est sain ; si elle baisse, vous financez vos locataires.",
  "La quota di ciò che dovresti incassare che arriva davvero. Sopra il 95 % è sano; se scende, stai finanziando i tuoi inquilini.",
  "A parte do que deveria receber que realmente chega. Acima de 95 % é saudável; se baixar, está a financiar os seus inquilinos.",
  "نسبة ما يجب أن تحصّله وقد وصلك فعلًا. فوق 95 % يعدّ وضعًا سليمًا؛ وإن انخفضت فأنت تموّل مستأجريك.",
  "जो आपको वसूलना चाहिए उसमें से कितना सचमुच आता है। 95 % से ऊपर स्वस्थ है; गिरे तो आप अपने किरायेदारों को वित्तपोषित कर रहे हैं।",
  "应收款项中实际到账的比例。高于 95 % 属健康;低于此值,说明你在为租客垫资。")
t("kpi.coll.how",
  "Eingenommen ÷ erwartet im Monat (Miete + Nebenkosten). Der laufende Monat ist noch nicht abgeschlossen, daher steigt der Wert mit jeder eingehenden Zahlung. So verbesserst du ihn: am 1. erinnern, Lastschrift oder Überweisung verlangen und den Hinweis für nach dem Fälligkeitstag unbezahlte Miete nutzen.",
  "Encaissé ÷ attendu du mois (loyer + charges). Le mois en cours n'est pas terminé, il augmente donc à mesure que les paiements arrivent. Pour l'améliorer : relancez le 1er, demandez un prélèvement ou un virement et utilisez l'alerte de loyer impayé après la date d'échéance.",
  "Incassato ÷ atteso nel mese (canone + utenze). Il mese in corso è ancora aperto, quindi sale man mano che arrivano i pagamenti. Per migliorarlo: ricorda il pagamento il giorno 1, chiedi addebito diretto o bonifico e usa l'avviso di canone non pagato dopo la scadenza.",
  "Recebido ÷ esperado no mês (renda + consumos). O mês em curso ainda está aberto, por isso sobe à medida que os pagamentos chegam. Para a melhorar: lembre o pagamento no dia 1, peça débito direto ou transferência e use o alerta de renda por pagar após o dia de vencimento.",
  "المحصَّل ÷ المتوقع في الشهر (الإيجار + المرافق). الشهر الجاري لا يزال مفتوحًا، لذا ترتفع النسبة مع وصول الدفعات. لتحسينها: ذكّر بالدفع في اليوم الأول، واطلب الخصم المباشر أو التحويل، واستخدم تنبيه الإيجار غير المدفوع بعد يوم الاستحقاق.",
  "माह में वसूला ÷ अपेक्षित (किराया + उपयोगिताएँ)। चालू माह अभी खुला है, इसलिए भुगतान आने के साथ यह बढ़ता है। इसे सुधारने के लिए: 1 तारीख को याद दिलाएँ, डायरेक्ट डेबिट या ट्रांसफ़र से भुगतान माँगें और देय दिन के बाद अवैतनिक किराये वाले अलर्ट का उपयोग करें।",
  "当月已收 ÷ 应收(租金 + 水电杂费)。当月尚未结束,随着款项到账该比例会上升。改善方法:1 号提醒、要求自动扣款或转账,并使用「过了到期日仍未付租金」提醒。")

# ================= occupancy =================
t("kpi.occ.title", "Belegung", "Occupation", "Occupazione", "Ocupação", "الإشغال", "अधिभोग", "入住率")
t("kpi.occ.full", "Alles ist vermietet", "Tout est loué", "È tutto affittato", "Está tudo arrendado", "كل شيء مؤجَّر", "सब कुछ किराए पर है", "全部已出租")
t("kpi.occ.lost", "%1$ld leer · rund %2$@ im Monat nicht eingenommen", "%1$ld vides · environ %2$@ par mois non encaissés", "%1$ld sfitti · circa %2$@ al mese non incassati", "%1$ld vazios · cerca de %2$@ por mês sem receber", "%1$ld شاغرة · نحو %2$@ شهريًا غير محصَّلة", "%1$ld खाली · हर माह लगभग %2$@ वसूल नहीं हो रहा", "%1$ld 个空置 · 每月约 %2$@ 未收")
t("kpi.occ.what",
  "Wie viele deiner Zimmer oder Wohnungen einen Mieter haben. Jedes leere Zimmer ist Miete, die du nicht erhältst, während Kosten und Steuern weiterlaufen.",
  "Combien de vos chambres ou logements ont un locataire. Chaque chambre vide est un loyer que vous n'encaissez pas, alors que les frais et les impôts continuent de courir.",
  "Quante delle tue stanze o dei tuoi immobili hanno un inquilino. Ogni stanza sfitta è un canone che non incassi, mentre spese e tasse continuano a correre.",
  "Quantos dos seus quartos ou imóveis têm inquilino. Cada quarto vazio é renda que não recebe, enquanto os custos e os impostos continuam a correr.",
  "كم من غرفك أو عقاراتك فيها مستأجر. كل غرفة شاغرة إيجار لا تحصّله بينما تستمر التكاليف والضرائب.",
  "आपके कितने कमरों या आवासों में किरायेदार है। हर खाली कमरा वह किराया है जो आपको नहीं मिलता, जबकि लागत और कर चलते रहते हैं।",
  "你的房间或房产中有多少已有租客。每个空置房间都是收不到的租金,而成本和税费仍在继续。")
t("kpi.occ.how",
  "Zimmer oder Wohnungen mit Mieter ÷ Gesamtzahl. Leerstandstage führen in der Steuererklärung außerdem zu fiktiven Einkünften. So verbesserst du es: vor Vertragsende inserieren, die Miete zwischen Mietern gleich halten und den Hinweis für zu lange leere Wohnungen nutzen.",
  "Chambres ou logements avec locataire ÷ total. Les jours de vacance imputent aussi un revenu dans votre déclaration. Pour l'améliorer : annoncez avant la fin du contrat, gardez le même loyer entre deux locataires et utilisez l'alerte de vacance prolongée.",
  "Stanze o immobili con inquilino ÷ totale. I giorni di sfitto imputano inoltre un reddito nella dichiarazione. Per migliorarla: pubblica l'annuncio prima della fine del contratto, mantieni lo stesso canone tra un inquilino e l'altro e usa l'avviso per immobili sfitti da troppo tempo.",
  "Quartos ou imóveis com inquilino ÷ total. Os dias vazios também imputam rendimento na declaração. Para a melhorar: anuncie antes de o contrato terminar, mantenha a mesma renda entre inquilinos e use o alerta de imóvel vazio há demasiado tempo.",
  "الغرف أو العقارات المؤجَّرة ÷ الإجمالي. كما تُحتسب أيام الشغور دخلًا افتراضيًا في إقرارك الضريبي. لتحسينها: أعلن قبل انتهاء العقد، وأبقِ الإيجار نفسه بين المستأجرين، واستخدم تنبيه العقارات الشاغرة لفترة طويلة.",
  "किरायेदार वाले कमरे या आवास ÷ कुल। खाली दिनों पर आपके कर रिटर्न में आरोपित आय भी जुड़ती है। इसे सुधारने के लिए: अनुबंध खत्म होने से पहले विज्ञापन दें, किरायेदारों के बीच वही किराया रखें और बहुत समय से खाली आवासों वाले अलर्ट का उपयोग करें।",
  "有租客的房间或房产 ÷ 总数。空置天数还会在纳税申报中被视同收入。改善方法:合同到期前就发布招租广告,更换租客时保持原租金,并使用「房产或房间空置过久」提醒。")

# ================= where the money goes =================
t("kpi.mix.title", "Wohin das Geld fließt", "Où va l'argent", "Dove vanno i soldi", "Para onde vai o dinheiro", "أين يذهب المال", "पैसा कहाँ जाता है", "钱花在哪里")
t("kpi.mix.top", "Größte: %1$@ (%2$lld %%)", "Plus grande : %1$@ (%2$lld %%)", "Maggiore: %1$@ (%2$lld %%)", "Maior: %1$@ (%2$lld %%)", "الأكبر: %1$@ (%2$lld %%)", "सबसे बड़ा: %1$@ (%2$lld %%)", "最大项:%1$@(%2$lld %%)")
t("kpi.mix.none", "Keine Ausgaben in diesem Monat", "Aucune dépense ce mois-ci", "Nessuna spesa questo mese", "Sem despesas este mês", "لا مصروفات هذا الشهر", "इस माह कोई खर्च नहीं", "本月无支出")
t("kpi.mix.what",
  "Die Ausgaben des Monats nach Kategorie. Wenige Kategorien machen meist den Großteil aus: Wenn du weißt, welche, siehst du, wo du sparen kannst.",
  "Les dépenses du mois par catégorie. Quelques catégories en représentent généralement l'essentiel : savoir lesquelles vous indique où économiser.",
  "Le spese del mese per categoria. Poche categorie di solito pesano per la maggior parte: sapere quali ti dice dove puoi risparmiare.",
  "As despesas do mês por categoria. Algumas categorias costumam levar a maior parte: saber quais indica onde pode poupar.",
  "مصروفات الشهر حسب الفئة. تستحوذ عادةً بضع فئات على معظمها؛ ومعرفتها تدلّك على مواضع التوفير.",
  "माह के खर्च श्रेणी के अनुसार। आमतौर पर कुछ ही श्रेणियाँ अधिकांश हिस्सा लेती हैं: उन्हें जानने से पता चलता है कि बचत कहाँ संभव है।",
  "按类别列出的当月支出。通常少数几类占了大部分:知道是哪几类,就知道哪里能省。")
t("kpi.mix.how",
  "Summe aller im Monat fälligen Ausgaben, einschließlich der Verwalterprovision. Fixkosten (IBI, Hausgeld, Versicherung) lassen sich kaum senken; bei variablen (Nebenkosten, Reparaturen, Reinigung) kannst du ansetzen: Anbieter vergleichen, echte Rechnungen erfassen und den Hinweis auf starke Anstiege beachten.",
  "Somme de toutes les dépenses échues dans le mois, y compris la commission du gestionnaire. Les coûts fixes (IBI, copropriété, assurance) sont difficiles à réduire ; c'est sur les variables (charges, réparations, ménage) que vous pouvez agir : comparez les fournisseurs, saisissez les vraies factures et surveillez l'alerte de fortes hausses.",
  "Somma di tutte le spese in scadenza nel mese, inclusa la commissione del gestore. I costi fissi (IBI, condominio, assicurazione) sono difficili da tagliare; sui variabili (utenze, riparazioni, pulizie) puoi intervenire: confronta i fornitori, registra le bollette reali e tieni d'occhio l'avviso sui rincari forti.",
  "Soma de todas as despesas que vencem no mês, incluindo a comissão do gestor. Os custos fixos (IBI, condomínio, seguro) são difíceis de cortar; nos variáveis (consumos, reparações, limpeza) pode agir: compare fornecedores, registe as faturas reais e acompanhe o alerta de subidas fortes.",
  "مجموع كل المصروفات المستحقة في الشهر، بما فيها عمولة المدير. يصعب تقليص التكاليف الثابتة (IBI، رسوم المجتمع، التأمين)؛ أما المتغيرة (المرافق، الإصلاحات، التنظيف) فهي ما يمكنك التحكم فيه: قارن الموردين، وسجّل الفواتير الفعلية، وتابع تنبيه الزيادات الكبيرة.",
  "माह में देय सभी खर्चों का योग, प्रबंधक का कमीशन सहित। स्थिर लागतें (IBI, सोसायटी शुल्क, बीमा) घटाना कठिन है; परिवर्तनीय (उपयोगिताएँ, मरम्मत, सफ़ाई) में आप कुछ कर सकते हैं: आपूर्तिकर्ताओं की तुलना करें, असली बिल दर्ज करें और बड़ी वृद्धि वाले अलर्ट पर नज़र रखें।",
  "当月到期的所有支出之和,包括管理人佣金。固定成本(IBI、物业费、保险)很难削减;可变成本(水电杂费、维修、清洁)才是你能下手的地方:比较供应商、录入真实账单,并留意大幅上涨提醒。")

# ================= net margin =================
t("kpi.margin.title", "Nettomarge", "Marge nette", "Margine netto", "Margem líquida", "هامش الربح الصافي", "शुद्ध मार्जिन", "净利率")
t("kpi.margin.per100", "Von je 100 €, die du einnimmst, bleiben dir %1$ld €", "Sur 100 € encaissés, il vous reste %1$ld €", "Ogni 100 € che incassi, te ne restano %1$ld €", "De cada 100 € que recebe, ficam-lhe %1$ld €", "من كل 100 € تحصّلها يبقى لك %1$ld €", "हर 100 € की वसूली में से आपके पास %1$ld € बचते हैं", "每收取 100 €,你能留下 %1$ld €")
t("kpi.margin.what",
  "Der Anteil an allem Eingenommenen, der dir bleibt. So kannst du Monate mit unterschiedlichen Mieten vergleichen und sehen, ob die Kosten schneller wachsen als die Einnahmen.",
  "La part de tout ce que vous encaissez que vous conservez. Elle permet de comparer des mois aux loyers différents et de voir si les coûts augmentent plus vite que les revenus.",
  "La quota di tutto ciò che incassi che ti resta. Permette di confrontare mesi con canoni diversi e di vedere se i costi crescono più in fretta dei ricavi.",
  "A parte de tudo o que recebe que fica consigo. Permite comparar meses com rendas diferentes e ver se os custos crescem mais depressa do que os rendimentos.",
  "نسبة ما تحتفظ به من كل ما تحصّله. تتيح مقارنة أشهر ذات إيجارات مختلفة ومعرفة ما إذا كانت التكاليف تنمو أسرع من الدخل.",
  "आप जो कुछ वसूलते हैं उसमें से जितना आपके पास रहता है, उसका अनुपात। इससे अलग-अलग किराए वाले महीनों की तुलना होती है और दिखता है कि लागत आय से तेज़ बढ़ रही है या नहीं।",
  "你所收款项中最终留下的比例。可用来比较租金不同的月份,并判断成本增长是否快于收入。")
t("kpi.margin.how",
  "Netto ÷ eingenommen. Sinkt die Marge über mehrere Monate, wachsen die Ausgaben schneller als deine Einnahmen. So verbesserst du sie: Miete anpassen, laufende Ausgaben senken und dafür sorgen, dass Nebenkosten an die Mieter weitergegeben werden.",
  "Net ÷ encaissé. Une marge qui baisse pendant plusieurs mois signifie que les dépenses augmentent plus vite que vos revenus. Pour l'améliorer : révisez le loyer, réduisez les dépenses récurrentes et veillez à répercuter les charges sur les locataires.",
  "Netto ÷ incassato. Un margine che scende per più mesi indica che le spese crescono più in fretta delle entrate. Per migliorarlo: aggiorna il canone, riduci le spese ricorrenti e assicurati di addebitare le utenze agli inquilini.",
  "Líquido ÷ recebido. Uma margem que desce durante vários meses indica que as despesas crescem mais depressa do que os seus rendimentos. Para a melhorar: atualize a renda, corte as despesas recorrentes e garanta que os consumos são cobrados aos inquilinos.",
  "الصافي ÷ المحصَّل. هبوط الهامش على مدى عدة أشهر يعني أن المصروفات تنمو أسرع من دخلك. لتحسينه: حدّث الإيجار، وقلّص المصروفات المتكررة، وتأكد من تحميل المرافق على المستأجرين.",
  "शुद्ध ÷ वसूला। कई महीनों तक मार्जिन गिरना बताता है कि खर्च आपकी आय से तेज़ बढ़ रहे हैं। इसे सुधारने के लिए: किराया अद्यतन करें, आवर्ती खर्च घटाएँ और सुनिश्चित करें कि उपयोगिताएँ किरायेदारों से वसूली जा रही हैं।",
  "净额 ÷ 已收。利润率连续数月下降,说明支出增长快于收入。改善方法:调整租金、削减经常性支出,并确保水电杂费已向租客收取。")

# ================= utilities coverage =================
t("kpi.cov.title", "Nebenkostendeckung", "Couverture des charges", "Copertura delle utenze", "Cobertura de consumos", "تغطية المرافق", "उपयोगिता कवरेज", "水电杂费覆盖率")
t("kpi.cov.of", "Mieter zahlten %1$@ für Rechnungen über %2$@", "Les locataires ont payé %1$@ pour des factures de %2$@", "Gli inquilini hanno pagato %1$@ per bollette da %2$@", "Os inquilinos pagaram %1$@ por faturas de %2$@", "دفع المستأجرون %1$@ مقابل فواتير بقيمة %2$@", "किरायेदारों ने %2$@ के बिलों के लिए %1$@ चुकाए", "租客为 %2$@ 的账单支付了 %1$@")
t("kpi.cov.none", "Keine Nebenkostenrechnungen in diesem Monat", "Aucune facture de charges ce mois-ci", "Nessuna bolletta delle utenze questo mese", "Sem faturas de consumos este mês", "لا فواتير مرافق هذا الشهر", "इस माह कोई उपयोगिता बिल नहीं", "本月无水电杂费账单")
t("kpi.cov.what",
  "Vergleicht, was Mieter zusätzlich zur Miete für Nebenkosten zahlen, mit den Strom-, Wasser-, Gas- und Internetrechnungen, die du bezahlst. Unter 100 % zahlst du einen Teil ihres Verbrauchs.",
  "Compare ce que les locataires paient pour les charges en plus du loyer avec les factures d'électricité, d'eau, de gaz et d'internet que vous réglez. En dessous de 100 %, vous payez une partie de leur consommation.",
  "Confronta ciò che gli inquilini pagano per le utenze oltre al canone con le bollette di luce, acqua, gas e internet che paghi tu. Sotto il 100 % stai pagando una parte dei loro consumi.",
  "Compara o que os inquilinos pagam por consumos além da renda com as faturas de luz, água, gás e internet que paga. Abaixo de 100 % está a pagar parte do consumo deles.",
  "تقارن ما يدفعه المستأجرون للمرافق فوق الإيجار بفواتير الكهرباء والماء والغاز والإنترنت التي تدفعها أنت. إن كانت أقل من 100 % فأنت تدفع جزءًا من استهلاكهم.",
  "किराये के अलावा किरायेदार उपयोगिताओं के लिए जो देते हैं, उसकी तुलना उन बिजली, पानी, गैस और इंटरनेट बिलों से करता है जो आप भरते हैं। 100 % से कम होने पर आप उनके उपभोग का एक हिस्सा चुका रहे हैं।",
  "把租客在租金之外为水电杂费支付的金额,与你支付的电、水、燃气和网络账单作比较。低于 100 % 说明你在替他们承担部分用量。")
t("kpi.cov.how",
  "An Mieter berechnete Nebenkosten ÷ Nebenkostenrechnungen. Erfasse die echten Rechnungen, damit der Wert genau ist. So verbesserst du ihn: die Nebenkostenpauschale erhöhen (sie zählt weder für den Verwalter noch als steuerpflichtiges Einkommen) oder nach Verbrauch abrechnen.",
  "Charges facturées aux locataires ÷ factures de charges. Saisissez les vraies factures pour que le chiffre soit exact. Pour l'améliorer : augmentez le forfait de charges (il ne compte ni pour le gestionnaire ni comme revenu fiscal) ou facturez à la consommation.",
  "Utenze addebitate agli inquilini ÷ bollette delle utenze. Registra le bollette reali perché la cifra sia esatta. Per migliorarla: aumenta l'importo forfettario delle utenze (non conta per il gestore né come reddito fiscale) oppure addebita in base ai consumi.",
  "Consumos cobrados aos inquilinos ÷ faturas de consumos. Registe as faturas reais para que o valor seja exato. Para a melhorar: aumente o valor fixo dos consumos (não conta para o gestor nem como rendimento fiscal) ou cobre por consumo.",
  "المرافق المحمَّلة على المستأجرين ÷ فواتير المرافق. سجّل الفواتير الفعلية ليكون الرقم دقيقًا. لتحسينها: ارفع المبلغ الثابت للمرافق (فهو لا يُحتسب للمدير ولا كدخل ضريبي) أو حاسب بحسب الاستهلاك.",
  "किरायेदारों से वसूली उपयोगिताएँ ÷ उपयोगिता बिल। आँकड़ा सटीक रहे, इसके लिए असली बिल दर्ज करें। इसे सुधारने के लिए: उपयोगिताओं की निश्चित राशि बढ़ाएँ (यह न प्रबंधक के लिए गिनी जाती है, न कर-योग्य आय के रूप में) या उपभोग के आधार पर बिल बनाएँ।",
  "向租客收取的水电杂费 ÷ 水电杂费账单。录入真实账单,数字才准确。改善方法:提高水电杂费的固定金额(它不计入管理人佣金基数,也不算应税收入),或按实际用量收费。")
