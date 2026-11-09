//
//  ReviewManager.swift
//  Renting
//
//  Asks for the native App Store rating shortly after the user's FIRST
//  meaningful action of a session (seeing their data load, or opening a detail
//  screen / switching tab). Apple caps the prompts it actually DISPLAYS at 3
//  per year; calls the system silently drops don't spend that quota, so asking
//  early and often on our side is cheap.
//
//  Coordination with ads: THE RATING GOES FIRST. No interstitial is shown until
//  the prompt has been fired once (`allowsInterstitials`), and none right after
//  it (`AdConfig.postReviewGrace`). Unlike Capital, a slot the prompt passes on is
//  NOT handed to an interstitial: in an analytics app an ad popping up seconds
//  after the data appears is exactly the jarring behaviour we are avoiding.
//

import StoreKit
import UIKit
import os

@MainActor
final class ReviewManager {

    static let shared = ReviewManager()

    // MARK: - Configuration

    // WHY THERE IS NO ACTION COUNT AND NO SESSION-TIME BAR ANY MORE.
    //
    // The previous rule was "4 key actions AND 60 seconds into the session", and
    // it was evaluated ONLY inside `registerKeyAction()`. In a calculator that is
    // a rule that almost never fires: people run their four calculations in the
    // first thirty seconds, then spend a minute reading the result — and by the
    // time the 60 seconds are up there is no further tap left to re-evaluate the
    // rule on, so nothing is ever asked. Measured in production it took more
    // than ten interactions to surface, which for an app people open once to
    // work out a mortgage means never.
    //
    // The rule is now a timer, not a counter: one calculation is enough intent,
    // and the wait is short enough that the user is still looking at their own
    // result when the sheet appears — which is exactly the moment the app has
    // just been useful to them.

    /// Seconds between the session's first calculation and the prompt. Long
    /// enough that the result is on screen and the keyboard has gone, short
    /// enough that the user has not put the phone down.
    private static let firstActionDelay: TimeInterval = 5

    /// Escape valve for ads: if the prompt never gets to fire (no active scene,
    /// for instance) interstitials are released after this many actions so we
    /// don't lose monetisation indefinitely. Low now, because the prompt fires on
    /// the first calculation in every ordinary flow and this only ever catches
    /// the cases where that failed outright.
    private static let actionsBeforeUnblockingAds = 4

    /// Seconds that must have passed since the last interstitial was dismissed
    /// before firing the prompt (don't ask for a rating with the ad still fresh).
    private static let postInterstitialGrace: TimeInterval = 45

    #if DEBUG
    // Short values so the whole flow can be exercised in the simulator without
    // waiting. They do not affect release builds.
    //
    // NOTE: `minTimeBetweenRequests` cannot be 0. If it were, every action would
    // refresh `lastReviewRequestedAt` and `AdConfig.postReviewGrace` would block
    // the interstitial forever.
    private static let minTimeBetweenRequests: TimeInterval = 300
    private static let newSessionGap: TimeInterval = 20
    #else
    /// Minimum time between two requests of OURS.
    ///
    /// Not to be confused with Apple's limit (3 displayed per year): calls iOS
    /// silently drops don't spend that quota. Hence 30 days rather than 60 — if a
    /// request lands at a bad moment we don't want to lose two months, we want
    /// another shot soon. iOS still decides which ones it shows.
    private static let minTimeBetweenRequests: TimeInterval = 30 * 24 * 3600

    /// Gap away from the app beyond which returning to the foreground counts as a
    /// new session. Stops the counter inflating when switching apps for seconds.
    private static let newSessionGap: TimeInterval = 30 * 60
    #endif

    // MARK: - Persisted state

    private let actionsKey        = "renting_review_total_actions"
    private let lastRequestKey    = "renting_review_last_request_ts"
    private let ratedKey          = "renting_review_rated_manually"
    private let sessionsKey       = "renting_review_session_count"
    private let lastForegroundKey = "renting_review_last_foreground_ts"
    private let firstSeenKey      = "renting_review_first_seen_ts"

    /// Number of usage sessions. Incremented by `noteForeground()`.
    private var sessionCount: Int {
        get { UserDefaults.standard.integer(forKey: sessionsKey) }
        set { UserDefaults.standard.set(newValue, forKey: sessionsKey) }
    }

    /// Last time the app was in the foreground. Persisted so the gap is measured
    /// correctly even when iOS kills the process between visits.
    private var lastForegroundDate: Date? {
        get {
            let ts = UserDefaults.standard.double(forKey: lastForegroundKey)
            return ts > 0 ? Date(timeIntervalSince1970: ts) : nil
        }
        set {
            UserDefaults.standard.set(newValue?.timeIntervalSince1970 ?? 0, forKey: lastForegroundKey)
        }
    }

