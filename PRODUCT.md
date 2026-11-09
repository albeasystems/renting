# Product

<!-- impeccable:product-schema 1 -->

This file describes the **website** for the Renting iPhone app (the app itself is the SwiftUI project in this folder). The site lives in `web/`; simulator captures and the GIFs built from them live in `marketing/`.

## Platform

web

## Stack
Vite + React 19 + Tailwind v4, prerendered to static HTML per page and language: the same pipeline as the sibling sites `amortix/web` and `Capital/web` (confirmed by the user, 2026-11-09). Hosting assumed GitHub Pages at `https://albeasystems.github.io/renting/` until a domain exists; the site origin and base path are one configurable constant. Image generation is not available in this environment, so the build is code-first.

## Users
Primary: a small private landlord in Spain (1 to 10 homes) who lets traditionally, by the room, or on seasonal contracts ("temporada", LAU art. 3) and today runs it from a spreadsheet, a notebook and the bank app. The job: know at a glance who has paid this month, what the homes cost, and what to put in the income-tax return, without rebuilding it every spring. They arrive from searches such as "app para gestionar alquileres", "recibo de alquiler PDF", "actualizar la renta IRAV o IPC", "declarar alquiler en la renta, gastos deducibles", "fianza del alquiler: plazo para depositarla", or from an AI assistant's answer.
Secondary, not the lead: landlords in the other eight app languages, who get the same product with a clear note that the Tax tab follows Spanish rules.

## Product Purpose
Renting is an iPhone (and iPad) app for landlords. It tracks monthly collections per tenant and room (a tick per month, a yearly matrix, overdue and unpaid), expenses with their due dates and paid state, a Summary tab (month, quarter, year income, net profit, collection rate, occupancy, expense mix), a Tax tab with deductible expenses and the Spanish IRPF reductions, rent receipts as PDF (LAU art. 17.4), annual rent update with the IRAV or IPC index and a notice letter, deposit ("fianza") tracking with a reminder, configurable alerts, a home-screen widget of the month's collections, and a backup file. The website exists to be found by landlords asking those questions, answer them, and send them to the App Store.

## Positioning
A landlord app that does the paperwork Spanish law and the tax return ask for, on the phone and on the device: receipts that break rent and utilities apart, the 50 % / 60 % IRPF reduction per contract, imputation for vacant days, the IRAV update letter. Utilities passed on to tenants never count for the manager's commission or the fiscal income (the owner's own rule, built in). Data stays on the device (JSON); iCloud sync is optional and private to the user's own account; there is no server.

## Operating Context
Used at the door of a flat, at the bank app, at the kitchen table in May with the tax return open. Numbers are formatted per locale (es: 1.250,00 EUR). The app opens on Summary, with tabs Homes (homes and tenants), Collections, Expenses and Tax. Minimum iOS 17.

## Capabilities and Constraints
- Two plans only, no one-time purchase: **free** (up to 3 homes, tenant rent/dates/deposit amounts, collections, expenses, Summary, widget, file backup, net rent before reductions in the Tax tab, with ads) and the **Renting Cloud monthly subscription** (unlimited homes, manager fee and cadastral data, contract type and rent insurance, IRAV/IPC update and letter, tax reduction per contract, receipts, depreciation and vacancy imputation in Tax, PDF/CSV export, alerts and notifications, no ads, iCloud sync). A rewarded video removes ads and unlocks the Tax export for one hour. Nothing already typed is hidden or deleted when a subscription ends.
- Ads: Unity LevelPlay behind ATT and the Google consent form; they wait until a home exists.
- 9 app languages: en, es, de, fr, it, pt, ar (RTL), hi, zh-Hans. Site languages must match.
- Informational tool, not tax or legal advice: percentages and deadlines must be checked against the rules in force each year. The site must say so. The IRAV value is dated in the app (`RentRules.asOf`) and the site must not state a current index number.
- **Undecided facts (do not invent):** the final app name (the working name is "Renting", provisional; candidates Casero, Llavero, Rentia; in Spanish "renting" also means vehicle and equipment leasing, which competes for the term), the App Store ID and listing URL (the app is not published), the subscription price, the privacy URL, the domain. The name and the store link are single constants in the site so each is a one-line change.
- Support contact: albeasystems@gmail.com (publisher Albea Systems).
- No sharing with a co-owner or manager in v1 (decided by the user). No tourist/vacation rental. No server and no account.
- Not yet verified on a real device: iCloud round trip, real purchase, notifications, VoiceOver. The site must not promise them as proven.

## Brand Commitments
Publisher Albea Systems; sibling apps Amortix, Capital, SnowballFI, Measuro, Divix, NotasPAU. The provisional icon is a house with a gold check on teal. Voice: direct and precise, no hype, as the siblings. Spain first, nine languages.

## Evidence on Hand
- The app code, the `-debugAudit 1` (158 checks) and `-debugSyncTest 1` (31 checks) self-tests, and `docs/` (user research and gaps, cloud and subscription decision, audit).
- A built-in fictional demo portfolio of 6 homes (`Renting/Core/DemoData.swift`, flag `-debugDemo 1`), the only data the captures may show. The plan flags `-debugPro 1` / `-debugNoPro 1` choose the plan in the simulator.
- No ratings, reviews, downloads, testimonials, customers, press or prices exist. None may be shown or implied. The sample portfolio is fictional and must be labelled as such wherever its figures appear.

## Product Principles
1. Answer the landlord's question first (who has not paid, what do I declare, which index do I apply), then offer the app.
2. Every figure on the site comes from a real capture of the app or from a port of its formulas; the demo portfolio is called a demo.
3. Say plainly what is free and what the subscription adds. Never hide that there are ads in the free plan.
4. Spanish rules are stated as Spanish rules, with the date they were last checked and a prompt to confirm with the tax agency or an adviser.
5. Be findable by search engines and by AI assistants: one clear answer per page, structured data, `llms.txt`, correct `hreflang`.

## Accessibility & Inclusion
WCAG AA contrast, keyboard-operable controls, `prefers-reduced-motion` and `prefers-color-scheme` respected, `dir="rtl"` and correct `hreflang` for Arabic, locale-correct number and date formatting, mobile layouts reviewed and not only desktop.
