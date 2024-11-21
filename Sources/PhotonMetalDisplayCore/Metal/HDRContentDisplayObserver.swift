//
//  HDRContentDisplayObserver.swift
//  PhotonGPUImage
//
//  Created by JuniperPhoton on 2024/11/21.
//
import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// An observer to detech whether to disable HDR display or not in iOS.
///
/// When the app is in inactive or in background, the observer will change the maximum dynamic range to SDR.
///
/// You can either observe in the closure passed in the initializer or by checking the `maximumDynamicRange` property.
///
/// ```swift
/// // Define this variable in the class scope.
/// private var observer: HDRContentDisplayObserver!
///
/// // Construct the observer and keep strong reference to it.
/// observer = HDRContentDisplayObserver { [weak self] range in
///     guard let self else { return }
///
///     // If the range is .sdr, then you need to set the dynamic range to SDR accordingly.
/// }
/// ```
/// To get the current maximum dynamic range, you can access the ``maximumDynamicRange`` property.
///
/// > Note: On macOS, this class won’t perform any actions because its lifecycle differs from iOS.
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
#if canImport(UIKit)
        setupObserver()
#endif
    }
    
#if canImport(UIKit)
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
#endif
}
