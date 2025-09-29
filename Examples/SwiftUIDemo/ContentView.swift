import NearJsonRpcClient
import NearJsonRpcTypes
import SwiftUI

struct ContentView: View {
    @State private var accountId = "example.near"
    @State private var balance = "Loading..."
    @State private var isLoading = false

    private let client = try? NearJsonRpcClient(endpoint: "https://rpc.mainnet.near.org")

    var body: some View {
        VStack(spacing: 20) {
            Text("NEAR Account Viewer")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Account ID", text: $accountId)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: loadAccount) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Load Account")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || accountId.isEmpty)

            Text("Balance: \(balance)")
                .font(.title2)
                .padding()

            Spacer()
        }
        .padding()
    }

    func loadAccount() {
        guard let client else { return }

        isLoading = true

        Task {
            do {
                let account = try await client.viewAccount(accountId)
                await MainActor.run {
                    balance = formatBalance(account.amount)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    balance = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    func formatBalance(_ amount: String) -> String {
        // Convert from yoctoNEAR to NEAR (10^24)
        guard let value = Double(amount) else { return amount }
        let near = value / 1e24
        return String(format: "%.4f NEAR", near)
    }
}
