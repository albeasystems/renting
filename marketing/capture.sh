#!/bin/sh
# Re-takes the simulator captures of the happy path in every app language.
# The journey of a landlord with the built-in fictional portfolio: Summary -> Homes -> Collections -> Expenses -> Tax.
# Needs the Debug build (the -debug* launch flags are compiled out of release). Usage:
#   sh marketing/capture.sh [es,en,...]          # default: all nine
# Env: UDID (booted simulator, default: 'Renting Test'), APP (path to Renting.app; default: builds into /tmp/renting-dd)
cd "$(dirname "$0")/.."
OUT="$PWD/marketing/source"
UDID=${UDID:-E5CF3A58-B6F3-4629-BEE1-00A3B39F422F}
BUNDLE=com.albeasystems.renting
if [ -z "$APP" ]; then
  export LANG=en_US.UTF-8
  xcodebuild build -workspace Renting.xcworkspace -scheme Renting -configuration Debug \
    -destination "id=$UDID" -derivedDataPath /tmp/renting-dd >/tmp/renting-build.log 2>&1 || { tail -20 /tmp/renting-build.log; exit 1; }
  APP=/tmp/renting-dd/Build/Products/Debug-iphonesimulator/Renting.app
fi
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1
xcrun simctl install "$UDID" "$APP"
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
xcrun simctl ui "$UDID" appearance light
# A fictional landlord for the receipt (name and tax ID are only stored on the device).
xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1
xcrun simctl spawn "$UDID" defaults write "$BUNDLE" landlord_name "Marta Iglesias Vidal"
xcrun simctl spawn "$UDID" defaults write "$BUNDLE" landlord_tax_id "12345678Z"
LANGS=${1:-es,en,fr,it,de,pt,ar,hi,zh}
for lang in $(echo "$LANGS" | tr ',' ' '); do
  code=$lang; [ "$lang" = zh ] && code=zh-Hans
  mkdir -p "$OUT/$lang"
  # name|launch flags   (Summary is the default tab; the DEBUG-only flags are defined in RootView, DashboardView, CollectionsView)
  for step in "01-summary|" "02-chart|-debugScrollChart 1" "03-homes|-debugTab properties" "04-collections|-debugTab collections" \
              "05-year|-debugTab collections -debugYear 1" "06-receipt|-debugTab collections -debugReceipt 1" \
              "07-expenses|-debugTab expenses" "08-tax|-debugTab fiscal"; do
    name=${step%%|*}; flags=${step#*|}
    # only: restrict to some steps, e.g. ONLY="05-year 06-receipt"
    if [ -n "$ONLY" ] && ! echo " $ONLY " | grep -q " $name "; then continue; fi
    xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE" \
      -app_language "$code" -debugDemo 1 -debugPro 1 $flags >/dev/null
    sleep 6
    xcrun simctl io "$UDID" screenshot "$OUT/$lang/$name.png" >/dev/null 2>&1
  done
  echo "captured $lang"
done
xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1
