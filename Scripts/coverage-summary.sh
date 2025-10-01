#!/usr/bin/env bash
# SwiftPM coverage gate (macOS/bash 3.2 compatible)
# Usage: ./Scripts/coverage-summary.sh [THRESHOLD]
# Default threshold: 80 (line coverage)

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

echo "▶️  Resolving paths…"
BINPATH="$(swift build --show-bin-path)"
CODECOV_DIR="${BINPATH}/codecov"
mkdir -p "${CODECOV_DIR}"

# Force .profraw dumps here (one file per process)
export LLVM_PROFILE_FILE="${CODECOV_DIR}/near-swift-client-%p.profraw"

echo "▶️  Running tests with coverage…"
swift test --enable-code-coverage > /dev/null

echo "▶️  Looking for profiles in ${CODECOV_DIR}…"
if ! ls -1 "${CODECOV_DIR}"/*.profraw >/dev/null 2>&1; then
  find "${BINPATH}" -type f -name '*.profraw' -exec cp {} "${CODECOV_DIR}/" \; || true
fi

if ! ls -1 "${CODECOV_DIR}"/*.profraw >/dev/null 2>&1; then
  find .build -type f -name '*.profraw' -exec cp {} "${CODECOV_DIR}/" \; || true
fi

if ! ls -1 "${CODECOV_DIR}"/*.profraw >/dev/null 2>&1; then
  echo "❌ No .profraw files found (did tests run?)."
  exit 1
fi

PROFDATA="${CODECOV_DIR}/merged.profdata"
echo "ℹ️  Merging profiles → ${PROFDATA}"
${LLVM_PROFDATA} merge -sparse "${CODECOV_DIR}"/*.profraw -o "${PROFDATA}"

TEST_BIN="$(find "${BINPATH}" -type f -path '*/near-swift-clientPackageTests.xctest/Contents/MacOS/*' -print -quit || true)"
if [ -z "${TEST_BIN}" ]; then
  TEST_BIN="$(find "${BINPATH}" -type f -name 'near-swift-clientPackageTests' -print -quit || true)"
fi
if [ -z "${TEST_BIN}" ]; then
  echo "❌ Could not find the test binary."
  exit 1
fi

# FIXED: Exclude dependencies, tests, and generated code
IGNORE_REGEX='(checkouts/|/Tests/|/Generated/|/Scripts/|\.build/x86_64.*derived/)'

echo "▶️  Per-file coverage report (excluding dependencies)…"
${LLVM_COV} report "${TEST_BIN}" -instr-profile "${PROFDATA}" -ignore-filename-regex "${IGNORE_REGEX}" || true

echo "▶️  Computing total line coverage…"
SUMMARY_JSON="${CODECOV_DIR}/summary.json"
if ! ${LLVM_COV} export "${TEST_BIN}" \
    -instr-profile "${PROFDATA}" \
    -ignore-filename-regex "${IGNORE_REGEX}" \
    -summary-only > "${SUMMARY_JSON}"; then
  echo "❌ llvm-cov export failed."
  exit 1
fi

PCT="$(/usr/bin/python3 - "${SUMMARY_JSON}" <<'PY'
import json,sys
with open(sys.argv[1]) as f:
  data=json.load(f)

totals = None
if isinstance(data, dict) and 'totals' in data:
  totals = data['totals']
elif isinstance(data, dict) and 'data' in data and data['data']:
  totals = data['data'][0].get('totals')

if not totals or 'lines' not in totals or 'percent' not in totals['lines']:
  print("")
  sys.exit(0)

pct = totals['lines']['percent']
try:
  print(int(round(float(pct))))
except Exception:
  print("")
PY
)"

if [ -z "${PCT}" ]; then
  echo "❌ Could not read line coverage."
  exit 1
fi

echo "ℹ️  Line coverage: ${PCT}%"
if [ "${PCT}" -lt "${THRESHOLD}" ]; then
  echo "❌ Coverage ${PCT}% is below threshold ${THRESHOLD}%"
  exit 1
fi

echo "✅ Coverage ${PCT}% ≥ ${THRESHOLD}% (OK)"
