//
//  AppLanguage.swift
//  Renting
//
//  In-app language override. SwiftUI text follows `\.locale`, so the app injects
//  `locale` at the root; `bundle` serves the few strings looked up outside SwiftUI.
//

import Foundation
import Observation

@Observable
final class AppLanguage {
    static let shared = AppLanguage()

    static let supported = ["en", "es", "de", "fr", "it", "pt", "ar", "hi", "zh-Hans"]
    private static let key = "app_language"

    static func displayName(_ code: String) -> String {
        switch code {
        case "en": "English"
        case "es": "Español"
        case "de": "Deutsch"
        case "fr": "Français"
        case "it": "Italiano"
        case "pt": "Português"
        case "ar": "العربية"
        case "hi": "हिन्दी"
        case "zh-Hans": "简体中文"
        default: code
        }
    }

    /// Selected language code; defaults to the closest supported system language.
    var code: String {
        didSet {
            guard code != oldValue else { return }
            UserDefaults.standard.set(code, forKey: Self.key)
        }
    }

    var locale: Locale { Locale(identifier: code) }

    var bundle: Bundle {
        Bundle.main.path(forResource: code, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
    }

    var isRightToLeft: Bool { code == "ar" }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: Self.key), Self.supported.contains(saved) {
            code = saved
        } else {
            code = Bundle.preferredLocalizations(from: Self.supported, forPreferences: nil).first ?? "en"
        }
    }
}
