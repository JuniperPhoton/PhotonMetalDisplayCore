//
//  UIScreen+Active.swift
//  PhotonMetalDisplayCore
//
#if canImport(UIKit)
import UIKit

extension UIScreen {
    /// The screen of the foreground active window scene. Use this instead of `UIScreen.main`.
    ///
    /// `UIScreen.main` is deprecated and may not be the screen the app is actually on,
    /// for example on foldable devices, where its `currentEDRHeadroom` can be 1.0 while HDR is displayable.
    ///
    /// Falls back to `UIScreen.main` in app extensions, where `UIApplication.shared` is unavailable,
    /// and off the main thread, where `UIApplication.connectedScenes` can't be accessed.
    static var active: UIScreen {
        guard Thread.isMainThread, Bundle.main.bundleURL.pathExtension != "appex" else {
            return UIScreen.main
        }
        return MainActor.assumeIsolated {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
            return scene?.screen ?? UIScreen.main
        }
    }
}
#endif
