from strings_part9 import S, k
# Summary tab: month / quarter / year periods, the income tiles, the adaptive chart and the quick view.
# Order: en, es, de, fr, it, pt, ar, hi, zh-Hans
# Keys used through L() go through String(format:): positional %1$ld for numbers, %@ for text.

k("period.quarter","Quarter","Trimestre","Quartal","Trimestre","Trimestre","Trimestre","ربع","तिमाही","季度")
k("period.quarter_title","Q%1$ld %2$@","T%1$ld %2$@","Q%1$ld %2$@","T%1$ld %2$@","T%1$ld %2$@","T%1$ld %2$@","الربع %1$ld %2$@","तिमाही %1$ld %2$@","%2$@ 年第 %1$ld 季度")
k("period.q_short","Q%1$ld","T%1$ld","Q%1$ld","T%1$ld","T%1$ld","T%1$ld","ر%1$ld","ति%1$ld","Q%1$ld")
k("dash.net_quarter","Net profit this quarter","Beneficio neto del trimestre","Nettogewinn im Quartal","Bénéfice net du trimestre","Utile netto del trimestre","Lucro líquido do trimestre","صافي الربح هذا الربع","इस तिमाही का शुद्ध लाभ","本季度净利润")
k("dash.net_short","Net","Neto","Netto","Net","Netto","Líquido","الصافي","शुद्ध","净额")
k("dash.income.title","Income","Ingresos","Einnahmen","Revenus","Entrate","Receitas","الإيرادات","आय","收入")
k("dash.income.owed","%@ owed","Debe %@","%@ offen","%@ dû","%@ da incassare","%@ em dívida","%@ مستحق","%@ बकाया","欠 %@")
k("dash.income.rent","Rent %@","Alquiler %@","Miete %@","Loyer %@","Canone %@","Renda %@","الإيجار %@","किराया %@","租金 %@")
k("dash.income.note","Collected = rent + utilities charged to tenants. Quarters start on 1 January: Q1 Jan–Mar, Q2 Apr–Jun, Q3 Jul–Sep, Q4 Oct–Dec.","Cobrado = alquiler + suministros repercutidos. Los trimestres empiezan el 1 de enero: T1 ene–mar, T2 abr–jun, T3 jul–sep, T4 oct–dic.","Eingenommen = Miete + umgelegte Nebenkosten. Quartale beginnen am 1. Januar: Q1 Jan–Mär, Q2 Apr–Jun, Q3 Jul–Sep, Q4 Okt–Dez.","Encaissé = loyer + charges refacturées. Les trimestres commencent le 1er janvier : T1 janv.–mars, T2 avr.–juin, T3 juil.–sept., T4 oct.–déc.","Incassato = canone + utenze addebitate. I trimestri iniziano il 1° gennaio: T1 gen–mar, T2 apr–giu, T3 lug–set, T4 ott–dic.","Recebido = renda + consumos repassados. Os trimestres começam a 1 de janeiro: T1 jan–mar, T2 abr–jun, T3 jul–set, T4 out–dez.","المحصَّل = الإيجار + المرافق المحمّلة. تبدأ الأرباع في 1 يناير: ر1 يناير–مارس، ر2 أبريل–يونيو، ر3 يوليو–سبتمبر، ر4 أكتوبر–ديسمبر.","वसूली = किराया + किरायेदारों से ली गई उपयोगिताएँ। तिमाहियाँ 1 जनवरी से शुरू: ति1 जन–मार्च, ति2 अप्रैल–जून, ति3 जुलाई–सितंबर, ति4 अक्टूबर–दिसंबर।","已收 = 租金 + 向租客收取的水电杂费。季度从 1 月 1 日起算:Q1 1–3 月,Q2 4–6 月,Q3 7–9 月,Q4 10–12 月。")
k("dash.chart.monthly","Monthly","Mensual","Monatlich","Mensuel","Mensile","Mensal","شهري","मासिक","按月")
k("dash.chart.quarterly","Quarterly","Trimestral","Vierteljährlich","Trimestriel","Trimestrale","Trimestral","ربع سنوي","तिमाही","按季度")
k("dash.chart.yearly","Yearly","Anual","Jährlich","Annuel","Annuale","Anual","سنوي","वार्षिक","按年")
k("dash.chart.tap","Tap a bar","Toca una barra","Balken antippen","Touchez une barre","Tocca una barra","Toque numa barra","اضغط على عمود","बार पर टैप करें","轻点柱形")

