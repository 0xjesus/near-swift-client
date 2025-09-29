#!/usr/bin/env bash
# Fetch NEAR OpenAPI/OpenRPC (single source, no fallbacks).
# Writes the schema to Scripts/schemas/near-openapi.json

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMAS_DIR="${ROOT}/Scripts/schemas"
OUT="${SCHEMAS_DIR}/near-openapi.json"
TMP="$(mktemp -t near-openapi.XXXXXX.json)"

mkdir -p "${SCHEMAS_DIR}"

URL="https://raw.githubusercontent.com/near/nearcore/master/chain/jsonrpc/openapi/openapi.json"

echo "→ Downloading OpenAPI from:"
echo "   ${URL}"
curl -fsSL "${URL}" -o "${TMP}"

if [[ ! -s "${TMP}" ]]; then
  echo "❌ Downloaded file is empty. Aborting."
  exit 1
fi

mv "${TMP}" "${OUT}"

# Nota: forzamos POST "/" de JSON‑RPC en el cliente (no parchamos el spec aquí).
echo "OK: Wrote ${OUT} (size: $(wc -c < "${OUT}") bytes)"
