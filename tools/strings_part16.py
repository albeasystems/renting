from strings_part15 import S, k, t, n
# Per-room prices at set-up, the room price tied to each tenant, the fianza without autonomous communities
# (en, es, de, fr, it, pt, ar, hi, zh-Hans).

# ================= a room has its own price and utilities contribution =================
n("unit.expenses", "Utilities contribution", "Aportación de gastos", "Nebenkostenbeitrag", "Participation aux charges", "Contributo alle spese", "Contribuição para despesas", "المساهمة في المصروفات", "खर्चों में योगदान", "分摊费用")
n("form.rooms.footer",
  "Each room has its own rent and utilities contribution. They are where the next tenant of that room starts, and every tenant keeps the price they signed.",
  "Cada habitación tiene su propio alquiler y su aportación de gastos. Son el punto de partida del próximo inquilino de esa habitación, y cada inquilino conserva el precio que firmó.",
  "Jedes Zimmer hat seine eigene Miete und seinen eigenen Nebenkostenbeitrag. Sie sind der Ausgangspunkt für den nächsten Mieter des Zimmers; jeder Mieter behält den Preis, den er unterschrieben hat.",
  "Chaque chambre a son propre loyer et sa propre participation aux charges. Ce sont le point de départ du prochain locataire de la chambre, et chaque locataire garde le prix qu'il a signé.",
  "Ogni stanza ha il proprio canone e il proprio contributo alle spese. Sono il punto di partenza del prossimo inquilino della stanza e ogni inquilino conserva il prezzo che ha firmato.",
  "Cada quarto tem a sua própria renda e a sua própria contribuição para despesas. São o ponto de partida do próximo inquilino do quarto, e cada inquilino mantém o preço que assinou.",
  "لكل غرفة إيجارها الخاص ومساهمتها الخاصة في المصروفات. وهي نقطة البداية للمستأجر التالي في الغرفة، ويحتفظ كل مستأجر بالسعر الذي وقّع عليه.",
  "हर कमरे का अपना किराया और खर्चों में अपना योगदान होता है। ये उस कमरे के अगले किरायेदार की शुरुआत हैं, और हर किरायेदार वही कीमत रखता है जिस पर उसने हस्ताक्षर किए।",
  "每个房间都有各自的租金和费用分摊。它们是该房间下一位租客的起点,而每位租客保留自己签约时的价格。")
n("unit.price_note",
  "The room's price is only where the next tenant starts. Each tenant keeps their own rent and utilities, so you can raise or lower it when one leaves.",
  "El precio de la habitación es solo el punto de partida del siguiente inquilino. Cada inquilino conserva su propio alquiler y gastos, así que puedes subirlo o bajarlo cuando uno se va.",
  "Der Zimmerpreis ist nur der Ausgangspunkt für den nächsten Mieter. Jeder Mieter behält seine eigene Miete und Nebenkosten, du kannst den Preis also anpassen, wenn einer auszieht.",
  "Le prix de la chambre n'est que le point de départ du prochain locataire. Chaque locataire garde son propre loyer et ses charges : vous pouvez donc le monter ou le baisser quand l'un d'eux part.",
  "Il prezzo della stanza è solo il punto di partenza del prossimo inquilino. Ogni inquilino mantiene il proprio canone e le proprie utenze, quindi puoi alzarlo o abbassarlo quando uno se ne va.",
  "O preço do quarto é apenas o ponto de partida do próximo inquilino. Cada inquilino mantém a sua própria renda e despesas, por isso pode subi-lo ou baixá-lo quando um sai.",
  "سعر الغرفة هو مجرد نقطة البداية للمستأجر التالي. يحتفظ كل مستأجر بإيجاره ومصروفاته، لذا يمكنك رفعه أو خفضه عندما يغادر أحدهم.",
  "कमरे की कीमत अगले किरायेदार की सिर्फ़ शुरुआत है। हर किरायेदार अपना किराया और खर्च रखता है, इसलिए जब कोई जाए तो आप इसे बढ़ा या घटा सकते हैं।",
  "房间价格只是下一位租客的起点。每位租客保留自己的租金和费用,因此有人搬走时你可以上调或下调。")
# Now shown for whole homes only (the rooms have their own fields).
n("form.units.footer", "You can change the rent and utilities later.", "Puedes cambiar el alquiler y los gastos más adelante.", "Miete und Nebenkosten kannst du später ändern.", "Vous pourrez modifier le loyer et les charges plus tard.", "Potrai cambiare canone e utenze in seguito.", "Pode alterar a renda e as despesas mais tarde.", "يمكنك تغيير الإيجار والمصروفات لاحقًا.", "आप किराया और खर्च बाद में बदल सकते हैं।", "之后可以修改租金和费用。")

# ================= the fianza deadline is a number of days, the same everywhere =================
n("rule.param.filing", "Days after move-in to deposit it", "Días desde la entrada para depositarla", "Tage nach Einzug zur Hinterlegung", "Jours après l'entrée pour la déposer", "Giorni dall'ingresso per depositarla", "Dias após a entrada para a depositar", "عدد الأيام بعد الدخول للإيداع", "प्रवेश के बाद जमा करने के दिन", "入住后多少天内存放")
n("rule.depositFiling.detail",
  "The fianza is not marked as deposited with the authority within the days set after move-in.",
  "La fianza no está marcada como depositada en el organismo dentro de los días fijados desde la entrada.",
  "Die Kaution (fianza) ist innerhalb der nach dem Einzug festgelegten Tage nicht als bei der Behörde hinterlegt markiert.",
  "La caution (fianza) n'est pas marquée comme déposée auprès de l'organisme dans les jours fixés après l'entrée.",
  "La cauzione (fianza) non è segnata come depositata presso l'ente entro i giorni stabiliti dall'ingresso.",
  "A fiança não está marcada como depositada no organismo dentro dos dias definidos após a entrada.",
  "لم يُحدَّد الضمان (fianza) كمودَع لدى الجهة المختصة خلال الأيام المحددة بعد الدخول.",
  "निर्धारित दिनों में जमानत (fianza) को प्राधिकरण में जमा के रूप में चिह्नित नहीं किया गया है।",
  "押金(fianza)未在入住后设定的天数内标记为已存放到主管机构。")

# ================= keys no longer used =================
DROP = [key for key in S if key.startswith(("region.", "dep.dl.", "dep.note."))]
DROP += ["dep.title", "dep.region", "dep.region.none", "dep.region.footer", "dep.amount", "dep.rule", "dep.organism", "dep.deadline_rule",
         "dep.confirm", "dep.not_required_here", "dep.unknown", "dep.signed_on", "dep.custom_deadline", "dep.deadline", "dep.deadline.footer",
         "dep.filed_on", "dep.reference", "dep.footer", "dep.exempt", "dep.exempt.footer", "dep.status.not_required %@", "dep.status.missing",
         "dep.status.nodeadline", "contract.unset", "unit.edit", "form.room_rent", "tenant.home"]
for key in DROP:
    assert key in S, f"not in the catalog: {key}"
    del S[key]