k("quick.title","Quick view","Vista rápida","Schnellübersicht","Vue rapide","Vista rapida","Vista rápida","نظرة سريعة","त्वरित दृश्य","快速查看")
k("quick.income","Income","Ingresos","Einnahmen","Revenus","Entrate","Receitas","الإيرادات","आय","收入")
k("quick.expenses","Expenses","Gastos","Ausgaben","Dépenses","Spese","Despesas","المصروفات","खर्च","支出")
k("quick.income.empty","No income in this period.","Sin ingresos en este periodo.","Keine Einnahmen in diesem Zeitraum.","Aucun revenu sur cette période.","Nessuna entrata in questo periodo.","Sem receitas neste período.","لا إيرادات في هذه الفترة.","इस अवधि में कोई आय नहीं।","此期间没有收入。")
k("quick.expenses.empty","No expenses in this period.","Sin gastos en este periodo.","Keine Ausgaben in diesem Zeitraum.","Aucune dépense sur cette période.","Nessuna spesa in questo periodo.","Sem despesas neste período.","لا مصروفات في هذه الفترة.","इस अवधि में कोई खर्च नहीं।","此期间没有支出。")
k("quick.owed %@","%@ still owed","%@ pendientes de cobro","%@ noch offen","%@ restent dus","%@ ancora da incassare","%@ por receber","%@ مستحق التحصيل","%@ वसूली बाकी","待收 %@")
k("quick.owes %@","Owes %@","Debe %@","Schuldet %@","Doit %@","Deve %@","Deve %@","عليه %@","बकाया %@","欠 %@")
k("quick.unpaid %@","%@ unpaid","%@ sin pagar","%@ unbezahlt","%@ impayé","%@ non pagato","%@ por pagar","%@ غير مدفوع","%@ अवैतनिक","未付 %@")
k("quick.footer","Income is what tenants paid (rent plus utilities); expenses are what falls due in the period. Red marks what is still owed or unpaid.","Los ingresos son lo que pagaron los inquilinos (alquiler más suministros); los gastos, lo que vence en el periodo. En rojo, lo que aún se debe o está sin pagar.","Einnahmen sind das, was Mieter gezahlt haben (Miete plus Nebenkosten); Ausgaben das, was im Zeitraum fällig wird. Rot markiert Offenes.","Les revenus sont ce que les locataires ont payé (loyer plus charges) ; les dépenses, ce qui arrive à échéance sur la période. En rouge : ce qui reste dû ou impayé.","Le entrate sono ciò che hanno pagato gli inquilini (canone più utenze); le spese, ciò che scade nel periodo. In rosso, ciò che è ancora dovuto o non pagato.","As receitas são o que os inquilinos pagaram (renda mais consumos); as despesas, o que vence no período. A vermelho, o que ainda está em dívida ou por pagar.","الإيرادات هي ما دفعه المستأجرون (الإيجار والمرافق)؛ والمصروفات ما يستحق في الفترة. الأحمر يشير إلى ما لا يزال مستحقًا أو غير مدفوع.","आय वह है जो किरायेदारों ने दिया (किराया और उपयोगिताएँ); खर्च वे हैं जो अवधि में देय हैं। लाल रंग बकाया या अवैतनिक दर्शाता है।","收入为租客已付金额(租金加水电杂费);支出为该期间到期的费用。红色表示仍欠或未付。")

k("dash.to_date %@","To date, through %@ (the period is still running)","A fecha de hoy, hasta %@ (el periodo sigue abierto)","Bisher, bis %@ (der Zeitraum läuft noch)","À ce jour, jusqu'à %@ (la période est en cours)","Finora, fino a %@ (il periodo è ancora in corso)","Até agora, até %@ (o período ainda está em curso)","حتى الآن، حتى %@ (الفترة لا تزال جارية)","अब तक, %@ तक (अवधि अभी चल रही है)","截至目前,至 %@(该期间尚未结束)")

# the summary under the chart now follows the selected period, so it is no longer "yearly"
k("summary.title %@","Income · %@","Ingresos · %@","Einnahmen · %@","Revenus · %@","Entrate · %@","Receitas · %@","الإيرادات · %@","आय · %@","收入 · %@")
