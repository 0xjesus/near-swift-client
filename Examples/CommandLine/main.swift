import Foundation
import NearJsonRpcClient
import NearJsonRpcTypes

@main
struct NEARCLIExample {
    static func main() async {
        print("🚀 NEAR Swift Client Example")
        print("=" * 40)
        
        do {
            let client = try NearJsonRpcClient(endpoint: "https://rpc.mainnet.near.org")
            
            // Get network status
            print("\n📊 Network Status:")
            let status = try await client.getNetworkStatus()
            if let version = status["version"] {
                print("  Version: \(version)")
            }
            
            // Get latest block
            print("\n📦 Latest Block:")
            let block = try await client.getBlock()
            print("  Height: \(block.header.height)")
            print("  Author: \(block.author)")
            
            // View an account
            print("\n👤 Account Info (near):")
            let account = try await client.viewAccount("near")
            print("  Balance: \(formatBalance(account.amount))")
            print("  Storage: \(account.storageUsage) bytes")
            
            // Get gas price
            print("\n⛽ Gas Price:")
            let gasPrice = try await client.getGasPrice()
            print("  Current: \(gasPrice)")
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    static func formatBalance(_ amount: String) -> String {
        guard let value = Double(amount) else { return amount }
        let near = value / 1e24
        return String(format: "%.4f NEAR", near)
    }
}

// Helper for string repetition
func *(left: String, right: Int) -> String {
    return String(repeating: left, count: right)
}