    /// `true` if the user went to rate the app on their own from Settings.
    ///
    /// Apple does not tell us whether anyone rated: `requestReview` has neither a
    /// callback nor a return value. That bookkeeping lives in iOS (max 3 prompts
    /// displayed per year, and it won't re-ask someone who already rated this
    /// version), not here.
    ///
    /// All we know is that they tapped "Rate the app" and we opened the App Store
    /// page. That does NOT prove they rated — they could have backed out. So this
    /// flag does not silence the automatic prompt; it only releases the
    /// interstitials, because if they already went to rate there is no pending
    /// rating left to protect.
    private var hasRatedManually: Bool {
        get { UserDefaults.standard.bool(forKey: ratedKey) }
        set { UserDefaults.standard.set(newValue, forKey: ratedKey) }
    }

    private var totalActions: Int {
        get { UserDefaults.standard.integer(forKey: actionsKey) }
        set { UserDefaults.standard.set(newValue, forKey: actionsKey) }
    }

    private var lastRequestDate: Date? {
        get {
            let ts = UserDefaults.standard.double(forKey: lastRequestKey)
            return ts > 0 ? Date(timeIntervalSince1970: ts) : nil
        }
        set {
            UserDefaults.standard.set(newValue?.timeIntervalSince1970 ?? 0, forKey: lastRequestKey)
        }
    }

    // MARK: - When it is worth asking

    /// Payments the landlord must have ticked before the first request: a month marked as collected
    /// is the app doing its job. (This rule used to ask five seconds after the first tab switch,
    /// with the app still empty.)
    static let minPaymentsBeforeAsking = 3

    #if DEBUG
    static let minDaysInUse = 0.0
    #else
    /// Days since the app was first opened: not on the first day, not in the first session.
    static let minDaysInUse = 2.0
    #endif

    /// Pure rule, so it can be tested: real data (not the sample portfolio), enough payments ticked and
    /// enough days since the first launch.
    static func isEligible(payments: Int, isDemo: Bool, daysInUse: Double, minDays: Double = minDaysInUse) -> Bool {
        !isDemo && payments >= minPaymentsBeforeAsking && daysInUse >= minDays
    }

