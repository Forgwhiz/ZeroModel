// ZeroModelInstance.swift
// Represents a single dynamic model (e.g. loginModel, dashboardModel).
// Supports dynamic property access, auto-mapping from JSON, and cache management.

import Foundation

// MARK: - ZeroModelInstance

/// A single dynamic model instance.
/// All properties are resolved at runtime — no pre-declaration needed.
///
/// Example:
///   ZeroModel.loginModel.userId        → ZeroModelValue (crash-safe)
///   ZeroModel.loginModel.details.phone → nested ZeroModelInstance access
@dynamicMemberLookup
public final class ZeroModelInstance {

    // MARK: - Properties

    /// The registered name of this model (e.g. "loginModel").
    public let name: String

    // Internal key-value storage for this model's properties.
    private var storage:      [String: Any] = [:]
    private let lock =        NSLock()
    private weak var cacheManager: ZeroModelCacheManager?

    // MARK: - Initialiser

    internal init(name: String, cacheManager: ZeroModelCacheManager?) {
        self.name         = name
        self.cacheManager = cacheManager
        restoreFromCache()
    }

    // MARK: - Dynamic Member Lookup

    /// Read access: `model.userId` returns a `ZeroModelValue`.
    public subscript(dynamicMember key: String) -> ZeroModelValue {
        get {
            lock.lock()
            defer { lock.unlock() }
            return ZeroModelValue(storage[key], key: key, modelName: name)
        }
    }

    /// Write access: `model.userId = "abc"` stores a raw value.
    public subscript(dynamicMember key: String) -> Any? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storage[key]
        }
        set {
            lock.lock()
            storage[key] = newValue
            lock.unlock()
            persistToCache()
        }
    }

    // MARK: - Mapping

    /// Maps a raw JSON dictionary onto this model instance.
    /// Existing keys are overwritten; nested dictionaries become nested `ZeroModelInstance` objects.
    ///
    ///     ZeroModel.loginModel.map(from: jsonDictionary)
    ///
    /// - Parameter json: The raw `[String: Any]` dictionary from the API response.
    public func map(from json: [String: Any]) {
        lock.lock()
        var newStorage: [String: Any] = [:]
        for (rawKey, value) in json {
            let camelKey = rawKey.zm_camelCased()
            newStorage[camelKey] = resolvedValue(value, key: camelKey)
        }
        storage = newStorage
        lock.unlock()

        persistToCache()
        ZeroModelLogger.log("[\(name)] Mapped \(json.keys.count) key(s).", level: .debug)
    }

    /// Maps a raw JSON array onto this model, stored under `"items"`.
    public func map(from jsonArray: [[String: Any]]) {
        let instances = jsonArray.map { dict -> ZeroModelInstance in
            let child = ZeroModelInstance(name: "\(name)_item", cacheManager: cacheManager)
            child.map(from: dict)
            return child
        }
        lock.lock()
        storage["items"] = instances
        lock.unlock()
        persistToCache()
    }

    // MARK: - Helpers

    /// Returns all current property keys on this model.
    public var allKeys: [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(storage.keys)
    }

    /// Returns `true` if a key exists on this model.
    public func hasKey(_ key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return storage[key] != nil
    }

    /// Clears all values from this model instance and its cache entry.
    public func clear() {
        lock.lock()
        storage.removeAll()
        lock.unlock()
        clearCache()
        ZeroModelLogger.log("[\(name)] Cleared all values.", level: .debug)
    }

    // MARK: - Build-time Helper (transforms at call site via Xcode Extension)

    /// Build-time convenience — lets a developer type `createProperty("userId")`
    /// which the ZeroModel Xcode Source Editor Extension transforms into `.userId`.
    ///
    /// At runtime this is a no-op; it simply returns an empty `ZeroModelValue`.
    @discardableResult
    public func createProperty(_ name: String) -> ZeroModelValue {
        // Runtime no-op. The Xcode Extension replaces this call with the property accessor.
        return ZeroModelValue(nil, key: name, modelName: self.name)
    }

    // MARK: - Private

    /// Resolves a raw JSON value recursively:
    ///   - [String: Any]   → ZeroModelInstance (nested dict becomes a child model)
    ///   - [[String: Any]] → [ZeroModelInstance] (array of dicts, each a child model)
    ///   - [Any]           → [ZeroModelInstance] mixed array, best-effort per element
    ///   - NSNull          → kept as NSNull (exposed as .isNull on ZeroModelValue)
    ///   - primitives      → passed through unchanged
    private func resolvedValue(_ value: Any, key: String) -> Any {

        // NSNull — keep as-is so ZeroModelValue.isNull works correctly
        if value is NSNull { return value }

        // Nested dictionary → child ZeroModelInstance
        if let nested = value as? [String: Any] {
            let child = ZeroModelInstance(name: "\(name).\(key)", cacheManager: cacheManager)
            child.map(from: nested)
            return child
        }

        // Array of dictionaries → [ZeroModelInstance]
        if let nestedArray = value as? [[String: Any]] {
            return nestedArray.enumerated().map { index, dict -> ZeroModelInstance in
                let child = ZeroModelInstance(
                    name: "\(name).\(key)[\(index)]",
                    cacheManager: cacheManager
                )
                child.map(from: dict)
                return child
            }
        }

        // Mixed array — wrap dicts as child instances, keep primitives as-is
        if let mixedArray = value as? [Any] {
            return mixedArray.enumerated().map { index, element -> Any in
                if let dict = element as? [String: Any] {
                    let child = ZeroModelInstance(
                        name: "\(name).\(key)[\(index)]",
                        cacheManager: cacheManager
                    )
                    child.map(from: dict)
                    return child
                }
                return element
            }
        }

        return value
    }

    // MARK: - Cache

    private func persistToCache() {
        cacheManager?.persist(storage: storage, forModel: name)
    }

    internal func clearCache() {
        cacheManager?.clear(forModel: name)
    }

    private func restoreFromCache() {
        guard let restored = cacheManager?.restore(forModel: name) else { return }
        lock.lock()
        storage = restored
        lock.unlock()
        ZeroModelLogger.log("[\(name)] Restored from cache.", level: .debug)
    }
}
