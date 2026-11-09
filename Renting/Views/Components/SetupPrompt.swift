//
//  SetupPrompt.swift
//  Renting
//
//  A new landlord's first minutes: an empty app has to say what to do next and put the button
//  right there, instead of showing zeros or asking the user to look for a "+" in a corner.
//  The steps are two: add a home, then add a tenant to it. Both the Summary and Collections
//  show this card while the step is pending.
//

import SwiftUI

enum SetupStep: Hashable {
    case addHome, addTenant

    var icon: String { self == .addHome ? "building.2.fill" : "person.badge.plus" }
    var title: LocalizedStringKey { self == .addHome ? "setup.home.title" : "setup.tenant.title" }
    var text: LocalizedStringKey { self == .addHome ? "setup.home.text" : "setup.tenant.text" }
    var button: LocalizedStringKey { self == .addHome ? "setup.home.button" : "setup.tenant.button" }
}

struct SetupPrompt: View {
    @Environment(RentalStore.self) private var store
    @Environment(AppUI.self) private var ui

    var body: some View {
        if let step = store.setupStep {
            VStack(spacing: 12) {
                Image(systemName: step.icon).font(.system(size: 40)).foregroundStyle(Color.brand)
                Text(step.title).font(.headline).multilineTextAlignment(.center)
                Text(step.text).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button { ui.startSetup(step) } label: {
                    Label(step.button, systemImage: "plus").fontWeight(.semibold).frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent).controlSize(.large)
            }
            .frame(maxWidth: .infinity)
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
