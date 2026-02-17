// ZeroModelDebug.swift
// Debug utilities for inspecting the live state of ZeroModel instances.
// Useful during development — strip from Release builds with #if DEBUG if preferred.

import Foundation

// MARK: - ZeroModelDebug

public enum ZeroModelDebug {

    // MARK: - Print Model State

    /// Prints all current key-value pairs in a model to the console.
    ///
    ///     ZeroModelDebug.print(ZeroModel.loginModel)
    ///
    public static func print(_ model: ZeroModelInstance) {
        var output = "\n┌─── ZeroModel Debug: \(model.name) ───\n"
        if model.allKeys.isEmpty {
            output += "│  (empty — no values mapped yet)\n"
        } else {
            for key in model.allKeys.sorted() {
                let value: ZeroModelValue = model[dynamicMember: key]
                let typeLabel = typeDescription(of: value.rawValue)
                output += "│  \(key): \(value.string)  (\(typeLabel))\n"
            }
        }
        output += "└──────────────────────────────────"
        Swift.print(output)
    }

    /// Prints all registered model names and their key counts.
    ///
    ///     ZeroModelDebug.printAll()
    ///
    public static func printAll() {
        let names = ZeroModel.shared.registeredModelNames
        Swift.print("\n[ZeroModelDebug] \(names.count) model(s) registered: \(names.joined(separator: ", "))")
        for name in names {
            let model = ZeroModel.shared.instance(for: name)
            print(model)
        }
    }

    // MARK: - Snapshot

    /// Returns a plain dictionary snapshot of the model's current values.
    /// Useful for writing assertions in unit tests.
    public static func snapshot(of model: ZeroModelInstance) -> [String: String] {
        var result: [String: String] = [:]
        for key in model.allKeys {
            let value: ZeroModelValue = model[dynamicMember: key]
            result[key] = value.string
        }
        return result
    }

    // MARK: - Private

    private static func typeDescription(of value: Any?) -> String {
        guard let v = value else { return "nil" }
        switch v {
        case is String:           return "String"
        case is Int:              return "Int"
        case is Double:           return "Double"
        case is Float:            return "Float"
        case is Bool:             return "Bool"
        case is ZeroModelInstance:  return "NestedModel"
        case is [Any]:            return "Array"
        case is NSNull:           return "null"
        default:                  return String(describing: type(of: v))
        }
    }
}
