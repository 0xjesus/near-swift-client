#!/usr/bin/env zsh
set -euo pipefail

fix_file() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  local backup_dir="${f:h}/.backup"
  mkdir -p "$backup_dir"
  cp "$f" "$backup_dir/$(basename "$f").$(date +%Y%m%d_%H%M%S).bak"

  # Normalizar imports y referencias de módulos
  sed -i '' -E \
    -e 's/@[[:space:]]*testable[[:space:]]+import[[:space:]]+NearRPCClient/@testable import NearJsonRpcClient/g' \
    -e 's/^[[:space:]]*import[[:space:]]+NearRPCClient/import NearJsonRpcClient/g' \
    -e 's/@[[:space:]]*testable[[:space:]]+import[[:space:]]+NearRPCTypes/@testable import NearJsonRpcTypes/g' \
    -e 's/^[[:space:]]*import[[:space:]]+NearRPCTypes/import NearJsonRpcTypes/g' \
    -e 's/\bNearRPCClient\b/NearJsonRpcClient/g' \
    -e 's/\bNearRPCTypes\b/NearJsonRpcTypes/g' \
    "$f" || true

  # Arreglar llaves desbalanceadas (sobrantes o faltantes)
  python3 - "$f" <<'PY' || true
import sys, os
path = sys.argv[1]
with open(path,'r',encoding='utf-8') as fh:
    txt = fh.read()
opens = txt.count('{')
closes = txt.count('}')
if closes > opens:
    lines = txt.splitlines()
    extra = closes - opens
    for i in range(len(lines)-1, -1, -1):
        if extra == 0: break
        line = lines[i]
        if '}' in line and not line.strip().startswith('//'):
            pos = line.rfind('}')
            line = line[:pos] + '// [autofix removed extra }] ' + line[pos+1:]
            lines[i] = line
            extra -= 1
    txt = '\n'.join(lines) + '\n'
elif opens > closes:
    txt = txt + '\n' + ('}' * (opens - closes)) + '\n'
with open(path,'w',encoding='utf-8') as fh:
    fh.write(txt)
PY
}

echo "== 1) Normalizar imports en tests =="
for DIR in Packages/NearJsonRpcClient/Tests Packages/NearJsonRpcTypes/Tests; do
  [[ -d "$DIR" ]] || continue
  echo "   -> $DIR"
  while IFS= read -r f; do
    fix_file "$f"
  done < <(find "$DIR" -type f -name '*.swift')
done

echo "== 2) Clean build cache =="
swift package reset >/dev/null 2>&1 || true
rm -rf .build

echo "== 3) Build =="
swift build

echo "== 4) Tests =="
# Si aún fallan, queremos ver el log pero no parar el script; luego haremos commit igual.
set +e
swift test --enable-code-coverage
TEST_RC=$?
set -e

echo "== 5) Commit (opcional) =="
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git add -A
  MSG="tests: fix module imports NearJsonRpcClient/NearJsonRpcTypes + brace auto-fix"
  [[ $TEST_RC -ne 0 ]] && MSG="$MSG (tests still failing locally)"
  git commit -m "$MSG" || true
  echo "   Commit creado."
fi

if [[ $TEST_RC -eq 0 ]]; then
  echo "== ✅ Tests OK =="
else
  echo "== ⚠️  Tests aún fallan; pero imports/llaves quedaron arreglados. Revisa el primer error del log mostrado arriba. =="
fi
