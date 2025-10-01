#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPEC_URL="https://raw.githubusercontent.com/near/nearcore/master/chain/jsonrpc/openapi/openapi.json"

TYPES_PKG_PATH="Packages/NearJsonRpcTypes"
CLIENT_PKG_PATH="Packages/NearJsonRpcClient"
SPEC_FILENAME="openapi.yaml"

TYPES_SPEC_PATH="${TYPES_PKG_PATH}/Sources/NearJsonRpcTypes/${SPEC_FILENAME}"
CLIENT_SPEC_PATH="${CLIENT_PKG_PATH}/Sources/NearJsonRpcClient/${SPEC_FILENAME}"

echo "→ Downloading NEAR OpenAPI spec..."
curl -fsSL "${SPEC_URL}" -o "${TYPES_SPEC_PATH}"

if [[ ! -s "${TYPES_SPEC_PATH}" ]]; then
  echo "❌ ERROR: Spec download failed (empty file)."
  exit 1
fi

echo "→ Copying spec to client package..."
cp "${TYPES_SPEC_PATH}" "${CLIENT_SPEC_PATH}"

echo "→ Running Swift OpenAPI Generator directly..."

# ✅ CORRECCIÓN CLAVE:
# Generamos los 'types' (que incluye Schemas y Operations) con acceso 'public'.
# Así, el otro paquete (NearJsonRpcClient) puede verlos y usarlos.
swift run swift-openapi-generator generate \
  "${TYPES_SPEC_PATH}" \
  --mode types \
  --access-modifier public \
  --output-directory "${TYPES_PKG_PATH}/Sources/NearJsonRpcTypes/Generated"

# El generador para el cliente se queda igual. Genera su código como 'internal'.
swift run swift-openapi-generator generate \
  "${CLIENT_SPEC_PATH}" \
  --mode client \
  --output-directory "${CLIENT_PKG_PATH}/Sources/NearJsonRpcClient/Generated" \
  --additional-import NearJsonRpcTypes

echo "✅ Code generation complete."