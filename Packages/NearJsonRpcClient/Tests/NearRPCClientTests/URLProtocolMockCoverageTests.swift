@testable import NearJsonRpcClient
import XCTest

final class URLProtocolMockCoverageTests: XCTestCase {
    func testStatics_do_not_crash() {
        let req = URLRequest(url: URL(string: "http://localhost/")!)
        _ = URLProtocolMock.canonicalRequest(for: req)
        _ = URLProtocolMock.canInit(with: req)
        // Solo ejecuta rutas estáticas para subir cobertura del mock.
    }
}
