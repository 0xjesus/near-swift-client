#!/bin/bash

# NEAR Swift Client - COMPLETE Project Status Exporter
# Includes bounty description and full project context

set -e

# Configuration
OUTPUT_FILE="project_status_complete.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
MAX_SIZE_KB=800  # Stay under limit for LLMs

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Statistics
FILES_ADDED=0
TOTAL_LINES=0
MISSING_FILES=""
COMPLETED_ITEMS=0
TODO_ITEMS=0

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📄 NEAR Swift Client - Complete Project Status Export${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to add separator
add_separator() {
    echo -e "\n════════════════════════════════════════════════════════════════════════════════\n" >> "$OUTPUT_FILE"
}

# Function to add major section
add_major_section() {
    local title=$1
    add_separator
    echo "### $title ###" >> "$OUTPUT_FILE"
    add_separator
    echo -e "${CYAN}▶ Section: $title${NC}"
}

# Function to add file with metadata
add_file_complete() {
    local filepath=$1
    local description=$2
    
    if [ ! -f "$filepath" ]; then
        echo -e "  ${RED}✗ Missing: $filepath${NC}"
        MISSING_FILES="$MISSING_FILES\n  - $filepath"
        return
    fi
    
    local filename=$(basename "$filepath")
    local lines=$(wc -l < "$filepath" 2>/dev/null || echo "0")
    local size=$(stat -f%z "$filepath" 2>/dev/null || stat -c%s "$filepath" 2>/dev/null || echo "0")
    local size_kb=$((size / 1024))
    
    # Check if we're approaching size limit
    local current_size=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null || echo "0")
    local current_kb=$((current_size / 1024))
    
    if [ $((current_kb + size_kb)) -gt $MAX_SIZE_KB ]; then
        echo -e "  ${YELLOW}⚠ Size limit - skipping $filepath${NC}"
        return
    fi
    
    echo "" >> "$OUTPUT_FILE"
    echo "┌─────────────────────────────────────────────────────────────────────────────" >> "$OUTPUT_FILE"
    echo "│ FILE: $filepath" >> "$OUTPUT_FILE"
    if [ ! -z "$description" ]; then
        echo "│ DESC: $description" >> "$OUTPUT_FILE"
    fi
    echo "│ STATS: ${lines} lines | ${size_kb}KB" >> "$OUTPUT_FILE"
    echo "└─────────────────────────────────────────────────────────────────────────────" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Add syntax highlighting
    case "$filepath" in
        *.swift) echo '```swift' >> "$OUTPUT_FILE" ;;
        *.yml|*.yaml) echo '```yaml' >> "$OUTPUT_FILE" ;;
        *.json) echo '```json' >> "$OUTPUT_FILE" ;;
        *.sh) echo '```bash' >> "$OUTPUT_FILE" ;;
        *.md) echo '```markdown' >> "$OUTPUT_FILE" ;;
        *) echo '```' >> "$OUTPUT_FILE" ;;
    esac
    
    cat "$filepath" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    FILES_ADDED=$((FILES_ADDED + 1))
    TOTAL_LINES=$((TOTAL_LINES + lines))
    
    echo -e "  ${GREEN}✓${NC} Added: $filename (${lines} lines)"
}

# Initialize output file
cat > "$OUTPUT_FILE" << 'HEADER'
================================================================================
       NEAR SWIFT CLIENT - COMPLETE PROJECT STATUS & BOUNTY REQUIREMENTS
================================================================================
Generated for: Winning the $6,000 USDC NEAR Protocol Swift Client Bounty
================================================================================

HEADER

echo "Report Generated: $TIMESTAMP" >> "$OUTPUT_FILE"
echo "Project Location: $(pwd)" >> "$OUTPUT_FILE"

# ============================================
# BOUNTY DESCRIPTION (OFFICIAL)
# ============================================
add_major_section "📋 OFFICIAL BOUNTY REQUIREMENTS"

cat >> "$OUTPUT_FILE" << 'BOUNTY'
📦 Deliverables: Code generation, GitHub automation, Swift packages, documentation, testing

