#!/usr/bin/env zsh
set -euo pipefail

EQ="Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes/EquatableFixes.swift"
BR="Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes/NearTypesBridge.swift"
CS="Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes/CaseConversion.swift"

echo "== 1) Quitar el bloqueador de síntesis (EquatableFixes.swift) =="
if [[ -f "$EQ" ]]; then
  mkdir -p .backup
  mv "$EQ" ".backup/EquatableFixes.swift.$(date +%Y%m%d_%H%M%S)"
  echo "   movido a .backup/"
fi

echo "== 2) No exigir Equatable en ChunkView (bridge) =="
if [[ -f "$BR" ]]; then
  perl -0777 -pe 's/public\s+struct\s+ChunkView\s*:\s*Codable\s*,\s*Equatable\s*\{/public struct ChunkView: Codable {/' -i "$BR" || true
  perl -0777 -pe 's/public\s+struct\s+ChunkView\s*:\s*Equatable\s*,\s*Codable\s*\{/public struct ChunkView: Codable {/' -i "$BR" || true
fi

echo "== 3) (Opcional) Arreglar warning de Sendable heredado =="
if [[ -f "$CS" ]]; then
  sed -i '' -E 's/(JSONDecoder,)[[:space:]]*Sendable/\1 @unchecked Sendable/' "$CS" || true
  sed -i '' -E 's/(JSONEncoder,)[[:space:]]*Sendable/\1 @unchecked Sendable/' "$CS" || true
fi

echo "== 4) Clean build cache =="
swift package reset >/dev/null 2>&1 || true
rm -rf .build
find Packages -type f -path "*/Sources/*" \( -name "*.bak" -o -name "*~" -o -name "*.orig" \) -print -delete || true

echo "== 5) Build =="
swift build

echo "== 6) Smoke test (status y block final) =="
RPC_URL="${RPC_URL:-https://rpc.testnet.near.org}"
post() { curl -sS -X POST "$RPC_URL" -H 'Content-Type: application/json' --data-binary "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

STATUS='{"jsonrpc":"2.0","id":1,"method":"status"}'
BLOCK='{"jsonrpc":"2.0","id":2,"method":"block","params":{"finality":"final"}}'

SRES="$(post "$STATUS")"
BRES="$(post "$BLOCK")"

echo " - status:"
if have jq; then
  printf "%s\n" "$SRES" | jq '.result | {chain_id, chainId, latest_protocol_version, version}'
else
  python3 - <<'PY' 2>/dev/null || echo "$SRES"
import sys, json; d=json.load(sys.stdin); r=d.get("result",{})
print({"chain_id": r.get("chain_id") or r.get("chainId"),
       "latest_protocol_version": r.get("latest_protocol_version"),
       "version": r.get("version")})
PY
  <<< "$SRES"
fi

echo " - block(final):"
if have jq; then
  printf "%s\n" "$BRES" | jq '.result.header | {hash, height, epoch_id, prev_hash}'
else
  python3 - <<'PY' 2>/dev/null || echo "$BRES"
import sys, json; d=json.load(sys.stdin); h=(d.get("result") or {}).get("header") or {}
print({"hash": h.get("hash"), "height": h.get("height"), "epoch_id": h.get("epoch_id"), "prev_hash": h.get("prev_hash")})
PY
  <<< "$BRES"
fi

echo "== ✅ Listo =="
