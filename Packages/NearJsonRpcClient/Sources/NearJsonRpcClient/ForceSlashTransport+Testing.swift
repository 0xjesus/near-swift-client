import Foundation

extension ForceSlashTransport {
    func makeURLRequest(path _: String, body: Data, headers: [String: String]) throws -> (URL, URLRequest) {
        let mirror = Mirror(reflecting: self)
        var base: URL? = nil
        for child in mirror.children {
            if let label = child.label,
               label == "endpoint" || label == "baseURL" || label == "baseUrl",
               let u = child.value as? URL
            {
                base = u
                break
            }
        }
        guard let baseURL = base else { throw URLError(.badURL) }
        var comps = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        comps.path = "/"
        guard let url = comps.url else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = body
        var merged = headers
        if merged["Content-Type"] == nil { merged["Content-Type"] = "application/json" }
        if merged["Accept"] == nil { merged["Accept"] = "application/json" }
        for (k, v) in merged {
            req.setValue(v, forHTTPHeaderField: k)
        }
        return (url, req)
    }
}
