//
//  PlanGate.swift
//  Renting
//
//  How the screens show what only the subscription includes: the fields stay visible but greyed
//  out, under one row with a lock that opens the plan. Nothing is hidden, so a free user can see
//  what the subscription adds, and values already stored (a lapsed subscription) keep showing.
//

import SwiftUI

/// A row that says a feature is part of the subscription and opens the plan.
struct PlanLockRow: View {
    var text: LocalizedStringKey = "plan.locked"
    @State private var showPlan = false

    var body: some View {
        Button { showPlan = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "lock.fill").foregroundStyle(Color.gold)
                Text(text).font(.footnote.weight(.semibold)).multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Text("pro.unlock").font(.footnote).foregroundStyle(Color.brand)
                Image(systemName: "chevron.forward").font(.caption2.weight(.semibold)).foregroundStyle(.tertiary)
            }
        }
        .foregroundStyle(.primary)
        .sheet(isPresented: $showPlan) { ProSheet { ProPaywallView() } }
    }
}

/// The rows of a feature only the subscription includes. Subscribed: they work as usual.
/// Free: they are greyed out and a lock row sits on top of them.
struct SubscriberRows<Content: View>: View {
    @State private var plan = StoreManager.shared
    var note: LocalizedStringKey = "plan.locked"
    @ViewBuilder var content: () -> Content

    var body: some View {
        if !plan.hasCloud { PlanLockRow(text: note) }
        content().disabled(!plan.hasCloud)
    }
}
