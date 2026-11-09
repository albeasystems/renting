//
//  TabTap.swift
//  Renting
//
//  SwiftUI's `TabView` does not say when a tab is tapped again (its selection does not change),
//  and a tab that has been drilled into has to go back to its first screen whenever its item in
//  the tab bar is tapped. This puts a delegate in front of the tab bar controller's own one:
//  it reports every tap and hands everything else to the original, so the selection keeps working.
//

import UIKit

@MainActor
final class TabTapObserver: NSObject, UITabBarControllerDelegate {
    static let shared = TabTapObserver()

    /// Called with the index of the tapped item, before the tab is shown.
    var onTap: ((Int) -> Void)?
    nonisolated(unsafe) private weak var original: UITabBarControllerDelegate?
    private weak var controller: UITabBarController?

    /// Hooks into the app's tab bar controller; does nothing if it does not exist yet or is already hooked.
    func install(onTap: @escaping (Int) -> Void) {
        self.onTap = onTap
        guard let tabBar = Self.findTabBarController(), controller !== tabBar else { return }
        if tabBar.delegate !== self { original = tabBar.delegate }
        controller = tabBar
        tabBar.delegate = self
    }

    private static func findTabBarController() -> UITabBarController? {
        func search(_ vc: UIViewController) -> UITabBarController? {
            if let tabBar = vc as? UITabBarController { return tabBar }
            for child in vc.children { if let found = search(child) { return found } }
            return vc.presentedViewController.flatMap(search)
        }
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                if let root = window.rootViewController, let found = search(root) { return found }
            }
        }
        return nil
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let index = tabBarController.viewControllers?.firstIndex(of: viewController) { onTap?(index) }
        return original?.tabBarController?(tabBarController, shouldSelect: viewController) ?? true
    }

    nonisolated override func responds(to aSelector: Selector!) -> Bool {
        super.responds(to: aSelector) || (original?.responds(to: aSelector) ?? false)
    }

    nonisolated override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if let original, original.responds(to: aSelector) { return original }
        return super.forwardingTarget(for: aSelector)
    }
}
