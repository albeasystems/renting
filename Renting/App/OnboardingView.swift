//
//  OnboardingView.swift
//  Renting
//

import SwiftUI

struct OnboardingView: View {
    @Environment(RentalStore.self) private var store
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 20)
            Image(systemName: "building.2.crop.circle.fill")
                .font(.system(size: 76)).foregroundStyle(Color.brand)
            VStack(spacing: 8) {
                Text("onb.title").font(.largeTitle.bold()).multilineTextAlignment(.center)
                Text("onb.subtitle").font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: 16) {
                bullet("checkmark.circle.fill", "onb.b1")
                bullet("eurosign.circle.fill", "onb.b2")
                bullet("doc.richtext.fill", "onb.b3")
                bullet("lock.shield.fill", "onb.b4")
            }
            .padding(.horizontal, 8)
            Spacer()
            VStack(spacing: 10) {
                Button {
                    store.loadDemo(); hasSeenOnboarding = true
                } label: {
                    Text("onb.demo").fontWeight(.semibold).frame(maxWidth: .infinity).padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent).controlSize(.large)
                Button { hasSeenOnboarding = true } label: { Text("onb.empty").frame(maxWidth: .infinity) }
                    .controlSize(.large)
                Text("onb.demo.note").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .tint(Color.brand)
    }

    private func bullet(_ icon: String, _ key: LocalizedStringKey) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(Color.brand).frame(width: 30)
            Text(key).font(.subheadline)
        }
    }
}
