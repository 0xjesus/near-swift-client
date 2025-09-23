#!/bin/bash
# Shell Script para Limpieza y Reconstrucción del Proyecto en macOS

echo "--- Iniciando limpieza del proyecto ---"

# 1) Borrar scripts helpers y archivos temporales
echo "Borrando scripts (.zsh, .sh) y archivos de contexto..."
git rm -f *.zsh check_status.sh fix-folders.sh project_context_full.txt >/dev/null 2>&1 || true
rm -f *.zsh check_status.sh fix-folders.sh project_context_full.txt >/dev/null 2>&1

# 2) Borrar carpeta de helpers
if [ -d "bashScripts" ]; then
    echo "Borrando directorio 'bashScripts'..."
    git rm -r -f bashScripts >/dev/null 2>&1 || true
    rm -rf bashScripts
fi

# 3) Borrar backups (.bak) y carpetas (.backup)
echo "Buscando y eliminando archivos .bak y directorios .backup..."
git ls-files -z '*.bak' | xargs -0 git rm -f >/dev/null 2>&1 || true
find . -type f -name '*.bak' -delete
find . -type d -name '.backup' -exec rm -rf {} +

# 4) Limpiar README
echo "Limpiando referencia a 'near-verify.zsh' en README.md..."
sed -i '' '/near-verify\.zsh/d' README.md 2>/dev/null || true

# 5) Actualizar .gitignore
echo "Asegurando que .gitignore ignore los backups..."
touch .gitignore
grep -qF '**/.backup/' .gitignore || printf '\n**/.backup/\n' >> .gitignore
grep -qF '*.bak' .gitignore || printf '*.bak\n' >> .gitignore

# 6) Reconstruir y probar el proyecto Swift
echo "--- Reconstruyendo y probando el proyecto Swift ---"
swift package reset >/dev/null 2>&1 || true
rm -rf .build
if swift build; then
    echo "Build exitoso. Ejecutando tests..."
    swift test --enable-code-coverage
else
    echo "ERROR: La compilación (swift build) falló. No se ejecutarán los tests."
    exit 1
fi

# 7) Realizar commit de los cambios
echo "--- Preparando commit de la limpieza ---"
git add -A
git commit -m "chore: cleanup project helpers, backups, and artifacts" || echo "INFO: No hay cambios para registrar en el commit."

# 8) Mostrar estado final
echo "--- Estado final del repositorio ---"
git status -sb
echo "--- Limpieza completada ---"

