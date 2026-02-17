// String+ZeroModel.swift
// String extension helpers used internally by ZeroModel.
// All methods are prefixed with `zm_` to avoid conflicts with app code.

import Foundation

internal extension String {

    // MARK: - Key Conversion

    /// Converts a snake_case, kebab-case, or PascalCase string to camelCase.
    ///
    /// Examples:
    ///   "user_id"       → "userId"
    ///   "first-name"    → "firstName"
    ///   "UserEmail"     → "userEmail"
    ///   "userId"        → "userId"  (already camel — no change)
    func zm_camelCased() -> String {
        guard !self.isEmpty else { return self }

        // Handle snake_case and kebab-case
        if self.contains("_") || self.contains("-") {
            let separator: Character = self.contains("_") ? "_" : "-"
            let components = self.split(separator: separator).map { String($0) }
            guard let first = components.first else { return self }
            let rest = components.dropFirst().map { $0.zm_capitalised() }
            return ([String(first).zm_lowercasedFirst()] + rest).joined()
        }

        // Handle PascalCase → camelCase
        return self.zm_lowercasedFirst()
    }

    /// Returns a copy with only the first character lowercased.
    func zm_lowercasedFirst() -> String {
        guard let first = self.first else { return self }
        return first.lowercased() + self.dropFirst()
    }

    /// Returns a copy with only the first character uppercased.
    func zm_capitalised() -> String {
        guard let first = self.first else { return self }
        return first.uppercased() + self.dropFirst()
    }

    // MARK: - Validation

    /// Returns `true` if the string is a valid non-empty model name (alphanumeric + underscore).
    var zm_isValidModelName: Bool {
        guard !self.isEmpty else { return false }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        return self.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}
