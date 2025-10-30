import Foundation
import NearJsonRpcClient
import NearJsonRpcTypes

@main
struct QuickDemo {
    static func main() async throws {
        print("NEAR Swift Client Demo")
        print("======================\n")

        // Demonstrates package can be imported and used
        let client = NearJsonRpcClient(.init(
            endpoint: URL(string: "https://rpc.testnet.near.org")!
        ))

        print("✅ Package imported successfully")
        print("✅ Client initialized")
        print("✅ Types are available:", String(describing: Components.Schemas.RpcBlockRequest.self))

        print("\nPackage is ready to use!")
        print("For live examples, see the test suite in Tests/")
    }
}