    private var firstSeen: Date {
        let saved = UserDefaults.standard.double(forKey: firstSeenKey)
        if saved > 0 { return Date(timeIntervalSince1970: saved) }
        let now = Date()
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: firstSeenKey)
        return now
    }

    /// The landlord has used the app for real.
    private var hasUsedTheApp: Bool {
        let store = RentalStore.shared
        return Self.isEligible(payments: store.data.payments.count, isDemo: store.isDemo,
                               daysInUse: Date().timeIntervalSince(firstSeen) / 86_400)
    }

    // MARK: - In-memory state

    /// When the prompt was fired; `AdsManager` reads it to honour the post-review
    /// grace before showing an interstitial.
    private(set) var lastReviewRequestedAt: Date?

    /// The pending five-second countdown started by the session's first
    /// calculation. Cancelled if the user leaves the app before it fires — there
    /// is no point asking for stars, or showing an ad, into an empty screen.
    private var firstActionTask: Task<Void, Never>?

    /// `true` once this session's slot has been claimed, so a burst of taps
    /// schedules one countdown rather than one per tap.
    private var firstActionSlotUsed = false

    /// `true` once the app has been backgrounded since the last activation. In
    /// memory on purpose: if iOS kills the process while suspended, the next
    /// launch goes through the `countedThisProcess` branch instead.
    private var wentToBackground = false

    /// `true` once this process's initial activation has been evaluated.
    private var countedThisProcess = false

    private static let log = Logger(subsystem: "com.albeasystems.renting", category: "review")

    private init() {}

    // MARK: - Lifecycle

    /// Call at launch AND every time the app returns to the foreground.
    ///
    /// Counting sessions on cold launch alone is not enough: iOS keeps apps
    /// resident for a long time, so a user can open the app dozens of times from
    /// the app switcher without any launch code running again.
    ///
    /// Idempotent: extra calls don't inflate the counter, because a new session is
    /// only counted when the gap away from the app exceeds `newSessionGap`.
    func noteForeground() {
        let now = Date()
        _ = firstSeen   // starts counting the days in use at the very first launch

        // Only two things start a session: the process launching, or coming back
        // from the background. An `.inactive` → `.active` cycle does NOT count: it
        // happens with system dialogs (ATT, consent), Control Centre or a phone
        // call, and the user never left the app there.
        //
        // This filter is essential: on the way BACK, iOS passes through
        // `.inactive` before `.active`, so trying to infer it from the timestamp
        // alone fails — it would be rewritten just before being measured and the
        // gap would always come out as ~0.
        guard !countedThisProcess || wentToBackground else { return }

        let gap = lastForegroundDate.map { now.timeIntervalSince($0) } ?? .greatestFiniteMagnitude
        countedThisProcess = true
        wentToBackground = false
        lastForegroundDate = now

        guard gap >= Self.newSessionGap else { return }

        sessionCount += 1
        // A fresh session gets a fresh slot: the first calculation of every visit
        // is worth either a rating prompt or an interstitial.
        firstActionSlotUsed = false
        Self.log.debug("review — session \(self.sessionCount), lifetime actions: \(self.totalActions)")
        // This object is the one measuring the gap away from the app, so it is the
        // one that can tell AdsManager when a new session starts.
        AdsManager.shared.noteNewSession()
    }

    /// Call when the app goes to the background (`.background`, NOT `.inactive`).
    func noteBackground() {
        wentToBackground = true
        lastForegroundDate = Date()
        // Don't let a countdown started just before leaving fire into a screen the
        // user is no longer looking at.
        firstActionTask?.cancel()
        firstActionTask = nil
    }

    // MARK: - Interstitial gate
    //
    // THE RATING GOES FIRST. A user who has been shown an interstitial before
    // being asked to rate scores worse, so no interstitial is shown until the
    // review prompt has been fired at least once.

    /// `true` once the prompt has been fired (persisted: holding back the first
    /// interstitial happens once in the lifetime of the install).
    var hasRequestedReview: Bool { lastRequestDate != nil }

    /// Read by `AdsManager` before showing any interstitial.
    var allowsInterstitials: Bool {
        hasRequestedReview || hasRatedManually || totalActions >= Self.actionsBeforeUnblockingAds
    }

    // MARK: - Public API

    /// Call at the same points as `AdsManager.shared.registerKeyAction()`, and
    /// always BEFORE it, so the rating gets the first chance at the moment.
    func registerKeyAction() {
        totalActions += 1
        Self.log.debug("review — action \(self.totalActions)")
        claimFirstActionSlot()
    }

    /// A SECONDARY interaction (e.g. opening the metrics guide).
    ///
    /// Counts towards the escape valve but does NOT claim the five-second slot: a
    /// rating prompt landing on top of an explanation the user just asked to read
    /// is the most irritating interruption this app could produce.
    func registerSecondaryAction() {
        totalActions += 1
        Self.log.debug("review — secondary action \(self.totalActions)")
    }

    /// Call when the user taps "Rate the app" in Settings (which opens the App
    /// Store page with `?action=write-review`).
    ///
    /// Applies the NORMAL cooldown, not a permanent silence: opening the page is
    /// no proof they rated. The real "already rated" suppression is done by iOS.
    func markRatedManually() {
        hasRatedManually = true          // releases the interstitials
        lastRequestDate = Date()         // normal, reversible cooldown
        lastReviewRequestedAt = Date()   // honour the post-review grace
        Self.log.log("user went to rate from Settings — normal cooldown applied")
    }

    // MARK: - Internals

    /// Starts the session's one countdown, on the first calculation only.
    private func claimFirstActionSlot() {
        guard !firstActionSlotUsed else { return }
        // Not yet worth asking: the slot stays free for a later action of this session.
        guard hasUsedTheApp else {
            Self.log.debug("review — skipped: the app has not been used enough yet")
            return
        }
        firstActionSlotUsed = true

        Self.log.log("review — first action of the session, firing in \(Int(Self.firstActionDelay))s")
        firstActionTask?.cancel()
        firstActionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(Self.firstActionDelay))
            guard !Task.isCancelled, let self else { return }
            self.fireFirstActionSlot()
        }
    }

    /// Fires the prompt if it is allowed to. When it is not (cooldown, recent ad,
    /// no active scene) nothing happens: ads follow their own pacing.
    private func fireFirstActionSlot() {
        guard hasUsedTheApp else { return }   // the data may have changed during the countdown
        requestReviewIfPossible()
    }

    /// Returns `true` when the prompt was actually handed to StoreKit.
    @discardableResult
    private func requestReviewIfPossible() -> Bool {
        if let last = lastRequestDate {
            guard Date().timeIntervalSince(last) >= Self.minTimeBetweenRequests else {
                Self.log.debug("review — skipped: cooldown active (last: \(last, privacy: .public))")
                return false
            }
        }

        if let lastAd = AdsManager.shared.lastInterstitialClosedAt {
            guard Date().timeIntervalSince(lastAd) >= Self.postInterstitialGrace else {
                Self.log.debug("review — skipped: recent interstitial")
                return false
            }
        }

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else {
            Self.log.debug("review — skipped: no active foreground scene")
            return false
        }

        Self.log.log("requesting review (lifetime actions: \(self.totalActions), session \(self.sessionCount))")
        lastReviewRequestedAt = Date()
        lastRequestDate = Date()

        // `SKStoreReviewController` was deprecated in iOS 18 in favour of
        // `AppStore.requestReview(in:)`. The old path stays for the 17.0
        // deployment target.
        if #available(iOS 18.0, *) {
            AppStore.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview(in: scene)
        }
        return true
    }

    #if DEBUG
    /// Wipes the persisted state so the flow can be tested from scratch.
    func debugReset() {
        UserDefaults.standard.removeObject(forKey: actionsKey)
        UserDefaults.standard.removeObject(forKey: lastRequestKey)
        UserDefaults.standard.removeObject(forKey: ratedKey)
        UserDefaults.standard.removeObject(forKey: sessionsKey)
        UserDefaults.standard.removeObject(forKey: lastForegroundKey)
        UserDefaults.standard.removeObject(forKey: firstSeenKey)
        lastReviewRequestedAt = nil
        firstActionSlotUsed = false
        firstActionTask?.cancel()
        firstActionTask = nil
        Self.log.debug("review — state reset")
    }
    #endif
}
