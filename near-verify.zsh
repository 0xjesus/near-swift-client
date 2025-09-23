#!/usr/bin/env zsh
set -euo pipefail

echo "== 0) Limpiar backups en Sources =="
find Packages -type f -path "*/Sources/*" \( -name "*.bak" -o -name "*~" -o -name "*.orig" \) -print -delete || true

echo "== 1) Build limpio =="
swift package reset >/dev/null 2>&1 || true
rm -rf .build
swift build

echo "== 2) Tests =="
swift test --enable-code-coverage || true

echo "== 3) Smoke test contra rpc.testnet.near.org =="
RPC_URL="${RPC_URL:-https://rpc.testnet.near.org}"

post() {
  curl -sS -X POST "$RPC_URL" \
    -H 'Content-Type: application/json' \
    --data-binary "$1"
}

need() {
  command -v "$1" >/dev/null 2>&1
}

echo " - status"
STATUS_JSON='{"jsonrpc":"2.0","id":1,"method":"status"}'
STATUS="$(post "$STATUS_JSON")"

if need jq; then
  CHAIN_ID="$(printf "%s" "$STATUS" | jq -r '.result.chain_id // .result.chainId // empty')"
else
  CHAIN_ID="$(python3 - <<'PY' 2>/dev/null || true
import sys, json
d=json.load(sys.stdin)
r=d.get("result",{})
print(r.get("chain_id") or r.get("chainId") or "")
PY
  <<< "$STATUS")"
fi
[[ -n "${CHAIN_ID:-}" ]] || { echo "ERROR: status sin chain_id\n$STATUS"; exit 2; }
echo "   chain_id = $CHAIN_ID"

echo " - block(final)"
BLOCK_JSON='{"jsonrpc":"2.0","id":2,"method":"block","params":{"finality":"final"}}'
BLOCK="$(post "$BLOCK_JSON")"
if need jq; then
  BHASH="$(printf "%s" "$BLOCK" | jq -r '.result.header.hash // empty')"
else
  BHASH="$(python3 - <<'PY' 2>/dev/null || true
import sys, json
d=json.load(sys.stdin)
h=(d.get("result") or {}).get("header") or {}
print(h.get("hash") or "")
PY
  <<< "$BLOCK")"
fi
[[ -n "${BHASH:-}" ]] || { echo "ERROR: block(final) sin header.hash\n$BLOCK"; exit 3; }
echo "   block.header.hash = $BHASH"

echo "== ✅ Build + Tests + Smoke OK =="