📘 Background
The NEAR Protocol provides an OpenAPI specification for its JSON-RPC interface, but a high-quality, 
type-safe Swift client is still missing which prevents builders from implementing mobile native apps.

We're looking for an experienced Swift developer or small team to automate the generation and packaging 
of a developer-friendly Swift client using the OpenAPI spec from the nearcore repository.

This tool will serve as a public good: it must be fully automated, thoroughly documented, well-tested, 
and published under a permissive license for long-term use and contribution.

This is part of the bigger initiative that started with Rust and TypeScript clients. 
We strongly recommend to take inspiration from those two repositories.

🧩 Scope of Work

1. OpenAPI Parsing & Swift Code Generation
   - Parse the OpenAPI spec provided in the nearcore repo.
   - WARNING: The OpenAPI spec does not exactly match nearcore's JSON-RPC implementation. 
     The spec uses unique paths for each method while the actual JSON-RPC implementation 
     expects that the path is the same - /, so you must patch the generated code to skip using the paths.
   - Generate a fully type-safe Swift client with:
     * Automatic conversion of fields and method names from snake_case (from API) to camelCase 
       (Swift naming convention)
     * Follow best practices of Swift ecosystem to achieve ergonomic APIs

2. Two Swift Packages
   Package A: near-jsonrpc-types (the naming should be adjusted for Swift ecosystem best practices)
   - Contains only types and serialization/deserialization code
   - Lightweight, minimal dependencies

   Package B: near-jsonrpc-client (the naming should be adjusted for Swift ecosystem best practices)
   - Depends on near-jsonrpc-types
   - Includes all RPC method implementations using most popular or standard HTTP client 
     and auto-typed requests/responses

3. GitHub Actions Automation
   Set up CI/CD to:
   - Fetch the latest OpenAPI spec on push or schedule
   - Regenerate code and types
   - Submit a PR to the repo to run CI tests and get humans review
   - Once the PR is merged, release-please automation must pick it up to bump a version 
     and create a new PR with a proposal to make a release (it can be skipped or ignored)

4. Testing Suite
   - Unit tests for type safety and runtime validation
   - Integration tests (mocking or optional real RPC endpoint)
   - 80%+ test coverage for core functionality

5. Documentation
   - README and usage examples for both packages
   - Instructions for contributing and regenerating code
   - Deployment workflow documentation (e.g., how GitHub Actions publishes to Swift packages manager)

✅ Required Deliverables
   ✅ Full codebase in a new public GitHub repository (MIT or Apache-2.0 licensed)
   ✅ Two published Swift packages: near-jsonrpc-types and near-jsonrpc-client
   ✅ GitHub Actions automation for regeneration, testing, and publishing
   ✅ 80%+ test coverage for core functionality
   ✅ Developer-focused documentation for use and contribution

🧪 Tech Stack
   - Swift
   - OpenAPI tooling (e.g., apple/swift-openapi-generator)
   - GitHub Actions for automation

💰 Budget & Timeline
   - Budget: 6,000 USDC
   - This includes all automation, testing, documentation, and Swift package publishing
   - Timeline: Flexible, but preferred delivery within 3-4 weeks
   - Payment: lump sum upon successful delivery
   - Winner selection: The best complete solution submitted by the deadline

Reference Implementations:
   - Rust: https://github.com/near/near-jsonrpc-client-rs
   - TypeScript: https://github.com/near/near-jsonrpc-client-ts

Community:
   - Telegram: @NEAR_Tools_Community_Group, @NEARDev
BOUNTY

# ============================================
# CURRENT PROJECT STATUS VS REQUIREMENTS
# ============================================
add_major_section "📊 PROJECT STATUS VS BOUNTY REQUIREMENTS"

cat >> "$OUTPUT_FILE" << 'STATUS'

## ✅ COMPLETED REQUIREMENTS (What we have)

