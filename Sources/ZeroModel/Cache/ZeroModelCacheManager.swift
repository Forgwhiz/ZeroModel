// ZeroModelCacheManager.swift
// Handles persistence, TTL invalidation, and restoration of model values.
// Uses UserDefaults for lightweight key-value persistence across app launches.

import Foundation

// MARK: - ZeroModelCacheManager

/// Manages on-disk and in-memory caching of `ZeroModelInstance` storage dictionaries.
internal final class ZeroModelCacheManager {

    // MARK: - Constants

    private enum Keys {
        static let prefix     = "com.nomodel.cache."
        static let timestampSuffix = ".timestamp"
    }

    // MARK: - Properties

    private let configuration: ZeroModelConfiguration
    private let defaults = UserDefaults.standard
    private let lock = NSLock()

    // MARK: - Initialiser

    init(configuration: ZeroModelConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Persist

    /// Serialises and writes `storage` to UserDefaults under the model's cache key.
    func persist(storage: [String: Any], forModel name: String) {
        guard shouldPersist() else { return }

        lock.lock()
        defer { lock.unlock() }

        let cacheKey      = Keys.prefix + name
        let timestampKey  = cacheKey + Keys.timestampSuffix

        // Serialise only primitive-safe values (nested ZeroModelInstance → skip)
        let serialisable = serialisableStorage(storage)

        defaults.set(serialisable,        forKey: cacheKey)
        defaults.set(Date().timeIntervalSince1970, forKey: timestampKey)
        defaults.synchronize()

        ZeroModelLogger.log("[Cache] Persisted \(serialisable.keys.count) key(s) for model: \(name)", level: .debug)
    }

    // MARK: - Restore

    /// Restores a previously cached storage dictionary for `name`, respecting TTL.
    /// Returns `nil` if no cache entry exists or if the entry has expired.
    func restore(forModel name: String) -> [String: Any]? {
        guard shouldPersist() else { return nil }

        lock.lock()
        defer { lock.unlock() }

        let cacheKey     = Keys.prefix + name
        let timestampKey = cacheKey + Keys.timestampSuffix

        // TTL check
        if case .ttl(let seconds) = configuration.cachePolicy {
            let written = defaults.double(forKey: timestampKey)
            let elapsed = Date().timeIntervalSince1970 - written
            if elapsed > seconds {
                ZeroModelLogger.log("[Cache] TTL expired for model: \(name)", level: .debug)
                clear(forModel: name)
                return nil
            }
        }

        guard let stored = defaults.dictionary(forKey: cacheKey) else { return nil }
        ZeroModelLogger.log("[Cache] Restored \(stored.keys.count) key(s) for model: \(name)", level: .debug)
        return stored
    }

    // MARK: - Clear

    /// Removes the cache entry for `name`.
    func clear(forModel name: String) {
        let cacheKey     = Keys.prefix + name
        let timestampKey = cacheKey + Keys.timestampSuffix
        defaults.removeObject(forKey: cacheKey)
        defaults.removeObject(forKey: timestampKey)
        defaults.synchronize()
    }

    /// Removes all ZeroModel cache entries from UserDefaults.
    func clearAll() {
        let allKeys = defaults.dictionaryRepresentation().keys
        allKeys
            .filter { $0.hasPrefix(Keys.prefix) }
            .forEach { defaults.removeObject(forKey: $0) }
        defaults.synchronize()
        ZeroModelLogger.log("[Cache] Cleared all entries.", level: .info)
    }

    // MARK: - Private Helpers

    /// Returns `false` for policies that skip persistence.
    private func shouldPersist() -> Bool {
        switch configuration.cachePolicy {
        case .noCache, .inMemoryOnly: return false
        default:                      return true
        }
    }

    /// Strips non-serialisable values (e.g. nested `ZeroModelInstance` objects)
    /// so that `UserDefaults.set(_:forKey:)` does not crash.
    private func serialisableStorage(_ storage: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in storage {
            switch value {
            case is String, is Int, is Double, is Float, is Bool, is NSNull:
                result[key] = value
            case let arr as [Any]:
                result[key] = arr.filter { $0 is String || $0 is Int || $0 is Double || $0 is Bool }
            case is ZeroModelInstance:
                // Nested models are re-created at runtime from the API response — skip caching them.
                break
            default:
                if let num = value as? NSNumber {
                    result[key] = num
                }
            }
        }
        return result
    }
}
