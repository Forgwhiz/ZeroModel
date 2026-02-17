// ZeroModelConfiguration.swift
// All tuneable options for the ZeroModel library.
// Pass a configured instance to ZeroModel.configure(options:).

import Foundation

// MARK: - ZeroModelConfiguration

/// Configuration options for the ZeroModel library.
///
/// Example:
///
///     let config = ZeroModelConfiguration()
///     config.cachePolicy   = .untilNextAPICall
///     config.logLevel      = .debug
///     config.keyCodingStyle = .camelCase
///     ZeroModel.configure(options: config)
///
public final class ZeroModelConfiguration {

    // MARK: - Cache Policy

    /// Defines how long a model's values are retained.
    public var cachePolicy: ZeroModelCachePolicy = .untilNextAPICall

    /// Default TTL in seconds — used when `cachePolicy` is `.ttl(seconds:)`.
    /// Ignored for other cache policies.
    public var defaultTTLSeconds: TimeInterval = 3600 // 1 hour

    // MARK: - Key Coding Style

    /// Controls how JSON keys are transformed when mapping to property names.
    public var keyCodingStyle: ZeroModelKeyCodingStyle = .camelCase

    // MARK: - Logging

    /// The minimum log level emitted by ZeroModel. Set `.none` to silence all logs.
    public var logLevel: ZeroModelLogLevel = .warning

    // MARK: - Network

    /// Default timeout interval for ZeroModel-managed network requests, in seconds.
    public var requestTimeout: TimeInterval = 30.0

    /// Common headers attached to every ZeroModel-managed request.
    public var commonHeaders: [String: String] = [:]

    /// A closure that returns the current auth token — injected automatically as `Authorization: Bearer <token>`.
    public var authTokenProvider: (() -> String?)? = nil

    // MARK: - Initialiser

    public init() {}
}

// MARK: - ZeroModelCachePolicy

/// Determines when cached model values are invalidated.
public enum ZeroModelCachePolicy {

    /// Values persist until the same model receives a new API response. (Default)
    case untilNextAPICall

    /// Values persist for the lifetime of the current app session only.
    case untilAppKill

    /// Values persist for a fixed duration (seconds) from the time they were last written.
    case ttl(seconds: TimeInterval)

    /// Values are never persisted to disk — in-memory only.
    case inMemoryOnly

    /// Values are never cached — always fresh from the last API call.
    case noCache
}

// MARK: - ZeroModelKeyCodingStyle

/// Determines how raw JSON keys are transformed into Swift property names.
public enum ZeroModelKeyCodingStyle {

    /// `user_id` → `userId`  (Default)
    case camelCase

    /// Keys are used as-is with no transformation.
    case none
}