1. ✅ Two Swift Packages Structure
   - Created: NearJsonRpcTypes (types package)
   - Created: NearJsonRpcClient (client package)
   - Proper dependency structure (client depends on types)

2. ✅ Basic Type Definitions
   - AccountId, PublicKey, Hash, etc.
   - U128/U64 for large numbers
   - BlockReference, Actions
   - JSON-RPC request/response structures

3. ✅ Snake_case to camelCase Conversion
   - NearJSONEncoder with custom key encoding
   - NearJSONDecoder with custom key decoding
   - String extensions for case conversion

4. ✅ GitHub Actions Workflows
   - CI workflow (ci.yml)
   - OpenAPI update workflow (update-openapi.yml)
   - Release Please workflow (release-please.yml)

5. ✅ Basic Client Implementation
   - Async/await support
   - URLSession-based networking
   - Error handling structure
   - Some RPC methods (viewAccount, viewFunction, getBlock, etc.)

6. ✅ Project Structure
   - MIT License
   - Basic README
   - .gitignore configuration
   - Package.swift files

## ⚠️ IN PROGRESS (Partially complete)

1. ⚠️ OpenAPI Code Generation (70% complete)
   - Script exists: Scripts/generate-from-openapi.swift
   - ❌ CRITICAL: Path consolidation not implemented correctly
   - ❌ Not tested with actual NEAR OpenAPI spec
   - ❌ Type generation incomplete

2. ⚠️ Test Coverage (Currently ~40%, need 80%)
   - Basic unit tests exist
   - ❌ No integration tests
   - ❌ No mock server tests
   - ❌ Missing error case tests
   - ❌ No concurrent request tests

3. ⚠️ Documentation (60% complete)
   - Basic README exists
   - ❌ Missing API documentation
   - ❌ Missing contribution guide details
   - ❌ Missing deployment workflow docs
   - ❌ No usage examples for all methods

## ❌ MISSING CRITICAL REQUIREMENTS

1. ❌ OpenAPI Path Fix (BLOCKER!)
   - The generator MUST patch paths from /block, /tx, etc. to single "/"
   - This is CRITICAL for JSON-RPC compatibility

2. ❌ Complete RPC Method Implementation
   Missing methods:
   - sendTransaction
   - broadcastTxAsync
   - broadcastTxCommit
   - getChunk
   - getValidators
   - getGenesisConfig
   - getProtocolConfig
   - lightClientProof
   - getReceipt
   - getAccountChanges
   - getContractCode
   - getContractState
   - viewAccessKey
   - viewAccessKeyList

3. ❌ Missing Type Definitions
   - Transaction & SignedTransaction
   - Receipt & ExecutionOutcome
   - ExecutionStatus
   - FinalExecutionOutcome
   - ValidatorStake
   - EpochValidatorInfo
   - LightClientBlock
   - StateChanges

4. ❌ Package Publishing
   - Not published to Swift Package Index
   - No version tags
   - No release automation tested

5. ❌ Integration Tests
   - No tests against real NEAR testnet
   - No mock server implementation
   - No performance benchmarks

## 📈 COMPLETION METRICS

| Requirement | Status | Completion |
|-------------|--------|------------|
| Two Swift packages | ✅ Created | 100% |
| Snake_case conversion | ✅ Implemented | 100% |
| OpenAPI parsing | ⚠️ Script exists | 40% |
| Path consolidation fix | ❌ Not implemented | 0% |
| All RPC methods | ⚠️ Partial | 35% |
| Type definitions | ⚠️ Partial | 60% |
| GitHub Actions | ✅ Created | 90% |
| Test coverage 80% | ❌ Currently 40% | 50% |
| Documentation | ⚠️ Basic | 60% |
| Package publishing | ❌ Not done | 0% |
| **OVERALL** | **In Progress** | **~55%** |

## 🚨 CRITICAL PATH TO COMPLETION

Priority 1 (MUST DO NOW):
1. Fix OpenAPI generator path consolidation
2. Download and test with real NEAR OpenAPI spec
3. Generate all types from spec

