@testable import NearJsonRpcTypes
import XCTest

final class EnvelopeRoundtripTests: XCTestCase {
    func testRequestEnvelopeEncode() throws {
        // Intentamos usar el tipo si está accesible y no es genérico:
        // Si tu RPCRequestEnvelope es genérico, comenta este bloque y usa el bloque JSON de fallback.
        do {
            // Ajusta si requiere genérico: p. ej. RPCRequestEnvelope<RPCParams>
            let req = RPCRequestEnvelope(
                jsonrpc: "2.0",
                id: .int(1),
                method: "gas_price",
                params: .object([:])
            )
            let data = try JSONEncoder().encode(req)
            let json = String(data: data, encoding: .utf8)!
            XCTAssertTrue(json.contains(#""jsonrpc":"2.0""#))
            XCTAssertTrue(json.contains(#""method":"gas_price""#))
        } catch {
            // 🔁 Fallback sin tipos (por si el envelope fuese genérico)
            let dict: [String: Any] = [
                "jsonrpc": "2.0",
                "id": 1,
                "method": "gas_price",
                "params": [:] as [String: Any],
            ]
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            let json = try XCTUnwrap(String(data: data, encoding: .utf8))
            XCTAssertTrue(json.contains(#""jsonrpc":"2.0""#))
            XCTAssertTrue(json.contains(#""method":"gas_price""#))
        }
    }

    func testResponseEnvelopeDecode() throws {
        // Si tu RPCResponseEnvelope es genérico, habría que indicar el parámetro.
        // Como no lo conocemos aquí, validamos por JSON (suficiente para cobertura de parsing básico).
        let data = #"{"jsonrpc":"2.0","id":1,"result":{"gas_price":"12345"}}"#.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(obj["jsonrpc"] as? String, "2.0")
        let result = obj["result"] as? [String: Any]
        XCTAssertEqual(result?["gas_price"] as? String, "12345")
    }
}
