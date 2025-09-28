#!/usr/bin/env bash
set -euo pipefail

# 1) Ejecuta pruebas con cobertura si no hay perfiles
if ! find .build -type f -name '*.profraw' -print -quit >/dev/null 2>&1; then
  swift test --enable-code-coverage
fi

# 2) Localiza el binario de tests
BIN_PATH="$(swift build --show-bin-path)"
TEST_BIN="$(find "$BIN_PATH" -type f -name 'near-swift-clientPackageTests' -print -quit)"
if [[ -z "${TEST_BIN:-}" ]]; then
  echo "❌ No se encontró el binario de tests"; exit 1
fi

# 3) Fusiona perfiles
OUT_DIR=".build/coverage"
mkdir -p "$OUT_DIR"

# Usamos xargs -0 para evitar problemas con espacios/nuevas líneas
find .build -type f -name '*.profraw' -print0 \
| xargs -0 xcrun llvm-profdata merge -sparse -o "$OUT_DIR/merged.profdata"

# 4) Reporte por archivo (ignora build/tests/generated/scripts)
xcrun llvm-cov report "$TEST_BIN" \
  -instr-profile="$OUT_DIR/merged.profdata" \
  -ignore-filename-regex='(\.build|/Tests/|/Generated/|/Scripts/)'
