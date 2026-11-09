//
//  AdConfig.swift
//  Renting
//
//  Unity LevelPlay (ironSource) app key and ad unit IDs, plus interstitial
//  frequency-capping constants. Same policy as Capital: interstitials are paced by
//  user actions, never by a timer, and never open the app straight into an ad.
//
//  App key and ad unit IDs come from this app's LevelPlay dashboard.
//

import Foundation

enum AdConfig {

    /// LevelPlay App Key.
    static let levelPlayAppKey = "PENDING_APP_KEY"  // TODO: this app's LevelPlay App Key

    /// Banner placement per tab. All tabs share the same LevelPlay ad unit.
    enum Placement {
        case dashboard, properties, collections, expenses, fiscal
    }

    // The SDK's `adUnitId:` initialisers take the dashboard's ad unit ID, not the
    // ad unit's display name — passing the name yields "Invalid ad unit id".

    static func bannerID(_ placement: Placement) -> String {
        "PENDING_BANNER_ID"
    }

    static var interstitialID: String {
        "PENDING_INTERSTITIAL_ID"
    }

    static var rewardedID: String {
        "PENDING_REWARDED_ID"
    }

    // MARK: - Rewarded

    /// How long ads stay off after the user completes a rewarded video.
    /// Watching again while a window is open extends it rather than restarting it.
    static let rewardedAdFreeDuration: TimeInterval = 3600   // 1 hour

    // MARK: - Interstitial frequency capping

    /// Key actions between interstitials. The counter runs ALWAYS — the grace and
    /// cooldown below only decide whether an ad may be *shown*, never whether an
    /// action counts.
    ///
    /// A "key action" here is leaving a detail screen or switching tab: natural
    /// breakpoints where a full-screen ad never lands on top of fresh data.
    static let successfulActionsRequiredForInterstitial = 3

    /// Minimum time between two interstitials actually shown. Persisted, so closing
    /// and reopening the app does not reset it.
    static let interstitialCooldown: TimeInterval = 300   // 5 minutes

    /// Window after a session starts during which no interstitial is shown, so the
    /// app never opens straight into an ad.
    static let startupGracePeriod: TimeInterval = 15

    /// Seconds after the rating prompt during which no interstitial is shown, so the
    /// user is never hit with an ad right after being asked to rate. Short on
    /// purpose: it only has to outlast the rating sheet itself.
    static let postReviewGrace: TimeInterval = 15

    /// Hard ceiling per session. A session restarts after 30 minutes away.
    static let maxInterstitialsPerSession = 3

    /// Exponential backoff when a load fails (seconds): starts at `base`, doubles
    /// up to `max`, resets on a successful load.
    static let interstitialBaseRetryDelay: TimeInterval = 4
    static let interstitialMaxRetryDelay: TimeInterval = 64

    /// Away-from-app gap after which a new session starts.
    static let newSessionGap: TimeInterval = 30 * 60

    /// Height reserved for the banner so the layout never jumps when it loads.
    static let bannerHeight: CGFloat = 50
}
