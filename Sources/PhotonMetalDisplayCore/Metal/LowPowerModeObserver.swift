//
//  LowPowerModeDetector.swift
//  PhotonCam
//
//  Created by JuniperPhoton on 2024/12/5.
//
import Combine
import Foundation

#if os(iOS)
/// An `ObservableObject` to publish changes about whether the device is in
/// low-power mode.
///
/// Observe ``isLowPowerModeEnabled`` property to get the notification.
///
/// ```swift
/// class Foo {
///     let observer = LowPowerModeObserver()
/// }
///
/// lowPowerModeCancellable = observer.$isLowPowerModeEnabled
///     .receive(on: DispatchQueue.main)
///     .sink { [weak self] isLowPowerModeEnabled in
///         guard let self else { return }
///     }
/// }
/// ```
///
/// Normally you shouldn't observe this direclty. Instead, you can use `HDRContentDisplayDetector`
/// to get whether you should render HDR content.
public class LowPowerModeObserver: ObservableObject {
    @Published public private(set) var isLowPowerModeEnabled: Bool = ProcessInfo.processInfo.isLowPowerModeEnabled
    
    public init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(powerStateChanged),
            name: Notification.Name.NSProcessInfoPowerStateDidChange,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func powerStateChanged(_ notification: Notification) {
        let lowerPowerEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        DispatchQueue.main.async {
            self.isLowPowerModeEnabled = lowerPowerEnabled
        }
    }
}
#endif
