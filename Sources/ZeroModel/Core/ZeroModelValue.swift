// ZeroModelValue.swift
// A crash-safe value wrapper that converts any runtime type to the requested type.
// Prevents crashes when the backend changes a field's data type (e.g. Int → String).
//
// KEY DESIGN: ZeroModelValue is itself @dynamicMemberLookup so that deeply nested
// JSON chains work without any intermediate .model accessor:
//
//   model.data.order.customer.address.city.string   ✅  (any depth)
//   model.data.order.items[0].discount.value.double ✅
//
// Each dot-access on a ZeroModelValue checks if the backing raw value is a
// ZeroModelInstance and forwards the lookup into it. If the raw value is a
// primitive (String, Int, etc.) and the key doesn't exist, it returns a
// ZeroModelValue(nil) — never crashes.

import Foundation

// MARK: - ZeroModelValue

/// A crash-safe dynamic value returned from any `ZeroModelInstance` property access.
///
/// Supports unlimited nesting via `@dynamicMemberLookup` — no `.model` hop needed:
///
///   model.data.order.customer.address.city.string
///   model.data.order.payment.billingAddress.postalCode.string
///   model.meta.apiVersion.string
///
/// Type conversion table (never crashes):
///   v.string   → converts from Int, Double, Bool, NSNumber
///   v.int      → converts from String ("123"), Double, Bool
///   v.double   → converts from String ("3.14"), Int, Bool
///   v.bool     → converts from Int (0/1), String ("true"/"false"/"yes"/"no")
///   v.array    → [ZeroModelValue] wrapping each element
///   v.model    → the underlying ZeroModelInstance (if this value IS a nested dict)
@dynamicMemberLookup
public struct ZeroModelValue {

    // MARK: - Internal Raw Storage

    let raw:       Any?
    let key:       String
    let modelName: String

    init(_ raw: Any?, key: String = "", modelName: String = "") {
        self.raw       = raw
        self.key       = key
        self.modelName = modelName
    }

    // MARK: - Existence Check

    /// `true` if the backing value is non-nil.
    public var exists: Bool {
        return raw != nil
    }

    /// `true` if the value is `NSNull` or nil.
    public var isNull: Bool {
        if raw == nil { return true }
        return raw is NSNull
    }

    // MARK: - String

    /// Returns the value as a `String`. Converts Int, Double, Bool gracefully.
    /// Returns `""` if conversion is not possible.
    public var string: String {
        switch raw {
        case let s as String:  return s
        case let i as Int:     return String(i)
        case let i as Int64:   return String(i)
        case let d as Double:  return String(d)
        case let f as Float:   return String(f)
        case let b as Bool:    return b ? "true" : "false"
        case let n as NSNumber: return n.stringValue
        default:               return ""
        }
    }

    /// Returns `String?` — nil if the value is absent or NSNull.
    public var optionalString: String? {
        return isNull ? nil : (raw == nil ? nil : string)
    }

    // MARK: - Int

    /// Returns the value as an `Int`. Converts String and Double gracefully.
    /// Returns `0` if conversion is not possible.
    public var int: Int {
        switch raw {
        case let i as Int:      return i
        case let i as Int64:    return Int(i)
        case let d as Double:   return Int(d)
        case let f as Float:    return Int(f)
        case let s as String:   return Int(s) ?? 0
        case let b as Bool:     return b ? 1 : 0
        case let n as NSNumber: return n.intValue
        default:                return 0
        }
    }

    /// Returns `Int?` — nil if the value is absent or NSNull.
    public var optionalInt: Int? {
        return isNull ? nil : (raw == nil ? nil : int)
    }

    // MARK: - Double

    /// Returns the value as a `Double`. Converts String and Int gracefully.
    /// Returns `0.0` if conversion is not possible.
    public var double: Double {
        switch raw {
        case let d as Double:   return d
        case let f as Float:    return Double(f)
        case let i as Int:      return Double(i)
        case let i as Int64:    return Double(i)
        case let s as String:   return Double(s) ?? 0.0
        case let b as Bool:     return b ? 1.0 : 0.0
        case let n as NSNumber: return n.doubleValue
        default:                return 0.0
        }
    }

    /// Returns `Double?` — nil if the value is absent or NSNull.
    public var optionalDouble: Double? {
        return isNull ? nil : (raw == nil ? nil : double)
    }

    // MARK: - Float

    /// Returns the value as a `Float`.
    public var float: Float {
        return Float(double)
    }

