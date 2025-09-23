#!/usr/bin/env zsh
set -euo pipefail

SRC="Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes"
BR="$SRC/NearTypesBridge.swift"

have_def() { grep -R -E '(^|[[:space:]])(struct|typealias)[[:space:]]+'"$1"'\b' "$SRC" >/dev/null 2>&1; }

echo "== 1) Asegurar archivo bridge =="
if [[ ! -f "$BR" ]]; then
  mkdir -p "$SRC"
  echo 'import Foundation' > "$BR"
fi

echo "== 2) Añadir typealias mínimos si faltan =="
if ! have_def ProtocolConfig; then
  echo 'public typealias ProtocolConfig = JSONValue' >> "$BR"
  echo "   + ProtocolConfig = JSONValue"
fi
if ! have_def GenesisConfig; then
  echo 'public typealias GenesisConfig = JSONValue' >> "$BR"
  echo "   + GenesisConfig = JSONValue"
fi

echo "== 3) Limpiar caché y compilar =="
swift package reset >/dev/null 2>&1 || true
rm -rf .build
swift build

echo "== ✅ OK =="
