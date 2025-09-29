#!/usr/bin/env bash
# Coverage gate for "core" functionality (Types + transport).
# Ignores Generated, Scripts, Tests, and the high-level convenience wrapper NearJsonRpcClient.swift.
# Usage: ./Scripts/coverage-core.sh [THRESHOLD]   # default 80

set -euo pipefail

THRESHOLD="${1:-80}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Reuse the main summary script with a stricter ignore list
export COVERAGE_IGNORE_REGEX="(.build|/Tests/|/Generated/|/Scripts/|NearJsonRpcClient/Sources/NearJsonRpcClient/NearJsonRpcClient.swift)"
bash "${ROOT}/Scripts/coverage-summary.sh" "${THRESHOLD}"