Priority 2 (ESSENTIAL):
4. Implement all missing RPC methods
5. Write comprehensive tests (reach 80% coverage)
6. Test GitHub Actions on real repository

Priority 3 (FINAL):
7. Complete documentation with examples
8. Publish packages
9. Submit to bounty

Estimated Hours to Complete:
- OpenAPI fix & generation: 4-6 hours
- Missing RPC methods: 6-8 hours  
- Tests to 80%: 8-10 hours
- Documentation: 3-4 hours
- Publishing & submission: 2-3 hours
TOTAL: 23-31 hours of focused work
STATUS

# ============================================
# PROJECT STRUCTURE
# ============================================
add_major_section "📁 CURRENT PROJECT STRUCTURE"

echo '```' >> "$OUTPUT_FILE"
tree -L 3 -I '.git|.build|.swiftpm|DerivedData|*.xcodeproj' 2>/dev/null | head -80 >> "$OUTPUT_FILE" || {
    find . -type f \( -name "*.swift" -o -name "*.yml" -o -name "*.json" -o -name "*.md" \) \
        -not -path "./.git/*" -not -path "./.build/*" | \
        sed 's|^\./||' | sort | head -50 >> "$OUTPUT_FILE"
}
echo '```' >> "$OUTPUT_FILE"

# ============================================
# PACKAGE CONFIGURATIONS
# ============================================
add_major_section "📦 PACKAGE CONFIGURATIONS"

add_file_complete "Package.swift" "Main workspace configuration"
add_file_complete "Packages/NearJsonRpcTypes/Package.swift" "Types package (must have ZERO dependencies)"
add_file_complete "Packages/NearJsonRpcClient/Package.swift" "Client package configuration"

# ============================================
# TYPES PACKAGE SOURCE
# ============================================
add_major_section "🔷 NEARJSONRPCTYPES PACKAGE - SOURCE CODE"

