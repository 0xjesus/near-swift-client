#!/bin/bash

echo "🔍 NEAR Swift Client - Quick Status Check"
echo "=========================================="

# Check if packages build
echo -n "Build status: "
if swift build &>/dev/null; then
    echo "✅ Success"
else
    echo "❌ Failed"
fi

# Check test status
echo -n "Tests status: "
if swift test &>/dev/null; then
    echo "✅ Passing"
else
    echo "❌ Failed"
fi

# Count files
echo "File counts:"
echo "  Swift files: $(find . -name "*.swift" -not -path "./.build/*" | wc -l)"
echo "  Test files: $(find . -path "*/Tests/*.swift" | wc -l)"
echo "  Workflows: $(find .github/workflows -name "*.yml" 2>/dev/null | wc -l)"

# Check coverage
if [ -f .build/debug/codecov/default.profdata ]; then
    echo "Test coverage: Available (run 'swift test --enable-code-coverage' to update)"
else
    echo "Test coverage: Not generated yet"
fi

echo ""
echo "Run './$(basename $0)' for detailed context export"
