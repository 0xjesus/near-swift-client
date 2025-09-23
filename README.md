````markdown
# NEAR Swift JSON-RPC Client

![CI](https://github.com/0xjesus/near-swift-client/actions/workflows/ci.yml/badge.svg)
![Release](https://github.com/0xjesus/near-swift-client/actions/workflows/release-please.yml/badge.svg)

A fully type-safe **Swift client for NEAR JSON-RPC**.  
Generated from the **OpenAPI spec** (patched for JSON-RPC via `POST /`) with best practices for Swift developers.

---

## Features
- ✅ Two Swift Packages
  - `NearJsonRpcTypes`: lightweight, type definitions + Codable serialization.
  - `NearJsonRpcClient`: RPC client built on top of `Types`.
- ✅ Automatic conversion: `snake_case` → `camelCase`.
- ✅ CI/CD: build, test, regeneration, and automated release with GitHub Actions.
- ✅ MIT licensed, open-source, community driven.

---

## Installation (SwiftPM)

In Xcode:
1. Go to **File > Add Packages…**
2. Add repository URL:

```text
https://github.com/0xjesus/near-swift-client
````

Products available:

* `NearJsonRpcTypes`
* `NearJsonRpcClient`

---

## Quick Start

```swift
import NearJsonRpcClient
import NearJsonRpcTypes

let client = NearJsonRpcClient(.init(endpoint: URL(string:"https://rpc.testnet.near.org")!))

Task {
    do {
        let latest = try await client.block(.init(finality: .final))
        print("Block height:", latest.header?.height ?? 0)

        let account = try await client.viewAccount(.init(
            accountId: "account.rpc-examples.testnet",
            finality: .final
        ))
        print("Account balance:", account.amount?.value ?? "0")
    } catch {
        print("RPC Error:", error)
    }
}
```

---

## Development

### Build & Test

```bash
swift build
swift test --enable-code-coverage
```

### Smoke Test RPC

```bash
./Scripts/fetch-openapi.sh
swift run
```

---

## Regeneration Workflow

The client and types are auto-generated from the NEAR **OpenAPI spec**.

* **Manual regeneration:**

  ```bash
  gh workflow run manual-regenerate.yml
  ```
* **Nightly regeneration:** runs daily via CI.
* **Release automation:** handled via `release-please`.

---

## Contributing

We welcome PRs!
See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

[MIT](LICENSE)

```
```
