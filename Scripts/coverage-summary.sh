#!/usr/bin/env bash
# SwiftPM coverage gate (macOS/bash 3.2 compatible)
# Usage: ./Scripts/coverage-summary.sh [THRESHOLD]
# Default threshold: 80 (lines coverage)

set -euo pipefail

THRESHOLD="${1:-80}"

# Prefer xcrun tools on macOS
if command -v xcrun >/dev/null 2>&1; then
  LLVM_COV="xcrun llvm-cov"
  LLVM_PROFDATA="xcrun llvm-profdata"
else
  LLVM_COV="llvm-cov"
  LLVM_PROFDATA="llvm-profdata"
fi

echo "▶️  Resolviendo rutas…"
BINPATH="$(swift build --show-bin-path)"
CODECOV_DIR="${BINPATH}/codecov"
mkdir -p "${CODECOV_DIR}"

# Fuerza volcados .profraw aquí (un archivo por proceso)
export LLVM_PROFILE_FILE="${CODECOV_DIR}/near-swift-client-%p.profraw"

echo "▶️  Ejecutando tests con cobertura…"
swift test --enable-code-coverage > /dev/null

echo "▶️  Localizando perfiles en ${CODECOV_DIR}…"
if ! ls -1 "${CODECOV_DIR}"/*.profraw >/dev/null 2>&1; then
  # fallback: copia .profraw desde .build por si Swift los dejó fuera
  find "${BINPATH}" -type f -name '*.profraw' -exec cp {} "${CODECOV_DIR}/" \; || true
fi

if ! ls -1 "${CODECOV_DIR}"/*.profraw >/dev/null 2>&1; then
  echo "❌ No se encontraron .profraw (¿se ejecutaron tests?)."
  echo "   BINPATH=${BINPATH}"
  exit 1
fi

PROFDATA="${CODECOV_DIR}/merged.profdata"
echo "ℹ️  Fusionando perfiles → ${PROFDATA}"
${LLVM_PROFDATA} merge -sparse "${CODECOV_DIR}"/*.profraw -o "${PROFDATA}"

# Ubicar binario de tests
TEST_BIN="$(find "${BINPATH}" -type f -path '*/near-swift-clientPackageTests.xctest/Contents/MacOS/*' -print -quit || true)"
if [ -z "${TEST_BIN}" ]; then
  TEST_BIN="$(find "${BINPATH}" -type f -name 'near-swift-clientPackageTests' -print -quit || true)"
fi
if [ -z "${TEST_BIN}" ]; then
  echo "❌ No se encontró el binario de tests (near-swift-clientPackageTests)."
  exit 1
fi

# Ignorar rutas que no cuentan para el gate
IGNORE_REGEX="${COVERAGE_IGNORE_REGEX:-'(.build|/Tests/|/Generated/|/Scripts/)'}"

echo "▶️  Reportando cobertura por archivo…"
${LLVM_COV} report "${TEST_BIN}" -instr-profile "${PROFDATA}" -ignore-filename-regex "${IGNORE_REGEX}" || true

echo "▶️  Calculando cobertura total (líneas) con llvm-cov export…"
SUMMARY_JSON="${CODECOV_DIR}/summary.json"
if ! ${LLVM_COV} export "${TEST_BIN}" \
    -instr-profile "${PROFDATA}" \
    -ignore-filename-regex "${IGNORE_REGEX}" \
    -summary-only > "${SUMMARY_JSON}"; then
  echo "❌ llvm-cov export falló."
  exit 1
fi

# Extrae 'totals.lines.percent' con python3 (siempre presente en macOS reciente)
PCT="$(/usr/bin/python3 - "${SUMMARY_JSON}" <<'PY'
import json,sys
with open(sys.argv[1]) as f:
  data=json.load(f)
# llvm-cov export puede devolver 'data[0].totals' o 'totals' en versiones distintas
totals = None
if isinstance(data, dict) and 'totals' in data:
  totals = data['totals']
elif isinstance(data, dict) and 'data' in data and data['data']:
  totals = data['data'][0].get('totals')
if not totals or 'lines' not in totals or 'percent' not in totals['lines']:
  print("")
  sys.exit(0)
pct = totals['lines']['percent']
print(int(round(float(pct))))
PY
)"

if [ -z "${PCT}" ]; then
  echo "❌ No se pudo obtener el porcentaje de líneas desde ${SUMMARY_JSON}"
  exit 1
fi

echo "ℹ️  Cobertura (líneas): ${PCT}%"
if [ "${PCT}" -lt "${THRESHOLD}" ]; then
  echo "❌ Cobertura ${PCT}% < umbral ${THRESHOLD}%"
  exit 1
fi

echo "✅ Cobertura ${PCT}% ≥ ${THRESHOLD}% (OK)"
