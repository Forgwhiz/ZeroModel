// ZeroModelRequest.swift
// The network layer for ZeroModel.
// Wraps URLSession and automatically maps API responses into ZeroModelInstance objects.

import Foundation

// MARK: - HTTP Method

public enum ZeroModelHTTPMethod: String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case patch  = "PATCH"
    case delete = "DELETE"
}

// MARK: - ZeroModelRequestResult

/// The result returned to the developer's completion closure.
public enum ZeroModelRequestResult {
    /// The request succeeded. `model` is already populated.
    case success(model: ZeroModelInstance?, rawResponse: [String: Any])
    /// The request failed.
    case failure(error: ZeroModelError)
}

// MARK: - ZeroModelRequest

/// The primary API call interface for ZeroModel.
///
/// Usage (with model — auto-mapped before completion fires):
///
///     ZeroModelRequest.post(
///         url: "https://api.example.com/login",
///         params: ["email": "a@b.com", "password": "secret"],
///         model: ZeroModel.loginModel
///     ) { result in
///         switch result {
///         case .success:
///             print(ZeroModel.loginModel.userId)   // already populated
///         case .failure(let error):
///             print(error.localizedDescription)
///         }
///     }
///
/// Usage (without model — developer maps manually):
///
///     ZeroModelRequest.post(url:, params:) { result in
///         if case .success(_, let raw) = result {
///             ZeroModel.loginModel.map(from: raw)
///         }
///     }
///
public final class ZeroModelRequest {

    // MARK: - Convenience Static Methods

    public static func get(
        url:        String,
        params:     [String: Any]     = [:],
        headers:    [String: String]  = [:],
        model:      ZeroModelInstance?  = nil,
        completion: @escaping (ZeroModelRequestResult) -> Void
    ) {
        execute(method: .get, url: url, params: params, headers: headers, model: model, completion: completion)
    }

    public static func post(
        url:        String,
        params:     [String: Any]     = [:],
        headers:    [String: String]  = [:],
        model:      ZeroModelInstance?  = nil,
        completion: @escaping (ZeroModelRequestResult) -> Void
    ) {
        execute(method: .post, url: url, params: params, headers: headers, model: model, completion: completion)
    }

    public static func put(
        url:        String,
        params:     [String: Any]     = [:],
        headers:    [String: String]  = [:],
        model:      ZeroModelInstance?  = nil,
        completion: @escaping (ZeroModelRequestResult) -> Void
    ) {
        execute(method: .put, url: url, params: params, headers: headers, model: model, completion: completion)
    }

    public static func patch(
        url:        String,
        params:     [String: Any]     = [:],
        headers:    [String: String]  = [:],
        model:      ZeroModelInstance?  = nil,
        completion: @escaping (ZeroModelRequestResult) -> Void
    ) {
        execute(method: .patch, url: url, params: params, headers: headers, model: model, completion: completion)
    }

    public static func delete(
        url:        String,
        params:     [String: Any]     = [:],
        headers:    [String: String]  = [:],
        model:      ZeroModelInstance?  = nil,
        completion: @escaping (ZeroModelRequestResult) -> Void
    ) {
        execute(method: .delete, url: url, params: params, headers: headers, model: model, completion: completion)
    }

    // MARK: - Core Executor

    public static func execute(
        method:     ZeroModelHTTPMethod,
        url:        String,
        params:     [String: Any]     = [:],
        headers:    [String: String]  = [:],
        model:      ZeroModelInstance?  = nil,
        completion: @escaping (ZeroModelRequestResult) -> Void
    ) {
        guard let request = buildURLRequest(
            method: method, urlString: url, params: params, headers: headers
        ) else {
            complete(with: .failure(error: .invalidURL(url)), on: completion)
            return
        }

        ZeroModelLogger.log("→ \(method.rawValue) \(url)", level: .info)

        URLSession.shared.dataTask(with: request) { data, response, error in

            // Network error
            if let error = error {
                ZeroModelLogger.log("✗ \(url) — \(error.localizedDescription)", level: .error)
                complete(with: .failure(error: .networkError(error)), on: completion)
                return
            }

            // HTTP status check
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                ZeroModelLogger.log("✗ \(url) — HTTP \(http.statusCode)", level: .error)
                complete(with: .failure(error: .httpError(statusCode: http.statusCode)), on: completion)
                return
            }

            // Parse response body
            guard let data = data else {
                complete(with: .failure(error: .emptyResponse), on: completion)
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])

                if let dict = json as? [String: Any] {
                    // Auto-map into model BEFORE firing completion (if model was passed)
                    model?.map(from: dict)
                    ZeroModelLogger.log("✓ \(url) — mapped \(dict.keys.count) key(s) into \(model?.name ?? "no model")", level: .info)
                    complete(with: .success(model: model, rawResponse: dict), on: completion)

                } else if let array = json as? [[String: Any]] {
                    // Array response — map into model's "items" key
                    model?.map(from: array)
                    ZeroModelLogger.log("✓ \(url) — mapped array (\(array.count) item(s)) into \(model?.name ?? "no model")", level: .info)
                    complete(with: .success(model: model, rawResponse: ["items": array]), on: completion)

                } else {
                    complete(with: .failure(error: .parsingError("Unexpected JSON root type.")), on: completion)
                }

            } catch {
                ZeroModelLogger.log("✗ JSON parse error: \(error.localizedDescription)", level: .error)
                complete(with: .failure(error: .parsingError(error.localizedDescription)), on: completion)
            }

        }.resume()
    }

    // MARK: - Private Helpers

    private static func buildURLRequest(
        method:    ZeroModelHTTPMethod,
        urlString: String,
        params:    [String: Any],
        headers:   [String: String]
    ) -> URLRequest? {

        guard var urlComponents = URLComponents(string: urlString) else { return nil }

        var request: URLRequest

        if method == .get, !params.isEmpty {
            urlComponents.queryItems = params.map {
                URLQueryItem(name: $0.key, value: "\($0.value)")
            }
        }

        guard let finalURL = urlComponents.url else { return nil }
        request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.timeoutInterval = ZeroModel.shared.configuration.requestTimeout

        // Common headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Auth token injection
        if let token = ZeroModel.shared.configuration.authTokenProvider?() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Library-level common headers
        ZeroModel.shared.configuration.commonHeaders.forEach {
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        }

        // Call-site headers (override common headers if same key)
        headers.forEach {
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        }

        // Body for non-GET
        if method != .get, !params.isEmpty {
            request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        }

        return request
    }

    /// Always delivers completion on the main thread.
    private static func complete(
        with result: ZeroModelRequestResult,
        on completion: @escaping (ZeroModelRequestResult) -> Void
    ) {
        DispatchQueue.main.async { completion(result) }
    }
}
