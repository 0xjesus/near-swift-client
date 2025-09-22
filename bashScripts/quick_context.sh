#!/bin/bash
# Quick context generator for specific tasks

case "$1" in
    fix-openapi)
        echo "Generating context for OpenAPI fixes..."
        grep -A 50 -B 5 "generate-from-openapi" context.txt > openapi_context.txt
        echo "Context saved to openapi_context.txt"
        ;;
    add-tests)
        echo "Generating context for adding tests..."
        grep -A 100 "TEST" context.txt > tests_context.txt
        echo "Context saved to tests_context.txt"
        ;;
    complete-client)
        echo "Generating context for client completion..."
        grep -A 200 "CLIENT PACKAGE" context.txt > client_context.txt
        echo "Context saved to client_context.txt"
        ;;
    *)
        echo "Usage: $0 {fix-openapi|add-tests|complete-client}"
        ;;
esac
