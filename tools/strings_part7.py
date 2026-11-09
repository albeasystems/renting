from strings_part6 import S, k
# Alert rules engine. Only en + es are translated for now; the other 7 languages fall back to English
# (TODO: translate de fr it pt ar hi zh-Hans). Positional args because L() goes through String(format:).
def k2(key, en, es):
    k(key, en, es, en, en, en, en, en, en, en)

for kind, t_en, t_es, d_en, d_es in [
 ("lateRent","Rent not paid after the due day","Impago tras el día de cobro","Warns when a tenant has not paid by the day you choose, and about partial payments.","Avisa cuando un inquilino no ha pagado el día que elijas, y de los pagos parciales."),
 ("expectedRent","Rent still to come in this month","Cobros que van a entrar este mes","Shows (and notifies on the day you choose) how much rent you still expect this month.","Muestra (y avisa el día que elijas) cuánto alquiler esperas todavía este mes."),
 ("upcomingExpense","Expenses about to fall due","Gastos a punto de vencer","IBI, community, taxes… due this month or next, not paid yet.","IBI, comunidad, tasas… que vencen este mes o el siguiente y siguen sin pagar."),
 ("unpaidExpense","Expenses overdue and unpaid","Gastos vencidos sin pagar","Expenses from the last three months not marked as paid.","Gastos de los últimos tres meses que no has marcado como pagados."),
 ("utilityIncrease","Utility bill much higher","Subida fuerte de consumos","A utility bill well above the average of the previous ones. Record real bills to use it.","Una factura de suministros muy por encima de la media de las anteriores. Anota las facturas reales para usarla."),
 ("suppliesGap","Utilities cost more than you charge","Los consumos cuestan más de lo que cobras","The bills of last month exceed what tenants paid for utilities.","Las facturas del mes pasado superan lo que pagaron los inquilinos por suministros."),
 ("vacancy","Home or room empty for too long","Vivienda o habitación vacía demasiado tiempo","Counts the days since the last tenant left and the rent you are missing.","Cuenta los días desde que se fue el último inquilino y la renta que dejas de ingresar."),
 ("contractEnding","Contract ending","Contrato a punto de acabar","A contract reaching its end date.","Un contrato que llega a su fecha de fin."),
 ("rentUpdate","Annual rent update","Actualización anual de la renta","The contract anniversary is near and the rent has not been updated or kept yet.","Se acerca el aniversario del contrato y la renta no se ha actualizado ni mantenido."),
 ("depositReturn","Deposit to return","Fianza por devolver","A tenant has left and their deposit is still held.","Un inquilino se ha ido y su fianza sigue retenida."),
 ("depositFiling","Fianza deposit deadline","Plazo de depósito de la fianza","The fianza has not been deposited with the regional authority by its deadline.","La fianza no se ha depositado en el organismo autonómico dentro de su plazo."),
]:
    k2("rule." + kind, t_en, t_es)
    k2("rule." + kind + ".detail", d_en, d_es)

k2("rule.unit.day","(day of the month)","(día del mes)")
k2("rule.unit.days","days","días")
k2("rule.param.late_day","Late after day","Impago a partir del día")
k2("rule.param.digest_day","Notify on day","Avisar el día")
k2("rule.param.lead","Notice","Antelación")
k2("rule.param.increase","Increase over average","Subida sobre la media")
k2("rule.param.gap","Bills above what you charge","Facturas por encima de lo cobrado")
k2("rule.param.vacant","Empty for more than","Vacía más de")
k2("rule.param.ending","Notice before the end","Aviso antes del fin")
k2("rule.param.update","Notice before anniversary","Aviso antes del aniversario")
k2("rule.param.filing","Notice before deadline","Aviso antes del plazo")
k2("rule.group.rent","Rent","Cobros")
k2("rule.group.expenses","Expenses and utilities","Gastos y suministros")
k2("rule.group.contracts","Homes, tenants and contracts","Viviendas, inquilinos y contratos")

