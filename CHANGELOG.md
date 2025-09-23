# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),  
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.1] - 2025-09-23
### Added
- Initial release of **NEAR Swift JSON-RPC Client** 🎉
- Two Swift Packages:
  - `NearJsonRpcTypes` → types, Codable serialization, aliases.
  - `NearJsonRpcClient` → client implementation with RPC methods.
- CI/CD workflows for:
  - macOS build & test
  - OpenAPI regeneration (manual + nightly)
  - Automated releases (`release-please`)
- Documentation:
  - README with QuickStart and contributing guide.
  - CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md
- Sanity tests for both packages.
- Example usage for RPC calls.

---

## [Unreleased]
### Planned
- Expand unit test coverage (target 80%+).
- Add integration tests against NEAR testnet/mainnet.
- Improve developer documentation and code comments.
- Swift Package Index submission.
