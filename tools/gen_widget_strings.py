"""Writes RentingWidget/Localizable.xcstrings: the name and description the widget gallery shows.

The gallery follows the language of the system (the app's language is not known to a widget
until the app has written its text), so these are the only strings the extension owns.
Order: en, es, de, fr, it, pt, ar, hi, zh-Hans.
"""
import json
import os

langs = ["en", "es", "de", "fr", "it", "pt", "ar", "hi", "zh-Hans"]

W = {
    "widget.name": (
        "Monthly collections", "Cobros del mes", "Zahlungen des Monats", "Encaissements du mois", "Incassi del mese",
        "Cobranças do mês", "تحصيلات الشهر", "इस माह की वसूली", "本月收租"),
    "widget.description": (
        "How much rent has come in this month and who still owes you.",
        "Cuánto alquiler has cobrado este mes y quién te debe todavía.",
        "Wie viel Miete diesen Monat eingegangen ist und wer noch zahlen muss.",
        "Combien de loyers ont été encaissés ce mois-ci et qui vous doit encore.",
        "Quanto affitto hai incassato questo mese e chi ti deve ancora qualcosa.",
        "Quanta renda recebeu este mês e quem ainda lhe deve.",
        "كم إيجارًا حصّلته هذا الشهر ومن لا يزال مدينًا لك.",
        "इस माह कितना किराया आया और किस पर अभी बकाया है।",
        "本月已收多少租金,以及谁还欠款。"),
}

out = {"sourceLanguage": "en", "version": "1.0", "strings": {}}
for key, values in W.items():
    assert len(values) == len(langs), key
    out["strings"][key] = {
        "extractionState": "manual",
        "localizations": {l: {"stringUnit": {"state": "translated", "value": v}} for l, v in zip(langs, values)},
    }

base = os.path.join(os.path.dirname(__file__), "..", "RentingWidget")
os.makedirs(base, exist_ok=True)
with open(os.path.join(base, "Localizable.xcstrings"), "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, indent=2)
print(len(W), "widget keys")
