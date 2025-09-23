# NEAR Swift SDK: NearJsonRpcClient + NearJsonRpcTypes

Cliente **type-safe** para el **JSON-RPC** de NEAR en Swift. Generación automática desde **OpenAPI** con **consolidación de paths -> “/”** (compatibilidad con JSON‑RPC).

## Instalación (SPM)
En Xcode: File > Add Packages… y añade `https://github.com/<tu-org>/near-swift-client`.  
Productos: `NearJsonRpcClient`, `NearJsonRpcTypes`.

## Uso rápido
```swift
import NearJsonRpcClient
import NearJsonRpcTypes

let client = NearJsonRpcClient(.init(endpoint: URL(string:"https://rpc.testnet.near.org")!))

let latest = try await client.block(.init(finality: .final))
print(latest.header?.height ?? 0)

let account = try await client.viewAccount(.init(accountId: "account.rpc-examples.testnet", finality: .final))
print(account.amount?.value ?? "0")
## QuickStart (macOS)

```bash
swift build
swift test --enable-code-coverage
```

### Smoke RPC (mainnet)
```bash
```
