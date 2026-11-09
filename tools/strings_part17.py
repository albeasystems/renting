from strings_part16 import S, k, t, n
# Texts the app writes into the Collections widget (en, es, de, fr, it, pt, ar, hi, zh-Hans).
# The widget draws them as they are, so they are in the in-app language.

# "of 6,590 €" under the amount collected. Each language keeps the amount to the side it needs.
n("widget.of", "of %1$@", "de %1$@", "von %1$@", "sur %1$@", "su %1$@", "de %1$@", "من %1$@", "%1$@ में से", "共 %1$@")
# "+2 more": tenants who owe something and do not fit in the widget (Arabic has no "+": it would be drawn after the number).
n("widget.more", "+%1$ld more", "+%1$ld más", "+%1$ld weitere", "+%1$ld de plus", "+%1$ld altri", "+%1$ld mais", "%1$ld أخرى", "+%1$ld और", "还有 %1$ld 位")
# The widget still shows last month: it only updates when the app runs.
n("widget.stale", "Open Renting to update", "Abre Renting para actualizar", "Öffne Renting zum Aktualisieren", "Ouvrez Renting pour mettre à jour", "Apri Renting per aggiornare", "Abra o Renting para atualizar", "افتح Renting للتحديث", "अपडेट के लिए Renting खोलें", "打开 Renting 以更新")
n("widget.empty", "Add homes and tenants in Renting to follow your collections", "Añade viviendas e inquilinos en Renting para ver tus cobros", "Füge in Renting Wohnungen und Mieter hinzu, um deine Zahlungen zu sehen", "Ajoutez des logements et des locataires dans Renting pour suivre vos encaissements", "Aggiungi immobili e inquilini in Renting per seguire i tuoi incassi", "Adicione imóveis e inquilinos no Renting para acompanhar as suas cobranças", "أضف عقارات ومستأجرين في Renting لمتابعة تحصيلاتك", "अपनी वसूली देखने के लिए Renting में आवास और किरायेदार जोड़ें", "在 Renting 中添加房产和租客,即可查看收租情况")
