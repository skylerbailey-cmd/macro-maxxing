import Foundation
import os

/// Centralised logging wrapper.  All messages are suppressed in release
/// builds so that user IDs, file paths, and operational details never
/// leak to device logs in production.
enum AppLogger {

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.sbailey.Wellness",
        category: "app"
    )

    /// General-purpose log.  Only emits output in DEBUG builds.
    static func log(_ message: String) {
        #if DEBUG
        logger.debug("\(message, privacy: .public)")
        #endif
    }
}
