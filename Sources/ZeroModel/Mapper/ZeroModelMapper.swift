// ZeroModelMapper.swift
// JSON key transformation and response normalisation utilities.

import Foundation

// MARK: - ZeroModelMapper

/// Utility responsible for transforming raw API responses before they are stored
/// in a `ZeroModelInstance`. Handles key coding style conversion and value normalisation.
internal enum ZeroModelMapper {

    // MARK: - Key Transformation

    /// Transforms all keys in `json` according to the global `keyCodingStyle`.
    static func transformKeys(
        in json: [String: Any],
        style: ZeroModelKeyCodingStyle
    ) -> [String: Any] {
        switch style {
        case .camelCase:
            return Dictionary(uniqueKeysWithValues: json.map { key, value in
                (key.zm_camelCased(), value)
            })
        case .none:
            return json
        }
    }

    // MARK: - Value Normalisation

    /// Recursively walks `json` and normalises values:
    /// - `NSNull`      → kept (represented as `.isNull` in `ZeroModelValue`)
    /// - Nested dicts  → left for `ZeroModelInstance.map(from:)` to wrap
    /// - Everything else → passed through unchanged
    static func normalise(_ json: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in json {
            switch value {
            case let nested as [String: Any]:
                result[key] = normalise(nested)
            case let array as [[String: Any]]:
                result[key] = array.map { normalise($0) }
            default:
                result[key] = value
            }
        }
        return result
    }
}
