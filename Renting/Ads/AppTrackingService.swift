//
//  AppTrackingService.swift
//  Renting
//
//  App Tracking Transparency. The "Ask App Not to Track" dialog is shown once,
//  at first launch. All four authorization states are handled gracefully:
//  ads keep working in every state (non-personalised when not authorized).
//

import AppTrackingTransparency
import Foundation

@MainActor
final class AppTrackingService {
    static let shared = AppTrackingService()
    private init() {}

    private let hasRequestedKey = "att_has_requested"

    /// Presents the ATT prompt as soon as possible on first launch. The system
    /// only allows the prompt while the app is active, so we wait briefly for the
    /// scene to become active and then request immediately.
    func requestTrackingIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        // Short wait for the window to be active (required by iOS), then prompt.
        try? await Task.sleep(for: .milliseconds(250))
        _ = await ATTrackingManager.requestTrackingAuthorization()
        UserDefaults.standard.set(true, forKey: hasRequestedKey)
    }

    var status: ATTrackingManager.AuthorizationStatus {
        ATTrackingManager.trackingAuthorizationStatus
    }

    var isAuthorized: Bool { status == .authorized }
}
