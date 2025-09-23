import Foundation

/// Transport que SIEMPRE hace POST "/" (requisito del bounty)
public final class ForceSlashTransport {
    private let baseURL: URL
    private let session: URLSession
    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    public func postJSON(body: Data, headers: [String:String] = [:]) async throws -> (Data, URLResponse) {
        var comps = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        comps.path = "/"
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "POST"
        req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        headers.forEach { k,v in req.setValue(v, forHTTPHeaderField: k) }
        return try await session.data(for: req)
    }
}
