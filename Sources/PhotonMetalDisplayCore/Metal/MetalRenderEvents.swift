//
//  MetalRenderEvents.swift
//  PhotonMetalDisplayCore
//
//  Created by JuniperPhoton on 2025/3/13.
//
import Foundation
import OSLog

/// A delegate for metal rendering events.
public protocol MetalRenderEventsDelegate: AnyObject {
    func onStartInitializeCIContext()
    func onStopInitializeCIContext()
    func onStartRender(id: String)
    func onEndRender(id: String)
}

/// A default logger based delegate for metal rendering events.
public class LoggerMetalRenderEventsDelegate: MetalRenderEventsDelegate {
    static let defaultLogger = Logger(subsystem: "com.juniperphoton.metaldisplaycore", category: "mtl_event")
    
    private let logger: Logger
    
    /// Create a new instance with an optional logger.
    public init(logger: Logger? = nil) {
        if let logger {
            self.logger = logger
        } else {
            self.logger = Self.defaultLogger
        }
    }
    
    public func onStartInitializeCIContext() {
        logger.log("Start initialize CIContext")
    }
    
    public func onStopInitializeCIContext() {
        logger.log("Stop initialize CIContext")
    }
    
    public func onStartRender(id: String) {
        logger.log("Start render: \(id)")
    }
    
    public func onEndRender(id: String) {
        logger.log("End render: \(id)")
    }
}