for file in Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes/*.swift; do
    [ -f "$file" ] && add_file_complete "$file" "Type definitions"
done

# ============================================
# CLIENT PACKAGE SOURCE
# ============================================
add_major_section "🔶 NEARJSONRPCCLIENT PACKAGE - SOURCE CODE"

for file in Packages/NearJsonRpcClient/Sources/NearJsonRpcClient/*.swift; do
    [ -f "$file" ] && add_file_complete "$file" "Client implementation"
done

# ============================================
# CRITICAL: OPENAPI GENERATOR
# ============================================
add_major_section "⚠️ CRITICAL: OPENAPI GENERATOR SCRIPT"

echo "🚨 THIS SCRIPT MUST FIX THE PATH ISSUE!" >> "$OUTPUT_FILE"
echo "The OpenAPI spec has paths like /block, /tx, but JSON-RPC needs single '/' endpoint" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

add_file_complete "Scripts/generate-from-openapi.swift" "OpenAPI generator - NEEDS PATH FIX"

# ============================================
# TESTS
# ============================================
add_major_section "🧪 TEST SUITES"

echo "Current Coverage: ~40% | Required: 80%+" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

for file in Packages/NearJsonRpcTypes/Tests/NearJsonRpcTypesTests/*.swift; do
    [ -f "$file" ] && add_file_complete "$file" "Types tests"
done

for file in Packages/NearJsonRpcClient/Tests/NearJsonRpcClientTests/*.swift; do
    [ -f "$file" ] && add_file_complete "$file" "Client tests"
done

# ============================================
# GITHUB ACTIONS
# ============================================
add_major_section "🤖 GITHUB ACTIONS WORKFLOWS"

for file in .github/workflows/*.yml .github/workflows/*.yaml; do
    [ -f "$file" ] && add_file_complete "$file" "CI/CD workflow"
done

# ============================================
# DOCUMENTATION
# ============================================
add_major_section "📚 DOCUMENTATION"

add_file_complete "README.md" "Main documentation"
add_file_complete "CONTRIBUTING.md" "Contribution guidelines"
add_file_complete "LICENSE" "License file"

# ============================================
# EXAMPLES
# ============================================
add_major_section "💡 EXAMPLES"

for file in Examples/**/*.swift Examples/*.swift; do
    [ -f "$file" ] && add_file_complete "$file" "Example code"
done

# ============================================
# TASK LIST TO WIN BOUNTY
# ============================================
add_major_section "✅ CHECKLIST TO WIN THE BOUNTY"

cat >> "$OUTPUT_FILE" << 'TASKS'

## 🎯 IMMEDIATE ACTIONS REQUIRED

### 1. FIX THE OPENAPI GENERATOR (CRITICAL!)
```swift
// In Scripts/generate-from-openapi.swift
func patchOpenAPISpec(_ spec: inout [String: Any]) {
    // MUST consolidate all paths to single "/"
    // Current: /block, /tx, /query, etc.
    // Needed: "/" with method in JSON-RPC body
}
```

### 2. DOWNLOAD REAL OPENAPI SPEC
```bash
curl -o openapi.json https://raw.githubusercontent.com/near/nearcore/master/chain/jsonrpc/res/rpc_errors_schema.json
```

### 3. IMPLEMENT MISSING RPC METHODS
Add to NearJsonRpcClient.swift:
- [ ] sendTransaction
- [ ] broadcastTxAsync
- [ ] broadcastTxCommit
- [ ] getValidators
- [ ] getChunk
- [ ] getGenesisConfig
- [ ] getProtocolConfig
- [ ] viewAccessKey
- [ ] viewAccessKeyList
- [ ] getContractCode
- [ ] getContractState

### 4. ADD MISSING TYPES
Add to RPCTypes.swift:
- [ ] Transaction
- [ ] SignedTransaction
- [ ] Receipt
- [ ] ExecutionOutcome
- [ ] FinalExecutionOutcome
- [ ] ValidatorStake
- [ ] EpochValidatorInfo

### 5. INCREASE TEST COVERAGE TO 80%
- [ ] Add unit tests for all methods
- [ ] Add integration tests with mock
- [ ] Add error case tests
- [ ] Add concurrent request tests

### 6. COMPLETE DOCUMENTATION
- [ ] Add usage examples for all methods
- [ ] Document the code generation process
- [ ] Add API reference
- [ ] Create migration guide

### 7. TEST GITHUB ACTIONS
- [ ] Test CI workflow
- [ ] Test OpenAPI update workflow
- [ ] Test release workflow

### 8. PUBLISH PACKAGES
- [ ] Tag version 1.0.0
- [ ] Publish to Swift Package Index
- [ ] Test installation

## 📝 SUBMISSION CHECKLIST

Before submitting for the bounty:
- [ ] All RPC methods implemented
- [ ] 80%+ test coverage verified
- [ ] GitHub Actions all green
- [ ] Documentation complete
- [ ] Packages published
- [ ] Example apps working
- [ ] Tested on iOS/macOS
- [ ] License file (MIT)
- [ ] Clean commit history
- [ ] No compiler warnings

## 🏆 WINNING CRITERIA

To maximize chances of winning:
1. Be FIRST with a complete solution
2. Have the BEST code quality
3. Exceed requirements (90%+ coverage)
4. Provide excellent documentation
5. Active in community chat
6. Responsive to feedback
TASKS

# ============================================
# FINAL STATISTICS
# ============================================
add_major_section "📊 EXPORT STATISTICS"

OUTPUT_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null || echo "0")
OUTPUT_KB=$((OUTPUT_SIZE / 1024))
OUTPUT_LINES=$(wc -l < "$OUTPUT_FILE")
EST_TOKENS=$((OUTPUT_SIZE / 4))

# Count completion
COMPLETED_ITEMS=8   # Based on status above
TODO_ITEMS=7        # Based on missing items

cat >> "$OUTPUT_FILE" << FOOTER

## Summary Statistics
- Files included: $FILES_ADDED
- Total lines of code: $TOTAL_LINES
- Output size: ${OUTPUT_KB}KB
- Estimated tokens: ~$EST_TOKENS / 200,000
- Generated: $TIMESTAMP

## Completion Status
- Completed items: $COMPLETED_ITEMS
- TODO items: $TODO_ITEMS
- Overall completion: ~55%
- Hours to complete: ~25-30

## Quick Test Commands
\`\`\`bash
# Build project
swift build

# Run tests
swift test --enable-code-coverage

# Check coverage
xcrun llvm-cov report .build/debug/*.xctest -instr-profile=.build/debug/codecov/default.profdata

# Generate from OpenAPI
swift Scripts/generate-from-openapi.swift
\`\`\`

## How to Use This Document

1. Send to ChatGPT/Claude with this prompt:
   "Help me complete this NEAR Swift client to win the $6000 bounty. 
   Focus on: 1) Fix OpenAPI path consolidation 2) Add missing RPC methods 3) Reach 80% test coverage.
   The current completion is 55%. Please provide complete implementations."

2. Or for specific fixes:
   "Fix the OpenAPI generator to consolidate all paths to single '/' for JSON-RPC"
   "Add the missing RPC methods with proper types"
   "Write tests to increase coverage from 40% to 80%"

END OF PROJECT STATUS REPORT
FOOTER

# Console output
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ PROJECT STATUS EXPORT COMPLETE!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Status summary
echo -e "${MAGENTA}📊 BOUNTY PROGRESS:${NC}"
echo -e "  ${GREEN}✅ Completed:${NC} 8 requirements"
echo -e "  ${YELLOW}⚠️  In Progress:${NC} 3 requirements"
echo -e "  ${RED}❌ Missing:${NC} 7 requirements"
echo -e "  ${BLUE}📈 Overall:${NC} ~55% complete"
echo ""

echo -e "${BLUE}📋 Export Statistics:${NC}"
echo -e "  📄 Output: ${YELLOW}$OUTPUT_FILE${NC}"
echo -e "  📁 Files: ${YELLOW}$FILES_ADDED${NC} included"
echo -e "  📏 Size: ${YELLOW}${OUTPUT_KB}KB${NC}"
echo -e "  🎯 Tokens: ${YELLOW}~$EST_TOKENS${NC} / 200,000"

if [ $EST_TOKENS -lt 200000 ]; then
    echo -e "  ${GREEN}✓ Within token limits${NC}"
else
    echo -e "  ${RED}⚠ May exceed limits${NC}"
fi

echo ""
echo -e "${CYAN}🚀 Next Steps:${NC}"
echo -e "  1. ${YELLOW}Fix OpenAPI generator${NC} (path consolidation)"
echo -e "  2. ${YELLOW}Add missing RPC methods${NC}"
echo -e "  3. ${YELLOW}Increase test coverage${NC} to 80%"
echo -e "  4. ${YELLOW}Complete documentation${NC}"
echo ""

echo -e "${GREEN}📋 Copy to clipboard:${NC}"
echo -e "  ${BLUE}cat $OUTPUT_FILE | pbcopy${NC}     # macOS"
echo -e "  ${BLUE}cat $OUTPUT_FILE | xclip${NC}      # Linux"
echo ""

echo -e "${MAGENTA}💡 Recommended LLM prompt:${NC}"
echo "\"I need to complete this NEAR Swift client for a \$6000 bounty."
echo "Current status: 55% complete. Critical issues:"
echo "1. Fix OpenAPI path consolidation (paths must be '/' not '/method')"  
echo "2. Add missing RPC methods (see checklist)"
echo "3. Increase test coverage from 40% to 80%"
echo "Please provide complete working implementations.\""
echo ""

# Create quick action script
cat > quick_actions.sh << 'ACTIONS'
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
ACTIONS

chmod +x quick_actions.sh
echo -e "${GREEN}✨ Created quick_actions.sh for common tasks${NC}"
echo ""

if [ ! -z "$MISSING_FILES" ]; then
    echo -e "${RED}⚠️ Missing files detected:${NC}$MISSING_FILES"
fi