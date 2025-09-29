#!/usr/bin/env bash
# Gate de cobertura para funcionalidad "core" (Types + transporte)
# Ignora Generated, Scripts, Tests y el archivo NearJsonRpcClient.swift (capa de conveniencia).
# Uso: ./Scripts/coverage-core.sh [THRESHOLD]  # default 80

set -euo pipefail

THRESHOLD="${1:-80}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Reutiliza el script principal con un IGNORE más agresivo
export COVERAGE_IGNORE_REGEX="(.build|/Tests/|/Generated/|/Scripts/|NearJsonRpcClient/Sources/NearJsonRpcClient/NearJsonRpcClient.swift)"
bash "${ROOT}/Scripts/coverage-summary.sh" "${THRESHOLD}"
