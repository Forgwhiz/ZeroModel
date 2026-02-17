// ZeroModel.swift
// Core entry point for the ZeroModel library.
//
// Usage:
//   ZeroModel.configure()               ← call once in AppDelegate
//   ZeroModel.loginModel.userId         ← access any dynamic property
//   ZeroModel.loginModel.map(from:json) ← manually map a response

import Foundation

// MARK: - ZeroModel Root

/// The root namespace for the ZeroModel library.
/// Supports dynamic member lookup so any model name resolves automatically.
///
/// Example:
///   ZeroModel.loginModel        → returns (or creates) a ZeroModelInstance named "loginModel"
///   ZeroModel.dashboardModel    → returns (or creates) a ZeroModelInstance named "dashboardModel"
@dynamicMemberLookup
public final class ZeroModel {

    // MARK: - Singleton

    /// Shared instance — holds all registered model instances.
    public static let shared = ZeroModel()

    private init() {}

    // MARK: - Configuration

    /// Call once in AppDelegate `didFinishLaunchingWithOptions`.
    ///
    ///     ZeroModel.configure()
    ///
    /// - Parameter options: Optional configuration block to customise behaviour.
    public static func configure(options: ZeroModelConfiguration = ZeroModelConfiguration()) {
        shared.configuration = options
        shared.cacheManager   = ZeroModelCacheManager(configuration: options)
        ZeroModelLogger.log("ZeroModel configured successfully.", level: .info)
    }

    // MARK: - Internal State

    internal var configuration: ZeroModelConfiguration  = ZeroModelConfiguration()
    internal var cacheManager:  ZeroModelCacheManager?
    private  var registry:     [String: ZeroModelInstance] = [:]
    private  let lock = NSLock()

    // MARK: - Dynamic Member Lookup

    /// Resolves `ZeroModel.<anyName>` to a `ZeroModelInstance`.
    /// Creates the instance on first access and returns the cached one on subsequent calls.
    public subscript(dynamicMember name: String) -> ZeroModelInstance {
        return instance(for: name)
    }

    // MARK: - Instance Management

    /// Returns the `ZeroModelInstance` registered under `name`, creating it if needed.
    public func instance(for name: String) -> ZeroModelInstance {
        lock.lock()
        defer { lock.unlock() }

        if let existing = registry[name] {
            return existing
        }
        let newInstance = ZeroModelInstance(name: name, cacheManager: cacheManager)
        registry[name] = newInstance
        ZeroModelLogger.log("Model instance created: \(name)", level: .debug)
        return newInstance
    }

    /// Removes a model instance and clears its cache.
    public func removeModel(named name: String) {
        lock.lock()
        defer { lock.unlock() }
        registry[name]?.clearCache()
        registry.removeValue(forKey: name)
        ZeroModelLogger.log("Model instance removed: \(name)", level: .debug)
    }

    /// Removes all model instances and clears all caches.
    public func removeAllModels() {
        lock.lock()
        defer { lock.unlock() }
        registry.values.forEach { $0.clearCache() }
        registry.removeAll()
        ZeroModelLogger.log("All model instances removed.", level: .info)
    }

    /// Returns all currently registered model names.
    public var registeredModelNames: [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(registry.keys)
    }
}
