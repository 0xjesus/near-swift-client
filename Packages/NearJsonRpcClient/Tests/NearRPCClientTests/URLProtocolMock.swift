import Foundation

private extension InputStream {
    func readAll() -> Data {
        open()
        defer { close() }
        var data = Data()
        var buf = [UInt8](repeating: 0, count: 4096)
        while hasBytesAvailable {
            let n = read(&buf, maxLength: buf.count)
            if n > 0 { data.append(buf, count: n) } else { break }
        }
        return data
    }
}

final class URLProtocolMock: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = URLProtocolMock.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            // ✅ Convierte httpBodyStream → httpBody si hace falta
            var enriched = request
            if enriched.httpBody == nil, let s = enriched.httpBodyStream {
                enriched.httpBody = s.readAll()
            }

            let (resp, data) = try handler(enriched)
            client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
