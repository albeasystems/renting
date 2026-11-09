from strings_part7 import S, k
# KPI explanations on the Summary tab and the actual-bill sheet. Only en + es are translated for now;
# the other 7 languages fall back to English (TODO: de fr it pt ar hi zh-Hans).
def k2(key, en, es):
    k(key, en, es, en, en, en, en, en, en, en)

# ---- actual bill
k2("exp.actual.open","Record the real bill","Anotar la factura real")
k2("exp.planned","Planned","Previsto")
k2("exp.actual","Real bill","Factura real")
k2("exp.actual.vs_plan","Against plan","Frente a lo previsto")
k2("exp.actual.footer","Utilities change every month. Record what the bill really was: the alerts compare it with the previous ones and warn you of big increases.","Los suministros cambian cada mes. Anota lo que costó la factura: las alertas la comparan con las anteriores y te avisan de las subidas fuertes.")
k2("exp.actual.clear","Back to the planned amount","Volver al importe previsto")
k2("exp.actual_delta %@","%@%% vs plan","%@%% sobre lo previsto")

# ---- KPI sheet
k2("kpi.info","How is it calculated?","¿Cómo se calcula?")
k2("kpi.title %@","Your numbers · %@","Tus números · %@")
k2("kpi.how_title","How it is calculated and how to improve it","Cómo se calcula y cómo mejorarlo")
k2("kpi.footer","Charts show the last 12 months up to the month you are viewing. The dashed line marks the average or a healthy goal.","Los gráficos muestran los últimos 12 meses hasta el mes que estás viendo. La línea de puntos marca la media o un objetivo sano.")
k2("kpi.eq.title","How your net profit is made","Cómo se forma tu beneficio neto")
k2("kpi.eq.split %lld %lld","Of every 100 € collected: %1$lld € go to expenses and %2$lld € are left for you.","De cada 100 € que cobras: %1$lld € se van en gastos y te quedan %2$lld €.")
k2("kpi.eq.what","Net profit is a cash figure: what really came in during the month minus what you paid or must pay for the same month.","El beneficio neto es una cifra de caja: lo que realmente ha entrado en el mes menos lo que has pagado o debes pagar de ese mismo mes.")
k2("kpi.eq.rent %@","Rent %@","Alquiler %@")
k2("kpi.eq.supplies %@","Utilities %@","Suministros %@")
k2("kpi.eq.note","It is not the tax result: the Tax tab applies deductible expenses, depreciation, the reduction of each contract and the days a home was empty.","No es el resultado fiscal: la pestaña Fiscal aplica gastos deducibles, amortización, la reducción de cada contrato y los días en que la vivienda estuvo vacía.")

k2("kpi.net.title","Net profit","Beneficio neto")
k2("kpi.net.avg","Average of the last 12 months: %@","Media de los últimos 12 meses: %@")
k2("kpi.net.what","Compare the month with the dashed line: above it, a good month; below it, something changed (a late payment, a one-off repair, an empty room).","Compara el mes con la línea de puntos: por encima, buen mes; por debajo, algo ha cambiado (un impago, una reparación puntual, una habitación vacía).")
k2("kpi.net.how","Net = collected (rent + utilities) − expenses (taxes, community, utilities, insurance, manager fee, repairs…). Annual expenses such as IBI weigh on the month they fall due, so a drop in that month is normal. To raise it: collect on time, fill empty rooms, update the rent every year and review the largest expenses.","Neto = cobrado (alquiler + suministros) − gastos (tasas, comunidad, suministros, seguro, comisión del gestor, reparaciones…). Los gastos anuales como el IBI pesan en el mes en que vencen, así que una caída ese mes es normal. Para subirlo: cobra a tiempo, llena las habitaciones vacías, actualiza la renta cada año y revisa los gastos más grandes.")

k2("kpi.coll.title","Collection rate","Tasa de cobro")
k2("kpi.coll.of","%1$@ collected of %2$@ expected","%1$@ cobrados de %2$@ esperados")
k2("kpi.coll.what","The share of what you should collect that actually arrives. Above 95 % is healthy; if it falls, you are financing your tenants.","La parte de lo que deberías cobrar que realmente llega. Por encima del 95 % es sano; si baja, estás financiando a tus inquilinos.")
k2("kpi.coll.how","Collected ÷ expected in the month (rent + utilities). The current month is still in progress, so it rises as payments arrive. To improve it: remind on day 1, ask for payment by direct debit or transfer and use the alert for rent not paid after the due day.","Cobrado ÷ esperado del mes (alquiler + suministros). El mes en curso aún está abierto, así que sube a medida que entran pagos. Para mejorarla: recuerda el pago el día 1, pide domiciliación o transferencia y usa la alerta de impago tras el día de cobro.")

