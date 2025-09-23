````markdown
# Contributing to NEAR Swift JSON-RPC Client

We welcome contributions from the community! 🚀

---

## How to Contribute

1. **Fork** the repository on GitHub.
2. Create a new branch for your feature or fix:
   ```bash
   git checkout -b feat/my-feature
````

3. Make your changes following the [Code Style](#code-style) guidelines.
4. Commit using [Conventional Commits](https://www.conventionalcommits.org/):

   * `feat(types): add new struct for AccountBalance`
   * `fix(client): correct error handling in RPC calls`
   * `chore: update CI workflow`
5. Push your branch and open a **Pull Request** to `main`.

---

## Development Setup

### Requirements

* Swift 5.9 or later
* macOS 13+ or Linux with Swift toolchain
* GitHub CLI (`gh`) for workflow triggers (optional)

### Build & Test

```bash
swift build
swift test --enable-code-coverage
```

### Run RPC Smoke Test

```bash
swift run
```

---

## Code Style

* Use Swift’s native `Codable` for all serialization/deserialization.
* Prefer **`camelCase`** for Swift naming (auto-converted from API `snake_case`).
* Keep packages minimal and focused:

  * `NearJsonRpcTypes`: *types only*.
  * `NearJsonRpcClient`: *RPC methods only*.
* Always include **unit tests** for new types or client methods.

---

## Automated Workflows

* **CI (Swift CI):** builds and tests every push/PR.
* **Regeneration:** regenerates from OpenAPI spec (manual + nightly).
* **Release:** versioning and tagging are automated with `release-please`.

To run regeneration manually:

```bash
gh workflow run manual-regenerate.yml
```

---

## Reporting Issues

* Use the [GitHub Issues](https://github.com/0xjesus/near-swift-client/issues) page.
* Provide:

  * Steps to reproduce
  * Expected behavior
  * Actual behavior
  * Logs or screenshots if available

---

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).

```
```
