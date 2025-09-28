#!/bin/bash

# Script de build, testing y verificación para NEAR Swift Client
# Uso: ./build_and_test.sh

set -e  # Salir si cualquier comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con color
print_step() {
    echo -e "\n${GREEN}==>${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}Advertencia:${NC} $1"
}

# 1) Build + tests
print_step "1) Compilando proyecto y ejecutando tests..."
if swift build && swift test; then
    echo "✅ Build y tests completados exitosamente"
else
    print_error "Falló el build o los tests"
    exit 1
fi

# 2) Coverage gate (should pass >= 80%)
print_step "2) Verificando cobertura de código (>= 80%)..."
COVERAGE_SCRIPT="Scripts/coverage-summary.sh"

if [ -f "$COVERAGE_SCRIPT" ]; then
    chmod +x "$COVERAGE_SCRIPT"
    if ./"$COVERAGE_SCRIPT"; then
        echo "✅ Cobertura verificada"
    else
        print_warning "La verificación de cobertura falló o está por debajo del 80%"
    fi
else
    print_warning "Script de cobertura no encontrado: $COVERAGE_SCRIPT"
fi

# 3) Docs build locally (optional quick check)
print_step "3) Generando documentación localmente (verificación rápida)..."
if swift package --disable-sandbox generate-documentation \
    --target NearJsonRpcClient \
    --target NearJsonRpcTypes \
    --output-path docs \
    --transform-for-static-hosting \
    --hosting-base-path near-swift-client; then
    
    if [ -f "docs/index.html" ]; then
        echo "✅ Documentación generada exitosamente"
        ls -la docs/index.html
    else
        print_warning "Documentación generada pero index.html no encontrado"
    fi
else
    print_warning "Generación de documentación falló (opcional)"
fi

# 4) Example CLI runs (smoke test)
print_step "4) Ejecutando ejemplo CLI (smoke test)..."
EXAMPLE_DIR="Examples/NearQuickStart"

if [ -d "$EXAMPLE_DIR" ]; then
    pushd "$EXAMPLE_DIR" > /dev/null
    export NEAR_RPC_URL="https://rpc.testnet.near.org"
    
    if swift run; then
        echo "✅ Ejemplo CLI ejecutado exitosamente"
    else
        print_warning "Ejemplo CLI falló"
    fi
    
    popd > /dev/null
else
    print_warning "Directorio de ejemplo no encontrado: $EXAMPLE_DIR"
fi

# 5) Verificar workflows de GitHub Actions
print_step "5) Verificando workflows de GitHub Actions..."
if command -v gh &> /dev/null; then
    if gh workflow list 2>/dev/null; then
        echo "✅ Workflows listados exitosamente"
    else
        print_warning "No se pudieron listar workflows (¿estás en un repo de GitHub?)"
    fi
else
    print_warning "GitHub CLI (gh) no está instalado"
    echo "Instala con: brew install gh"
fi

# 6) Verificar releases
print_step "6) Verificando releases (buscando v0.1.1)..."
if command -v gh &> /dev/null; then
    if gh release list 2>/dev/null | head -5; then
        echo "✅ Releases listados exitosamente"
    else
        print_warning "No se pudieron listar releases"
    fi
else
    print_warning "GitHub CLI (gh) no está instalado"
fi

# Resumen final
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✨ Script completado${NC}"
echo -e "${GREEN}========================================${NC}"
