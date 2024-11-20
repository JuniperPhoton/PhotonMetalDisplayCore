//
//  HDRContentDisplayObserver.swift
//  PhotonGPUImage
//
//  Created by JuniperPhoton on 2024/11/21.
//
import Foundation

#if canImport(UIKit)
import UIKit

/// An observer to detech whether to disable HDR display or not.
/// When the app is in inactive or in background, the observer will change the maximum dynamic range to SDR.
///
/// You can either observe in the closure passed in the initializer or by checking the `maximumDynamicRange` property.
@available(iOS 15.0, *)
public class HDRContentDisplayObserver {
    private var displayModeChanged: (MetalDynamicRange) -> Void
    
    /// The current maximum dynamic range supported currently.
    public private(set) var maximumDynamicRange: MetalDynamicRange = .hdr
    
    /// Initialize the observer with the given closure.
    ///
    /// - parameter displayModeChanged: The closure to call when the display mode changes.
    /// The parameter indicates the supported maximum dynamic range.
    public init(displayModeChanged: @escaping (MetalDynamicRange) -> Void) {
        self.displayModeChanged = displayModeChanged
        setupObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func didResignActive() {
        maximumDynamicRange = .sdr
        displayModeChanged(maximumDynamicRange)
    }
    
    @objc private func didBecomeActive() {
        maximumDynamicRange = .hdr
        displayModeChanged(maximumDynamicRange)
    }
}
#endif
