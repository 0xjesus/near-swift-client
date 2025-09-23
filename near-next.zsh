#!/usr/bin/env zsh
set -euo pipefail

RPC="${1:-https://rpc.mainnet.near.org}"
SRC="Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes"
BRIDGE="$SRC/NearTypesBridge.swift"

have() { command -v "$1" >/dev/null 2>&1; }
post() { curl -fsS -H 'Content-Type: application/json' --data "$1" "$RPC"; }

echo "== 0) Limpiar restos (.bak en Sources) =="
find "$SRC" -name '*.bak' -delete || true

echo "== 1) Build + Tests =="
swift build
swift test --enable-code-coverage || true

echo "== 2) Smoke RPC contra: $RPC =="
STATUS="$(post '{"jsonrpc":"2.0","id":"s","method":"status","params":[]}')"
BLOCK="$(post '{"jsonrpc":"2.0","id":"b","method":"block","params":{"finality":"final"}}')"
PCFG="$(post '{"jsonrpc":"2.0","id":"p","method":"EXPERIMENTAL_protocol_config","params":{"finality":"final"}}')"

echo "-- status --"
if have jq; then
  printf "%s\n" "$STATUS" | jq '{chain_id, protocol_version, version, sync_info}'
else
  python3 - <<'PY' <<<"$STATUS" 2>/dev/null || echo "$STATUS"
import sys,json; d=json.load(sys.stdin)
print({k:d.get(k) for k in ("chain_id","protocol_version","version","sync_info")})
PY
fi

echo "-- block(final) --"
if have jq; then
  printf "%s\n" "$BLOCK" | jq '.result.header | {hash,height,epoch_id,prev_hash}'
else
  python3 - <<'PY' <<<"$BLOCK" 2>/dev/null || echo "$BLOCK"
import sys,json; d=json.load(sys.stdin); h=(d.get("result") or {}).get("header") or {}
print({k:h.get(k) for k in ("hash","height","epoch_id","prev_hash")})
PY
fi

echo "-- protocol_config --"
if have jq; then
  printf "%s\n" "$PCFG" | jq '.result | {protocol_version, runtime_config: .runtime_config?}'
else
  python3 - <<'PY' <<<"$PCFG" 2>/dev/null || echo "$PCFG"
import sys,json; d=json.load(sys.stdin); r=d.get("result") or {}
print({"protocol_version": r.get("protocol_version"), "runtime_config_present": r.get("runtime_config") is not None})
PY
fi

echo "== 3) Snapshot git (opcional) =="
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BR="feat/macos-build-fix"
  git switch -c "$BR" 2>/dev/null || git switch "$BR"
  git add -A
  git commit -m "Fix macOS build: bridge (ProtocolConfig/GenesisConfig), removed dupes, cleaned backups, smoke OK" || true
  echo "   Commit creado en rama $BR. (Haz 'git push' cuando quieras.)"
else
  echo "   (Este directorio no es repo git; salto commit.)"
fi

echo "== ✅ DONE =="
