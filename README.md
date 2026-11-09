# Renting (working name)

iOS app (SwiftUI, iOS 17+) for landlords: traditional, by-room and seasonal rentals. Data only on the device (JSON in Application Support).
Same monetization stack as Capital: ATT → Google UMP → Unity LevelPlay (banner, interstitial, rewarded), review prompt, 9 languages.

## Build
```bash
export LANG=en_US.UTF-8   # CocoaPods needs UTF-8
xcodegen generate         # regenerates Renting.xcodeproj from project.yml
pod install               # LevelPlay + adapters + Google UMP
open Renting.xcworkspace  # always the workspace
```
Translations live in `tools/strings_part*.py` → `python3 tools/gen_strings.py` regenerates `Renting/Localizable.xcstrings`
(en, es, de, fr, it, pt, ar, hi, zh-Hans).

## Structure
- `Renting/Core` — models (`Models`), store + aggregations (`RentalStore`), `DemoData` (fictional portfolio), alerts, PDF/CSV (`ReportService`)
- `Renting/Ads`, `Renting/Store/ReviewManager` — copied from the LevelPlay template (same policy as Capital)
- `Renting/Views` — tabs: Summary, Homes (homes | tenants segments), Collections (calendar check), Expenses (month checklist / year matrix / list), Fiscal; plus the plan (paywall/alerts) and Settings

## Money rules
- A payment is rent + utilities (`Payment.supplies`). Only the rent counts for the manager's commission and the fiscal report.
- A manager on commission lives in `Property.management` (percent, optional +21 % VAT) and shows up as a monthly `Charge` in Expenses.
- Every expense occurrence (`Charge`) can be ticked as paid (`Expense.paidMonths`, `Management.paidMonths`).
- Deductible categories are chosen in the Fiscal tab (`Snapshot.deductible`); default: community, IBI, garbage/waste taxes, manager.
- Fiscal tab (Spanish IRPF): deductible expenses and the 3 % depreciation count only for the days each home/room was let; the reduction per contract (`Tenant.reduction`, automatic: none for seasonal, 60 % before 26/05/2023, 50 % after) applies to a positive net yield; days not let impute 1.1 %/2 % of `Property.cadastralValue` unless `ownerResidence`.
- Alerts are rules (`AlertRules.swift`): each can be switched off, has its own threshold and decides whether it notifies; `Alerts.swift` evaluates them and `AlertsManager.plan` turns them into local notifications. Utility bills can be recorded for real (`Expense.actuals`, long-press a charge in Expenses) so the "utility increase" rule works.
- Two plans: free (up to 3 homes, basic tenant/home/tax tools, ads) and the Renting Cloud monthly subscription (unlimited homes, the advanced home/tenant/tax tools, receipts, alerts, no ads, iCloud sync) — `Plan.swift`, `StoreManager` (single product), `Views/Components/PlanGate.swift`. There is no one-time purchase. Sync is `CloudSync.swift` (CKSyncEngine, private CloudKit database) on top of the pure `SyncModel.swift`; see `docs/cloud-y-suscripcion.md` for the decision, the manual setup (CloudKit container, schema deploy, App Store Connect) and what is verified. Debug flags: `-debugAudit 1` (80 logic/performance checks → tmp/audit.txt, see `docs/auditoria.md`), `-debugPro 1`/`-debugCloud 1` (fake subscription), `-debugNoPro 1` (free plan), `-debugSyncTest 1` (offline sync checks), `-debugOpen cloud`, `-debugDemoAsReal 1` (sample portfolio as real data, to test sync). Settings also has "Load sample data as real (testing)" in development/TestFlight builds. The app icon is provisional: regenerate it with `swift tools/icon/make_icon.swift out.png` (then flatten the alpha) or replace `AppIcon-1024.png`.
- Summary tab periods (`Period.swift`): month, calendar quarter (Q1 = Jan–Mar from 1 January) and year. A running quarter/year counts only up to the current month (`accountedMonths`), so expenses still to come do not look like a loss. The Income card shows month, quarter and year side by side; the chart changes scale with the period (12 monthly bars, 4 quarterly, one per year), a tap on a bar selects that period, and its (i) opens `PeriodInfoView` (income per tenant, expenses per concept, what is still owed/unpaid).
- Summary tab: the (i) next to the net profit opens `KPIInfoView` (net profit equation, collection rate, occupancy, expense mix, margin, utilities coverage, each with a 12-month chart).
- Fianza (a "deposited" switch with a reminder N days after move-in, no autonomous communities: the app is global) and annual rent update (IRAV/IPC + notice letter): `Compliance.swift`; the IRAV value is dated in `RentRules.asOf` and must be refreshed.
- Homes, rooms and tenants are edited in place on their detail screens (`AutoSave.swift`); each room has its own asking rent and utilities contribution, and every tenant keeps the price they signed (`Tenant.starting(in:)`).
- Rent receipts (`ReceiptService`, LAU art. 17.4): A5 PDF with rent and utilities on separate lines; landlord name/tax ID in Settings (UserDefaults, on device).

## Plans (see `docs/cloud-y-suscripcion.md` for the full table)
Free: up to 3 homes, rent/dates/deposit amounts for tenants, collections, expenses, Summary, widget, file backup, net rent before reductions in the Tax tab. Subscription: unlimited homes, manager and tax data for homes, contract type / rent update + letter / deposit filing / tax reduction / receipts for tenants, depreciation + reductions + vacancy imputation + deductible choice + PDF/CSV in Tax, alerts, no ads, iCloud sync. A rewarded video still removes ads and unlocks the Tax export for 1 hour. Nothing already entered is hidden or deleted when a subscription ends.

## Before release
- [ ] `Ads/AdConfig.swift`: replace `PENDING_*` with this app's LevelPlay App Key / ad unit IDs.
- [ ] `Info.plist`: `GADApplicationIdentifier` (currently Google's sample ID).
- [ ] `SettingsView.swift` → `AppLinks`: real privacy URL, App Store ID.
- [ ] Final name + bundle ID (currently `com.albeasystems.renting`), app icon.
- [ ] App Store Connect: create the Renting Cloud subscription (no one-time product).
- [ ] Debug flags: `-debugDemo 1 -debugPro 1 -debugNoPro 1 -debugTab properties|tenants|collections|expenses|fiscal -debugOpen reports|alerts|settings|paywall`.

Market research and next gaps: `docs/investigacion-usuarios-y-gaps.md`.
- "Monthly collections" widget (`RentingWidget/`, a WidgetKit extension): the app writes a snapshot (`Shared/WidgetSnapshot.swift`, built by `Renting/Core/WidgetBridge.swift`) into the App Group `group.com.albeasystems.renting` and the widget only draws it. `Shared/` holds what both targets use. Tapping it opens the Collections tab (`renting://collections`). After adding files run `xcodegen generate` + `pod install`.
- First use (`SetupPrompt`, `ReviewManager.isEligible`): an empty app asks for a home, then a tenant; ATT, the consent form and ads wait until there is a home; the rating prompt needs real data, 3 payments ticked and 2 days of use. A month with a payment is removed only after a confirmation (`AppUI.tapPayment`).
- Backup file (`Core/Backup.swift`, `Views/Settings/BackupView.swift`): Settings → Backup saves all the data as `Renting-backup-<date>.json` (no account, no server) and restores it after a confirmation; it is the way out for someone without iCloud. Debug: `-debugWriteBackup`, `-debugImport <file>`.
