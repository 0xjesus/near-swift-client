// ForceSlashTransport.swift  
// File: Packages/NearJsonRpcClient/Sources/NearJsonRpcClient/ForceSlashTransport.swift

import Foundation
import OpenAPIRuntime
import HTTPTypes

/// Custom transport that forces all requests to use "/" path for JSON-RPC compatibility
public struct ForceSlashTransport: ClientTransport {
    private let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        
        var components = URLComponents(url: self.baseURL, resolvingAgainstBaseURL: false)!
        components.path = "/"

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = request.method.rawValue

        for header in request.headerFields {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.name.rawName)
        }
        // Force JSON-RPC headers
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            urlRequest.httpBody = try await Data(collecting: body, upTo: .max)
        }
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        let openAPIResponse = HTTPResponse(
            status: .init(code: httpResponse.statusCode),
            headerFields: .init(httpResponse.allHeaderFields.map { (key, value) in
                // swiftlint:disable:next force_cast
                .init(name: .init(key as! String)!, value: value as! String)
            })
        )

        return (openAPIResponse, data.isEmpty ? nil : HTTPBody(data))
    }
    
    // MARK: - Additional method for tests
    
    /// Convenience method for posting JSON (used by tests)
    public func postJSON(body: Data, headers: [String: String] = [:]) async throws -> Data {
        var components = URLComponents(url: self.baseURL, resolvingAgainstBaseURL: false)!
        components.path = "/"
        
        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        for (key, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        urlRequest.httpBody = body
        
        let (data, _) = try await session.data(for: urlRequest)
        return data
    }
}