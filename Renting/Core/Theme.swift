//
//  Theme.swift
//  Renting
//

import SwiftUI

// The palette (`Color.brand`, `.income`, …) lives in Shared/BrandColors.swift: the widget uses it too.

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func card() -> some View { modifier(CardStyle()) }
}

/// A small coloured pill ("Ocupada", "Pendiente"…).
struct Pill: View {
    let text: LocalizedStringKey
    let color: Color
    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.14), in: Capsule())
    }
}

/// Section title used inside scroll-based screens.
struct SectionTitle: View {
    let key: LocalizedStringKey
    var body: some View {
        Text(key).font(.headline).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 6)
    }
}

/// Label + value pair used in KPI tiles.
struct KPI: View {
    let title: LocalizedStringKey
    let value: String
    var color: Color = .primary
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.weight(.bold)).foregroundStyle(color).minimumScaleFactor(0.7).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