    // MARK: - Bool

    /// Returns the value as a `Bool`. "true"/"1"/"yes" → true. "false"/"0"/"no" → false.
    /// Returns `false` if conversion is not possible.
    public var bool: Bool {
        switch raw {
        case let b as Bool:   return b
        case let i as Int:    return i != 0
        case let d as Double: return d != 0.0
        case let n as NSNumber: return n.boolValue
        case let s as String:
            let lower = s.lowercased()
            if ["true", "yes", "1"].contains(lower)  { return true }
            if ["false", "no", "0"].contains(lower) { return false }
            return false
        default: return false
        }
    }

    /// Returns `Bool?` — nil if the value is absent or NSNull.
    public var optionalBool: Bool? {
        return isNull ? nil : (raw == nil ? nil : bool)
    }

    // MARK: - Dynamic Member Lookup (enables unlimited nesting)

    /// Forwards property access into the underlying `ZeroModelInstance` when this
    /// value wraps a nested dictionary. Returns `ZeroModelValue(nil)` safely if
    /// this value is a primitive or the key doesn't exist — never crashes.
    ///
    /// This is what makes the following work at any depth:
    ///   model.data.order.customer.address.city.string
    public subscript(dynamicMember member: String) -> ZeroModelValue {
        // If the raw value IS a nested model instance, forward into it
        if let instance = raw as? ZeroModelInstance {
            return instance[dynamicMember: member]
        }
        // Otherwise return an empty value — safe default, no crash
        return ZeroModelValue(nil, key: member, modelName: "\(modelName).\(key)")
    }

    // MARK: - Array

    /// Returns the value as an array of `ZeroModelValue`.
    /// Each element supports further dot-chaining if it wraps a nested dict.
    /// Empty array if the value is not an array type.
    ///
    ///   model.data.order.items.array[0].productName.string
    ///   model.data.order.items.array[0].discount.value.double
    public var array: [ZeroModelValue] {
        // Array of ZeroModelInstance (produced by resolvedValue in ZeroModelInstance)
        if let instances = raw as? [ZeroModelInstance] {
            return instances.map { ZeroModelValue($0, key: key, modelName: modelName) }
        }
        // Fallback: raw [Any] array (primitives)
        if let arr = raw as? [Any] {
            return arr.map { ZeroModelValue($0, key: key, modelName: modelName) }
        }
        return []
    }

    /// Returns `true` if the backing value is an array.
    public var isArray: Bool {
        return raw is [ZeroModelInstance] || raw is [Any]
    }

    /// Subscript access into array values.
    ///   model.data.order.items[0].productName.string
    public subscript(index: Int) -> ZeroModelValue {
        let elements = array
        guard index >= 0, index < elements.count else {
            return ZeroModelValue(nil, key: "\(key)[\(index)]", modelName: modelName)
        }
        return elements[index]
    }

    // MARK: - Nested Model

    /// Returns the underlying `ZeroModelInstance` when this value wraps a nested dict.
    /// Useful when you want to pass a nested model as a parameter.
    /// For simple chaining, prefer dot-syntax: `model.data.order.customer.city`
    public var model: ZeroModelInstance {
        if let instance = raw as? ZeroModelInstance {
            return instance
        }
        return ZeroModelInstance(name: "\(modelName).\(key)_empty", cacheManager: nil)
    }

    /// Returns `true` if the backing value is a nested `ZeroModelInstance`.
    public var isModel: Bool {
        return raw is ZeroModelInstance
    }

    // MARK: - Raw

    /// Returns the original raw `Any?` value as-is.
    public var rawValue: Any? {
        return raw
    }
}

// MARK: - CustomStringConvertible

extension ZeroModelValue: CustomStringConvertible {
    /// Allows `label.text = "\(ZeroModel.loginModel.userId)"` to work naturally.
    public var description: String {
        return string
    }
}

// MARK: - ExpressibleByStringLiteral (for comparisons)

extension ZeroModelValue: Equatable {
    public static func == (lhs: ZeroModelValue, rhs: ZeroModelValue) -> Bool {
        return lhs.string == rhs.string
    }
}

// MARK: - Convenience String Interpolation

extension ZeroModelValue: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let raw = raw else { return "ZeroModelValue(nil) [\(modelName).\(key)]" }
        return "ZeroModelValue(\(raw)) [\(modelName).\(key)] → \"\(string)\""
    }
}
