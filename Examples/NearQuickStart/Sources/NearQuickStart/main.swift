import Foundation
import NearJsonRpcClient
import NearJsonRpcTypes

@main
struct App {
    static func main() async throws {
        guard let urlString = ProcessInfo.processInfo.environment["NEAR_RPC_URL"],
              let url = URL(string: urlString)
        else {
            print("Set NEAR_RPC_URL, e.g. https://rpc.testnet.near.org")
            return
        }

        let client = NearJsonRpcClient(.init(endpoint: url))
        _ = client // evitar warning de variable no usada

        print("NEAR JSON-RPC client initialized for \(url.absoluteString)")

        // (Opcional) si tienes un método generado como gasPrice(), descomenta y prueba:
        /*
         do {
           let result = try await client.gasPrice(blockId: nil)
           print("gas_price = \(result.price)")
         } catch {
           print("gasPrice() failed: \(error)")
         }
         */
    }
}
