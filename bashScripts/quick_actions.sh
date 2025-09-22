#!/bin/bash

echo "🚀 NEAR Swift Client - Quick Actions"
echo ""
echo "1) Download OpenAPI spec"
echo "2) Run generator"
echo "3) Build project"
echo "4) Run tests"
echo "5) Check coverage"
echo "6) Export context"
echo ""
read -p "Select action (1-6): " choice

case $choice in
    1)
        echo "Downloading NEAR OpenAPI spec..."
        curl -o openapi.json https://raw.githubusercontent.com/near/nearcore/master/chain/jsonrpc/res/rpc_errors_schema.json
        echo "✅ Downloaded to openapi.json"
        ;;
    2)
        echo "Running OpenAPI generator..."
        swift Scripts/generate-from-openapi.swift
        ;;
    3)
        echo "Building project..."
        swift build
        ;;
    4)
        echo "Running tests..."
        swift test
        ;;
    5)
        echo "Checking coverage..."
        swift test --enable-code-coverage
        xcrun llvm-cov report .build/debug/*.xctest -instr-profile=.build/debug/codecov/default.profdata
        ;;
    6)
        echo "Exporting context..."
        ./$(basename $0)
        ;;
    *)
        echo "Invalid option"
        ;;
esac