k2("kpi.occ.title","Occupancy","Ocupación")
k2("kpi.occ.full","Everything is let","Todo está alquilado")
k2("kpi.occ.lost","%1$ld empty · about %2$@ a month not collected","%1$ld vacías · unos %2$@ al mes sin ingresar")
k2("kpi.occ.what","How many of your rooms or homes have a tenant. Every empty room is rent you do not collect but costs and taxes keep running.","Cuántas de tus habitaciones o viviendas tienen inquilino. Cada habitación vacía es renta que no entra mientras los gastos y los impuestos siguen corriendo.")
k2("kpi.occ.how","Rooms or homes with a tenant ÷ total. Empty days also impute income in your tax return. To improve it: advertise before the contract ends, keep the same rent between tenants and use the alert for homes empty too long.","Habitaciones o viviendas con inquilino ÷ total. Los días vacíos además imputan renta en la declaración. Para mejorarla: anuncia antes de que acabe el contrato, mantén la renta entre inquilinos y usa la alerta de vacío prolongado.")

k2("kpi.mix.title","Where the money goes","A dónde va el dinero")
k2("kpi.mix.top","Largest: %1$@ (%2$lld %%)","Mayor: %1$@ (%2$lld %%)")
k2("kpi.mix.none","No expenses this month","Sin gastos este mes")
k2("kpi.mix.what","The expenses of the month by category. A few categories usually take most of it: knowing which ones tells you where saving is possible.","Los gastos del mes por categoría. Unas pocas categorías suelen llevarse la mayor parte: saber cuáles te dice dónde puedes ahorrar.")
k2("kpi.mix.how","Sum of every expense that falls due in the month, including the manager's commission. Fixed costs (IBI, community, insurance) are hard to cut; variable ones (utilities, repairs, cleaning) are where you can act: compare suppliers, record real bills and watch the alert for big increases.","Suma de todos los gastos que vencen en el mes, incluida la comisión del gestor. Los fijos (IBI, comunidad, seguro) son difíciles de recortar; los variables (suministros, reparaciones, limpieza) son donde puedes actuar: compara proveedores, anota las facturas reales y vigila la alerta de subidas.")

k2("kpi.margin.title","Net margin","Margen neto")
k2("kpi.margin.per100","Of every 100 € you collect, %1$ld € are left","De cada 100 € que cobras te quedan %1$ld €")
k2("kpi.margin.what","The share of everything you collect that you keep. It lets you compare months with different rents and see if costs grow faster than income.","La parte de todo lo que cobras que te quedas. Permite comparar meses con rentas distintas y ver si los costes crecen más rápido que los ingresos.")
k2("kpi.margin.how","Net ÷ collected. A margin that falls over several months means expenses are growing faster than your income. To improve it: update the rent, cut recurring expenses and make sure utilities are charged to tenants.","Neto ÷ cobrado. Un margen que baja durante varios meses indica que los gastos crecen más rápido que tus ingresos. Para mejorarlo: actualiza la renta, recorta gastos recurrentes y asegúrate de repercutir los suministros.")

k2("kpi.cov.title","Utilities coverage","Cobertura de suministros")
k2("kpi.cov.of","Tenants paid %1$@ for bills of %2$@","Los inquilinos pagaron %1$@ por facturas de %2$@")
k2("kpi.cov.none","No utility bills this month","Sin facturas de suministros este mes")
k2("kpi.cov.what","Compares what tenants pay for utilities on top of the rent with the electricity, water, gas and internet bills you pay. Below 100 % you are paying part of their consumption.","Compara lo que pagan los inquilinos por suministros además del alquiler con las facturas de luz, agua, gas e internet que pagas tú. Por debajo del 100 % estás pagando parte de su consumo.")
k2("kpi.cov.how","Utilities charged to tenants ÷ utility bills. Record the real bills so the figure is exact. To improve it: raise the flat utilities amount (it does not count for the manager or for tax income) or bill by consumption.","Suministros cobrados a inquilinos ÷ facturas de suministros. Anota las facturas reales para que la cifra sea exacta. Para mejorarla: sube la cantidad fija de suministros (no cuenta para el gestor ni como ingreso fiscal) o factura por consumo.")

# ---- the notifications footer now describes the rules instead of fixed reminders
k("alerts.notifications.footer",
  "Notifications follow your alert rules: choose what to be told about, when and with how much notice in “Customize alerts”.",
  "Las notificaciones siguen tus reglas de alertas: elige de qué avisarte, cuándo y con cuánta antelación en «Personalizar alertas».",
  "Mitteilungen folgen deinen Alarmregeln: Lege unter „Hinweise anpassen“ fest, worüber, wann und mit welchem Vorlauf du informiert wirst.",
  "Les notifications suivent vos règles d'alerte : choisissez de quoi être prévenu, quand et avec quel préavis dans « Personnaliser les alertes ».",
  "Le notifiche seguono le tue regole di avviso: scegli di cosa essere avvisato, quando e con quanto anticipo in «Personalizza avvisi».",
  "As notificações seguem as suas regras de alerta: escolha do que ser avisado, quando e com que antecedência em «Personalizar alertas».",
  "تتبع الإشعارات قواعد التنبيه الخاصة بك: اختر ما تريد أن تُنبَّه إليه ومتى وبأي مهلة في «تخصيص التنبيهات».",
  "सूचनाएँ आपके अलर्ट नियमों का पालन करती हैं: «अलर्ट अनुकूलित करें» में चुनें कि किसकी, कब और कितने पहले सूचना चाहिए।",
  "通知遵循你的提醒规则:在“自定义提醒”中选择提醒内容、时间和提前量。")
