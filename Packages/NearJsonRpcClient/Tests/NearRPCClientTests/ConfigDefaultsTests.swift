@testable import NearJsonRpcClient
import XCTest

final class ConfigDefaultsTests: XCTestCase {
    func testDefaultHeadersAndTimeout() {
        let url = URL(string: "https://rpc.testnet.near.org")!
        let cfg = NearJsonRpcClient.Config(endpoint: url)

        // Debe preservar Content-Type por defecto y timeout=30s
        XCTAssertEqual(cfg.headers["Content-Type"], "application/json")
        XCTAssertEqual(cfg.timeout, 30, "Default timeout should be 30s")
    }

    func testCustomHeadersMerge() {
        let url = URL(string: "https://rpc.testnet.near.org")!
        let cfg = NearJsonRpcClient.Config(
            endpoint: url,
            headers: ["Accept": "application/json", "Content-Type": "application/json"],
            timeout: 15
        )

        // Debe contener Accept y respetar Content-Type configurado
        XCTAssertEqual(cfg.headers["Accept"], "application/json")
        XCTAssertEqual(cfg.headers["Content-Type"], "application/json")
        XCTAssertEqual(cfg.timeout, 15)
    }
}
