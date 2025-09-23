#!/usr/bin/env bash
set -euo pipefail

SCHEMADIR="Scripts/schemas"
SCHEMA="$SCHEMADIR/near-openapi.json"
TMP="$SCHEMADIR/.near-openapi.tmp.json"

mkdir -p "$SCHEMADIR"

echo "→ Descargando OpenAPI (nearcore y fallbacks)…"
# Fuente 1 (nearcore): ajústala si cambia la ruta upstream
curl -fsSL -o "$TMP" https://raw.githubusercontent.com/near/nearcore/master/chain/jsonrpc/openrpc.json || true

# Fallbacks comunitarios (mantenlos en este orden)
if [[ ! -s "$TMP" ]]; then
  curl -fsSL -o "$TMP" https://raw.githubusercontent.com/near/nearcore/master/rpc/openrpc.json || true
fi
if [[ ! -s "$TMP" ]]; then
  curl -fsSL -o "$TMP" https://raw.githubusercontent.com/PolyProgrammist/near-openapi-client/main/openapi.json || true
fi

test -s "$TMP" || { echo "ERROR: no fue posible descargar OpenAPI"; exit 2; }

echo "→ Parcheando para JSON‑RPC en POST '/'" 
# Si tienes jq, limpiamos paths y forzamos único endpoint '/'
if command -v jq >/dev/null 2>&1; then
  jq '
    # borra todos los paths, deja solo "/"
    .paths = { "/": { "post": { "summary": "NEAR JSON-RPC (batched)", "operationId": "rpc", "responses": { "200": { "description": "OK" }}}}} 
  ' "$TMP" > "$SCHEMA"
else
  # Sin jq, copiado directo (el cliente ya fuerza "/")
  mv "$TMP" "$SCHEMA"
fi

echo "OK: $SCHEMA"
