// ZeroModelError.swift
// All error types that ZeroModel can emit.

import Foundation

// MARK: - ZeroModelError

/// Errors emitted by the ZeroModel network and mapping layers.
public enum ZeroModelError: Error, LocalizedError {

    /// The provided URL string is invalid or malformed.
    case invalidURL(String)

    /// A network-level error (e.g. no internet, timeout).
    case networkError(Error)

    /// The server returned a non-2xx HTTP status code.
    case httpError(statusCode: Int)

    /// The response body was empty.
    case emptyResponse

    /// JSON parsing or mapping failed.
    case parsingError(String)

    /// The model was not found in the registry.
    case modelNotFound(String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "[ZeroModel] Invalid URL: \(url)"
        case .networkError(let underlying):
            return "[ZeroModel] Network error: \(underlying.localizedDescription)"
        case .httpError(let code):
            return "[ZeroModel] HTTP error: \(code)"
        case .emptyResponse:
            return "[ZeroModel] Empty response body."
        case .parsingError(let detail):
            return "[ZeroModel] Parsing error: \(detail)"
        case .modelNotFound(let name):
            return "[ZeroModel] Model not found: \(name)"
        }
    }
}
