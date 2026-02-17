// ZeroModelLogger.swift
// Internal logging utility for the ZeroModel library.
// Only emits logs that meet or exceed the configured log level.

import Foundation

// MARK: - ZeroModelLogLevel

/// Log verbosity levels for the ZeroModel library.
public enum ZeroModelLogLevel: Int, Comparable {
    case none    = 0   // No logs emitted
    case error   = 1   // Errors only
    case warning = 2   // Warnings + errors (Default)
    case info    = 3   // Info + warnings + errors
    case debug   = 4   // All logs (verbose)

    public static func < (lhs: ZeroModelLogLevel, rhs: ZeroModelLogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - ZeroModelLogger

internal enum ZeroModelLogger {

    /// Emits a log message if `level` meets or exceeds the configured minimum.
    static func log(_ message: String, level: ZeroModelLogLevel) {
        guard ZeroModel.shared.configuration.logLevel >= level,
              ZeroModel.shared.configuration.logLevel != .none else { return }

        let prefix: String
        switch level {
        case .error:   prefix = "[ZeroModel ❌ ERROR]"
        case .warning: prefix = "[ZeroModel ⚠️ WARN ]"
        case .info:    prefix = "[ZeroModel ℹ️ INFO ]"
        case .debug:   prefix = "[ZeroModel 🔍 DEBUG]"
        case .none:    return
        }

        print("\(prefix) \(message)")
    }
}
