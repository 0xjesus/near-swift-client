# NEAR Swift JSON-RPC Client

[![CI](https://github.com/0xjesus/near-swift-client/actions/workflows/ci.yml/badge.svg)](https://github.com/0xjesus/near-swift-client/actions/workflows/ci.yml)
[![Coverage](https://github.com/0xjesus/near-swift-client/actions/workflows/coverage.yml/badge.svg)](https://github.com/0xjesus/near-swift-client/actions/workflows/coverage.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Type-safe Swift client for NEAR Protocol JSON-RPC API, auto-generated from the official OpenAPI specification with 80%+ test coverage and full CI automation.

## Features

- **Type-safe**: All RPC methods and responses fully typed with Swift structs/enums
- **Idiomatic Swift**: Automatic `snake_case` → `camelCase` conversion
- **Modern async/await**: Built on URLSession with native Swift concurrency
- **Two packages**: Lightweight types library + full-featured client
- **80%+ test coverage**: Comprehensive unit and integration tests
- **CI automation**: GitHub Actions for testing, coverage gates, and OpenAPI regeneration

## Packages

| Package | Description |
|---------|-------------|
| `NearJsonRpcTypes` | Type definitions and Codable serialization (no networking) |
| `NearJsonRpcClient` | HTTP client with ergonomic wrappers for all RPC methods |

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/0xjesus/near-swift-client.git", from: "0.1.1")
]
```

Or in Xcode: **File → Add Packages...** → paste repository URL.

## Quick Start

```swift
import NearJsonRpcClient
import NearJsonRpcTypes

let client = NearJsonRpcClient(.init(
    endpoint: URL(string: "https://rpc.testnet.near.org")!
))

// Get latest block
let latestBlock = try await client.block(blockReference: .finality(.final))
print("Latest block height:", latestBlock.header.height)

// Get block by height
let block = try await client.block(blockReference: .blockId(latestBlock.header.height - 100))
print("Block at height \(block.header.height) has hash: \(block.header.hash)")

// Query account
let account = try await client.viewAccount(accountId: "example.testnet")
print("Balance for example.testnet: \(account.amount)")

// Query account at a specific block
let accountAtBlock = try await client.viewAccount(
    accountId: "example.testnet",
    blockReference: .blockHash(block.header.hash)
)
print("Balance at block \(block.header.height): \(accountAtBlock.amount)")
```

## Development

### Build and Test

```bash
swift build
swift test --enable-code-coverage
```

### Check Coverage

```bash
./Scripts/coverage-summary.sh 80  # Requires ≥80% coverage
```

### Integration Tests

By default, tests use mocks. To test against live RPC:

```bash
export NEAR_RPC_URL="https://rpc.testnet.near.org"
swift test
```

## OpenAPI Code Generation

Types and client methods are generated from [NEAR's official OpenAPI spec](https://github.com/near/nearcore/blob/master/chain/jsonrpc/openapi/openapi.json).

### Regenerate Locally

```bash
# Fetch latest spec from nearcore repo
bash Scripts/fetch-openapi.sh

# Generate Swift code
swift Scripts/generate-from-openapi.swift

# Verify changes
swift test --enable-code-coverage
```

### Automated Regeneration

GitHub Actions automatically:
- Fetches latest OpenAPI spec (nightly + on-demand)
- Regenerates code if spec changed
- Runs full test suite
- Opens PR for review if changes detected

See [`.github/workflows/regen-openapi.yml`](.github/workflows/regen-openapi.yml)

## CI/CD Workflows

| Workflow | Purpose |
|----------|---------|
| **Swift CI** | Build, test, generate coverage artifacts |
| **Coverage Gate** | Enforce 80% minimum line coverage |
| **Lint** | SwiftFormat style checking |
| **Regenerate from OpenAPI** | Scheduled/manual code regeneration from spec |
| **Release Please** | Automated releases via conventional commits |

## Architecture

The generator patches the OpenAPI spec to work with JSON-RPC:
- **Problem**: OpenAPI spec defines unique paths per method (`/block`, `/status`, etc.)
- **Reality**: NEAR's JSON-RPC server expects all requests at `POST /`
- **Solution**: Transport layer forces `POST /` while preserving typed parameters

## Contributing

1. Use conventional commit format:
   ```
   feat(client): add new RPC method
   fix(types): correct deserialization
   ```

2. Ensure tests pass and coverage ≥80%:
   ```bash
   swift test --enable-code-coverage
   ./Scripts/coverage-summary.sh 80
   ```

3. Format code:
   ```bash
   swiftformat . --swiftversion 5.9
   ```

## License

MIT - see [LICENSE](LICENSE)

## Acknowledgments

This implementation follows patterns established by [near-jsonrpc-client-rs](https://github.com/near/near-jsonrpc-client-rs) and [near-api-js](https://github.com/near/near-api-js).
