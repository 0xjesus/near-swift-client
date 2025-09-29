@testable import NearJsonRpcClient
import NearJsonRpcTypes
import XCTest

final class ForceSlashTransportTests: XCTestCase {
    func testTransportForcesSlashPath() throws {
        let t = ForceSlashTransport(baseURL: URL(string: "https://rpc.mainnet.near.org")!)
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "rpc.mainnet.near.org"
        comps.path = "/should/be/ignored"
        let (url, _) = try t.makeURLRequest(path: comps.path, body: Data("{}".utf8), headers: [:]) // helper interno si existe
        XCTAssertEqual(url.path, "/") // path forzado a "/"
    }
}
