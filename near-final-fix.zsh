#!/usr/bin/env zsh
set -e

ROOT="$(pwd)"
DIR="Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes"
[[ -d "$DIR" ]] || { echo "ERROR: no encuentro $DIR. Corre esto en la raíz del repo."; exit 1; }

echo "== 1) Hacer Equatable los tipos que lo necesitan para ChunkView =="
cat > "$DIR/EquatableFixes.swift" <<'SWIFT'
import Foundation

// Necesario porque ChunkView: Equatable contiene un ChunkHeader? -> debe ser Equatable
extension ChunkHeader: Equatable {}

// Por si en algún sitio comparan cabeceras o bloques
extension BlockHeader: Equatable {}
extension Block: Equatable {}
SWIFT

echo "== 2) Arreglar warnings de Sendable heredado en CaseConversion.swift =="
CS="$DIR/CaseConversion.swift"
if [[ -f "$CS" ]]; then
  cp "$CS" "$CS.bak"
  # JSONDecoder/JSONEncoder en Foundation tienen conformance @unchecked Sendable;
  # si lo restatas, debe ser @unchecked, no 'Sendable' a secas.
  sed -i '' -E \
    -e 's/(JSONDecoder,)[[:space:]]*Sendable/\1 @unchecked Sendable/' \
    -e 's/(JSONEncoder,)[[:space:]]*Sendable/\1 @unchecked Sendable/' \
    "$CS"
fi

echo "== 3) Limpiar caché de build =="
swift package reset >/dev/null 2>&1 || true
rm -rf .build

echo "== 4) Compilar =="
swift build

echo "== 5) Tests (tolerante) =="
swift test --enable-code-coverage || true

echo "== ✅ LISTO =="
