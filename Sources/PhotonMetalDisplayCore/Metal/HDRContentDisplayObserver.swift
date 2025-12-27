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
    public enum StartMonitorConfig {
        case none
        case `default`
        case custom(duration: Duration)
    }
    
    private var displayModeChanged: (MetalDynamicRange) -> Void
    
    private var maximumDynamicRangeInternal: MetalDynamicRange = .hdr
    
    /// Whether the current EDR headroom is SDR, reported by the system.
    /// Under some circustances, such as bright outdoor condition,
    /// the system will set `currentEDRHeadroom` to 1.0 and will clip HDR rendering.
    public private(set) var isCurrentEDRHeadroomSDR = false
    
    /// The current maximum dynamic range supported currently.
    public var maximumDynamicRange: MetalDynamicRange {
#if canImport(UIKit)
        let supportHDR = maximumDynamicRangeInternal == .hdr &&
        !lowPowerModeObserver.isLowPowerModeEnabled &&
        !isCurrentEDRHeadroomSDR
        
        return supportHDR ? .hdr : .sdr
#else
        return .hdr
#endif
    }
    
#if canImport(UIKit)
    private var edrMonitorTask: Task<Void, Error>? = nil
    private let lowPowerModeObserver = LowPowerModeObserver()
    private var lowPowerModeCancellable: Cancellable? = nil
#endif
    
    /// Initialize the observer with the given closure.
    ///
    /// - parameter startMonitorConfig: Start a timer to detect change of `currentEDRHeadroom`.
    /// Under the sun the device may encounter an issue where the system will refuse to render HDR and
    /// `currentEDRHeadroom` will be set to 1.0. However, there's no way to monitor the change of`currentEDRHeadroom`,
    /// so we will start a timer here.
    /// - parameter displayModeChanged: The closure to call when the display mode changes.
    /// The parameter indicates the supported maximum dynamic range.
    public init(startMonitorConfig: StartMonitorConfig, displayModeChanged: @escaping (MetalDynamicRange) -> Void) {
        self.displayModeChanged = displayModeChanged
#if canImport(UIKit)
        setupObserver(startMonitorConfig: startMonitorConfig)
#endif
        
#if canImport(UIKit)
        lowPowerModeCancellable = lowPowerModeObserver.$isLowPowerModeEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLowPowerModeEnabled in
                guard let self else { return }
                publishChanges()
            }
#endif
    }

    deinit {
        cancelObserve()
    }
    
    public func cancelObserve() {
#if canImport(UIKit)
        NotificationCenter.default.removeObserver(self)
        edrMonitorTask?.cancel()
        edrMonitorTask = nil
#endif
    }
    
#if canImport(UIKit)
    private func setupObserver(startMonitorConfig: StartMonitorConfig) {
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
        
        switch startMonitorConfig {
        case .default:
            startMonitorTask(interval: .seconds(1))
        case .custom(let duration):
            startMonitorTask(interval: duration)
        default:
            break
        }
    }
    
    private func startMonitorTask(interval: Duration) {
        edrMonitorTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
            isCurrentEDRHeadroomSDR = UIScreen.main.currentEDRHeadroom <= 1.0
            publishChanges()
            
            while(true) {
                try await Task.sleep(for: interval)
                let prevIsCurrentEDRHeadroomSDR = isCurrentEDRHeadroomSDR
                let newIsCurrentEDRHeadroomSDR = UIScreen.main.currentEDRHeadroom <= 1.0
                if prevIsCurrentEDRHeadroomSDR != newIsCurrentEDRHeadroomSDR {
                    isCurrentEDRHeadroomSDR = newIsCurrentEDRHeadroomSDR
                    publishChanges()
                }
            }
        }
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