k2("alert.late_current","%1$@ has not paid yet (after day %2$ld)","%1$@ no ha pagado todavía (pasado el día %2$ld)")
k2("alert.expected","%1$@ still to come in this month (%2$ld payments)","Te faltan por entrar %1$@ este mes (%2$ld cobros)")
k2("alert.expected.detail","Collected %1$@ of %2$@ · counts as late after day %3$ld","Cobrado %1$@ de %2$@ · se considera impago pasado el día %3$ld")
k2("alert.utility_up","%1$@: +%2$ld%% in %3$@","%1$@: +%2$ld %% en %3$@")
k2("alert.utility_up.detail","%1$@ · %2$@ vs %3$@ average","%1$@ · %2$@ frente a %3$@ de media")
k2("alert.supplies_gap","%1$@: utilities cost more than you charge (%2$@)","%1$@: los consumos cuestan más de lo que cobras (%2$@)")
k2("alert.supplies_gap.detail","Charged %1$@ · bills %2$@ · you cover %3$@","Cobrado %1$@ · facturas %2$@ · pones %3$@ de tu bolsillo")
k2("alert.vacant","%1$@ empty for %2$ld days","%1$@ lleva %2$ld días vacía")
k2("alert.vacant.detail","About %1$@ of rent not collected","Unos %1$@ de renta sin ingresar")
k2("notif.late.title","Rent: check who has not paid (after day %1$ld)","Cobros: revisa quién no ha pagado (pasado el día %1$ld)")
k2("notif.late.body","Rent of %1$@","Alquiler de %1$@")
k2("notif.late.body_names","%1$ld unpaid: %2$@","%1$ld sin pagar: %2$@")
k2("notif.expected.title","Rent expected in %1$@","Cobros esperados en %1$@")
k2("notif.expected.body","You expect %1$@ from %2$ld tenants.","Esperas %1$@ de %2$ld inquilinos.")
k2("notif.vacant.title","%1$@ is still empty","%1$@ sigue vacía")
k2("notif.vacant.body","It has been empty for %1$ld days.","Lleva %1$ld días vacía.")
k2("notif.test.title","Test notification","Notificación de prueba")
k2("notif.test.body","Your alerts will arrive like this.","Así te llegarán tus alertas.")
k2("alerts.customize","Customize alerts","Personalizar alertas")
k2("alerts.active_rules %lld %lld","%1$lld of %2$lld on","%1$lld de %2$lld activas")
k2("alerts.group.high","Needs action","Requieren acción")
k2("alerts.group.normal","Coming up","Próximos")
k2("alerts.group.info","For your information","Para tu información")
k2("rules.title","Alert rules","Reglas de alertas")
k2("rules.notifications","Notifications","Notificaciones")
k2("rules.time","Time of day","Hora del aviso")
k2("rules.time.footer","All notifications arrive at this time.","Todas las notificaciones llegan a esta hora.")
k2("rules.master_off","Notifications are off: turn them on in the alerts screen.","Las notificaciones están desactivadas: actívalas en la pantalla de alertas.")
k2("rules.test","Send a test notification","Enviar notificación de prueba")
k2("rules.test.sent","Test sent: it arrives in a few seconds.","Prueba enviada: llega en unos segundos.")
k2("rules.notify","Notify me","Avisarme con notificación")
k2("rules.in_app_only","Shown in the app only","Solo se muestra en la app")
k2("rules.reset","Restore default rules","Restablecer reglas por defecto")
k2("letter.body2","The new rent will be due from %@: not before the contract anniversary and, in any case, from the month after this written notification. It will be paid by the same means as until now. Utilities and other concepts are not affected.","La nueva renta será exigible a partir de %@: no antes del aniversario del contrato y, en todo caso, desde el mes siguiente a esta notificación por escrito. Se abonará por los mismos medios que hasta ahora. Los suministros y demás conceptos no se ven afectados.")
