//
//  HDRContentDisplayObserver.swift
//  PhotonGPUImage
//
//  Created by JuniperPhoton on 2024/11/21.
//
import Foundation
import Combine

#if canImport(UIKit)
import UIKit
#endif

/// An observer to detech whether to disable HDR display or not in iOS.
///
/// When the app is in inactive, in background or in low-power mode, the observer will change the maximum dynamic range to SDR.
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
/// > Note: This class also consider the low-power status internally.
/// To detect whether the current device is in low-power mode, use ``LowPowerModeDetector``.
///
/// > Note: On macOS, this class won’t perform any actions because its lifecycle differs from iOS.
public class HDRContentDisplayObserver {
    private var displayModeChanged: (MetalDynamicRange) -> Void
    
    private var maximumDynamicRangeInternal: MetalDynamicRange = .hdr
    
    /// The current maximum dynamic range supported currently.
    public var maximumDynamicRange: MetalDynamicRange {
        maximumDynamicRangeInternal == .hdr && !lowPowerModeObserver.isLowPowerModeEnabled ? .hdr : .sdr
    }
    
#if os(iOS)
    private let lowPowerModeObserver = LowPowerModeObserver()
    private var lowPowerModeCancellable: Cancellable? = nil
#endif
    
    /// Initialize the observer with the given closure.
    ///
    /// - parameter displayModeChanged: The closure to call when the display mode changes.
    /// The parameter indicates the supported maximum dynamic range.
    public init(displayModeChanged: @escaping (MetalDynamicRange) -> Void) {
        self.displayModeChanged = displayModeChanged
#if canImport(UIKit)
        setupObserver()
#endif
        
#if os(iOS)
        lowPowerModeCancellable = lowPowerModeObserver.$isLowPowerModeEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLowPowerModeEnabled in
                guard let self else { return }
                publishChanges()
            }
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
        maximumDynamicRangeInternal = .sdr
        publishChanges()
    }
    
    @objc private func didBecomeActive() {
        maximumDynamicRangeInternal = .hdr
        publishChanges()
    }
    
    private func publishChanges() {
        displayModeChanged(maximumDynamicRange)
    }
#endif
}
