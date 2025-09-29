# NEAR Swift JSON-RPC Client

[![CI](https://github.com/0xjesus/near-swift-client/actions/workflows/ci.yml/badge.svg)](https://github.com/0xjesus/near-swift-client/actions/workflows/ci.yml)
[![Coverage gate](https://github.com/0xjesus/near-swift-client/actions/workflows/coverage.yml/badge.svg)](https://github.com/0xjesus/near-swift-client/actions/workflows/coverage.yml)
[![Docs](https://img.shields.io/badge/DocC-Online-blue)](https://0xjesus.github.io/near-swift-client/)
[![Release Please](https://github.com/0xjesus/near-swift-client/actions/workflows/release-please.yml/badge.svg)](https://github.com/0xjesus/near-swift-client/actions/workflows/release-please.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Fully type-safe Swift client for NEAR JSON-RPC**, generated from the official OpenAPI spec and patched for JSON-RPC’s single `POST "/"` endpoint. Designed for mobile & server Swift with idiomatic APIs, strong types, and CI automation.

**📚 Docs:** https://0xjesus.github.io/near-swift-client/

---

## Packages

This repository contains two SwiftPM packages:

- **`NearJsonRpcTypes`** – lightweight models & `Codable` serialization/deserialization (no HTTP).
- **`NearJsonRpcClient`** – async/await HTTP client built on top of `NearJsonRpcTypes` with ergonomic wrappers.

Key features:
- Automatic `snake_case` ⇢ `camelCase` conversion.
- Async/await, `URLSession` based.
- Tolerant decoders for NEAR RPC nuances.
- Thorough unit tests, mockable networking, and coverage gates.

---

## Installation (Swift Package Manager)

**Xcode:** *File → Add Packages…* and use:
```

[https://github.com/0xjesus/near-swift-client](https://github.com/0xjesus/near-swift-client)

````

**Package.swift:**
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
        .iOS(.v15), .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/0xjesus/near-swift-client.git", from: "0.1.1")
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                .product(name: "NearJsonRpcTypes", package: "near-swift-client"),
                .product(name: "NearJsonRpcClient", package: "near-swift-client")
            ]
        )
    ]
)
````

---

## Quick Start

```swift
import NearJsonRpcClient
import NearJsonRpcTypes

// Create a client (testnet or mainnet endpoint)
let client = NearJsonRpcClient(
    .init(
        endpoint: URL(string: "https://rpc.testnet.near.org")!,
        timeout: 30,
        headers: ["User-Agent": "NearSwiftClient/0.1"]
    )
)

Task {
    do {
        // Example: get the latest block
        let block = try await client.block(.init(finality: .final))
        print("Block height:", block.header?.height ?? 0)

        // Example: view an account (typed result)
        let account = try await client.viewAccount(.init(
            accountId: "account.rpc-examples.testnet",
            finality: .final
        ))
        print("Account balance:", account.amount?.value ?? "0")
    } catch {
        print("RPC error:", error)
    }
}
```

> **JSON-RPC path patching:** The official OpenAPI lists unique paths per method, but NEAR’s server expects **`POST "/"`**. The generator/transport here forces `POST "/"` for all methods while keeping typed params/responses.

---

## Documentation

* **DocC (hosted):** [https://0xjesus.github.io/near-swift-client/](https://0xjesus.github.io/near-swift-client/)
* **Build locally:**

  ```bash
  swift package --disable-sandbox generate-documentation \
    --target NearJsonRpcClient \
    --output-path docs \
    --transform-for-static-hosting \
    --hosting-base-path near-swift-client
  open docs/index.html
  ```

---

## Development

### Build & Test

```bash
swift build
swift test --enable-code-coverage
```

### Coverage gates (local)

```bash
# Overall coverage gate (default 80%)
./Scripts/coverage-summary.sh 80

# “Core” coverage gate: NearJsonRpcTypes + transport (ignores Generated/Scripts/Tests and the high-level client façade)
./Scripts/coverage-core.sh 80
```

### Integration tests (optional)

By default tests use mocks. To run against a real endpoint, set:

```bash
export NEAR_RPC_URL="https://rpc.testnet.near.org"
swift test
```

---

## OpenAPI Regeneration

The client and types are generated from the **official NEAR OpenAPI**:

```
https://github.com/near/nearcore/blob/master/chain/jsonrpc/openapi/openapi.json
```

**Locally:**

```bash
# 1) Fetch the spec and patch paths to JSON-RPC POST "/"
bash Scripts/fetch-openapi.sh

# 2) Regenerate Swift types + client wrappers (includes snake→camel conversion)
swift Scripts/generate-from-openapi.swift

# 3) Build & test
swift build
swift test --enable-code-coverage
```

**CI Workflows:**

* **Regenerate from OpenAPI** (scheduled & manual): fetch latest spec, regenerate, run tests, and open a PR with changes if any.
* **Manual Regenerate (OpenAPI)**: on-demand regeneration from the Actions tab.

> Requires repository Actions with **read & write** permissions and “Allow GitHub Actions to create and approve pull requests”.

---

## CI/CD (GitHub Actions)

* **Swift CI** – build, test, coverage artifacts, and a hard gate (≥ 80%).
* **Coverage (gate 80%)** – fast coverage check using `llvm-cov export`.
* **Lint** – SwiftFormat in lint mode.
* **Publish Docs (GitHub Pages)** – generates DocC and deploys to `gh-pages`.
* **Regenerate from OpenAPI** – scheduled nightly and manual dispatch; opens PR when the spec changes.
* **Manual Regenerate (OpenAPI)** – one-click regeneration for maintainers.
* **Release Please** – conventional-commit based automated release PRs.
* **semantic-pr** – enforces conventional PR titles.

---

## Examples

See the `Examples/` folder for a command-line app, a quick-start sample, and a simple SwiftUI demo showing basic calls.

---

## Contributing

1. Use **conventional commit** titles, e.g.:

   * `feat(client): add XYZ`
   * `fix(types): correct U128 decode`
2. Run locally:

   ```bash
   swiftformat . --swiftversion 5.9   # mirrors CI lint
   swift test --enable-code-coverage
   ./Scripts/coverage-summary.sh 80
   ```
3. For codegen changes:

   ```bash
   bash Scripts/fetch-openapi.sh
   swift Scripts/generate-from-openapi.swift
   ```

Issues and PRs are welcome!

---

## License

**MIT** – see [LICENSE](LICENSE).

