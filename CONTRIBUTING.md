# Contributing to NEAR Swift Client

Thank you for your interest in contributing! 

## Development Setup

1. Clone the repository
2. Ensure you have Swift 5.9+ installed
3. Run `swift build` to verify setup

## Code Style

We use SwiftLint for code style. Run `swiftlint` before committing.

## Testing

- Write tests for new features
- Maintain 80%+ code coverage
- Run `swift test` before submitting PRs

## Pull Request Process

1. Fork and create a feature branch
2. Make your changes with tests
3. Update documentation as needed
4. Submit PR with clear description

## Code Generation

The client is partially auto-generated. To regenerate:

```bash
swift run generate-from-openapi
```

## Questions?

Join our [Telegram community](https://t.me/NEAR_Tools_Community_Group).
