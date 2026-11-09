import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from strings_part19 import S
langs = ["en","es","de","fr","it","pt","ar","hi","zh-Hans"]
out = {"sourceLanguage":"en","version":"1.0","strings":{}}
for key, vals in S.items():
    out["strings"][key] = {"extractionState":"manual","localizations":{l:{"stringUnit":{"state":"translated","value":v}} for l,v in zip(langs,vals)}}
base = os.path.join(os.path.dirname(__file__), "..", "Renting")
json.dump(out, open(os.path.join(base,"Localizable.xcstrings"),"w"), ensure_ascii=False, indent=2)

# Info.plist strings
info = {
 "CFBundleDisplayName": ["Renting"]*9,
 "NSUserTrackingUsageDescription": [
  "Your data is used to show more relevant ads. We never sell your personal data.",
  "Tu información se usa para mostrar anuncios más relevantes. Nunca vendemos tus datos personales.",
  "Deine Daten werden verwendet, um relevantere Werbung anzuzeigen. Wir verkaufen deine persönlichen Daten nie.",
  "Vos données servent à afficher des publicités plus pertinentes. Nous ne vendons jamais vos données personnelles.",
  "I tuoi dati vengono usati per mostrare pubblicità più pertinenti. Non vendiamo mai i tuoi dati personali.",
  "Seus dados são usados para exibir anúncios mais relevantes. Nunca vendemos seus dados pessoais.",
  "تُستخدم بياناتك لعرض إعلانات أكثر صلة. لا نبيع بياناتك الشخصية أبدًا.",
  "आपके डेटा का उपयोग अधिक प्रासंगिक विज्ञापन दिखाने के लिए किया जाता है। हम आपका व्यक्तिगत डेटा कभी नहीं बेचते।",
  "你的数据用于展示更相关的广告。我们绝不会出售你的个人数据。"],
}
iout = {"sourceLanguage":"en","version":"1.0","strings":{}}
for key, vals in info.items():
    iout["strings"][key] = {"localizations":{l:{"stringUnit":{"state":"translated","value":v}} for l,v in zip(langs,vals)}}
json.dump(iout, open(os.path.join(base,"InfoPlist.xcstrings"),"w"), ensure_ascii=False, indent=2)
print(len(S), "keys")
