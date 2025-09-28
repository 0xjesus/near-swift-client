#!/usr/bin/env bash
set -euo pipefail

echo "=== 0) Environment ========================================"
swift --version || true
uname -a || true
echo

echo "=== 1) SwiftPM targets & deps =============================="
swift package describe | sed -n '1,200p'
echo

echo "=== 2) Ubicación real de fuentes NearJsonRpcTypes =========="
echo "(para detectar rutas correctas y nombres de archivos)"
find Packages/NearJsonRpcTypes/Sources -type f -maxdepth 3 -print | sort
echo

echo "=== 3) Declaraciones de tipos que buscamos (con visibilidad) ==="
# Imprime líneas de declaración y 2 líneas de contexto
grep -RInE '^(public|internal|fileprivate|private)?\s*(enum|struct|typealias)\s+(RPC(RequestID|Params|RequestEnvelope|ResponseEnvelope)\b|RequestID\b|Params\b)' \
  Packages/NearJsonRpcTypes/Sources || echo "No se encontraron declaraciones con esos nombres"

echo
echo "— Posibles equivalentes genéricos de envelopes:"
grep -RInE 'struct\s+RPC(RequestEnvelope|ResponseEnvelope)\s*<' Packages/NearJsonRpcTypes/Sources || echo "No se ven envelopes genéricos (o nombre distinto)"
echo

echo "=== 4) ¿Existen alias que cambien nombres? ================="
grep -RInE 'typealias\s+(RPC(RequestID|Params)|RequestID|Params)\b' Packages/NearJsonRpcTypes/Sources || echo "No se ven typealias para esos nombres"
echo

echo "=== 5) Contenido (cabecera) de archivos probables =========="
# Muestra las primeras 120 líneas de archivos clave si existen
for f in \
  Packages/NearJsonRpcTypes/Sources/**/RPCEnvelope.swift \
  Packages/NearJsonRpcTypes/Sources/**/RPCTypes.swift \
  Packages/NearJsonRpcTypes/Sources/**/RPCParams.swift \
  Packages/NearJsonRpcTypes/Sources/**/BasicTypes.swift \
  ; do
  if [[ -f "$f" ]]; then
    echo "--- $f (primeras 120 líneas) ---"
    sed -n '1,120p' "$f"
    echo
  fi
done

echo "=== 6) ¿Los tests importan @testable NearJsonRpcTypes? ====="
grep -RInH '@testable\s+import\s+NearJsonRpcTypes' Packages/NearJsonRpcTypes/Tests || echo "⚠️ Ningún @testable import NearJsonRpcTypes encontrado en tests de tipos"
echo "— Imports simples (por si algún test olvidó el @testable):"
grep -RInH '^import\s+NearJsonRpcTypes' Packages/NearJsonRpcTypes/Tests || true
echo

echo "=== 7) Dependencias del target de tests (JSON) ============="
# Dump JSON para revisar que NearJsonRpcTypes está como dependencia del target de tests
swift package dump-package > .build/pkg.json
sed -n '1,200p' .build/pkg.json | sed 's/\\u003e/>/g'
echo
echo "TIP: busca en el JSON el objeto del target de tests de tipos y confirma que 'dependencies' incluye 'NearJsonRpcTypes'."

echo
echo "=== 8) Resumen rápido ======================================"
echo "Si los tipos no aparecen en (3):"
echo "  • Revisa si el nombre es distinto (p.ej. RequestId vs RPCRequestID)."
echo "  • Mira si están marcados 'internal' y los tests NO usan '@testable import NearJsonRpcTypes'."
echo "  • Si los envelopes son genéricos (ver (3) y (5)), los tests deben indicar el parámetro de tipo al decodificar."
echo "============================================================"
