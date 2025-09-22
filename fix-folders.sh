#!/bin/bash

set -euo pipefail

echo "1) Backup de near-swift-sdk/ (si existe)..."
if [ -d near-swift-sdk ]; then
  mkdir -p .backup/near-swift-sdk
  rsync -a --delete near-swift-sdk/ .backup/near-swift-sdk/
  echo "   🔒 Backup en .backup/near-swift-sdk"
fi

echo "2) Mover contenido útil de near-swift-sdk/ -> repo raíz (merge si aplica)..."
for d in Packages Scripts Documentation Examples Package.swift README.md LICENSE; do
  if [ -e near-swift-sdk/$d ]; then
    echo "   ↪ moviendo near-swift-sdk/$d -> $d"
    rsync -a near-swift-sdk/$d ./ || true
  fi
done

echo "3) Quitar marca de submódulo si existe..."
# Intento suave: quitar del index sin borrar del disco.
git rm -r --cached near-swift-sdk 2>/dev/null || true
# Si estaba inicializado como submódulo, desinicializa y quita duro.
git submodule deinit -f near-swift-sdk 2>/dev/null || true
git rm -f near-swift-sdk 2>/dev/null || true
rm -rf .git/modules/near-swift-sdk 2>/dev/null || true

# Limpia .gitmodules si tenía entrada
if [ -f .gitmodules ]; then
  git config -f .gitmodules --remove-section submodule.near-swift-sdk 2>/dev/null || true
  sed -i.bak '/\[submodule "near-swift-sdk"\]/,/^$/d' .gitmodules || true
  rm -f .gitmodules.bak
fi

echo "4) Borrar carpeta residual near-swift-sdk/"
rm -rf near-swift-sdk

echo "5) Asegurar que Package.swift se llama near-swift-client (no near-swift-sdk)"
if [ -f Package.swift ] && grep -q 'name: "near-swift-sdk"' Package.swift; then
  sed -i.bak 's/name: "near-swift-sdk"/name: "near-swift-client"/' Package.swift
  rm -f Package.swift.bak
fi

echo "6) Reemplazar referencias textuales 'near-swift-sdk' -> 'near-swift-client' en docs/scripts (si alguna quedó)"
git grep -l 'near-swift-sdk' -- ':!fix-sdk-folders.sh' 2>/dev/null | xargs -r sed -i 's/near-swift-sdk/near-swift-client/g'

echo "7) Añadir y commitear"
git add -A
git commit -m "chore: remove stray near-swift-sdk submodule/folder; unify under near-swift-client"

echo "✅ Listo: repo unificado como 'near-swift-client' sin submódulos rotos."