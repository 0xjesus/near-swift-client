#!/usr/bin/env zsh
set -e
setopt NULL_GLOB

TYPES_DIR="Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes"
BACKUP=".backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP" "$TYPES_DIR"

echo "== 0) Limpiar definiciones duplicadas =="
# 0.1: Quitar nuestro RPCResults.swift que re-declaraba tipos
if [[ -f "$TYPES_DIR/RPCResults.swift" ]]; then
  echo "   -> backup & rm: RPCResults.swift"
  mv "$TYPES_DIR/RPCResults.swift" "$BACKUP/"
fi

# 0.2: Si BasicTypes ya define aliases/U128, quitar nuestros duplicados anteriores
if [[ -f "$TYPES_DIR/BasicTypes.swift" ]]; then
  if grep -q "typealias AccountId" "$TYPES_DIR/BasicTypes.swift" 2>/dev/null; then
    [[ -f "$TYPES_DIR/Aliases.swift" ]] && { echo "   -> rm Aliases.swift (duplicado)"; mv "$TYPES_DIR/Aliases.swift" "$BACKUP/"; }
  fi
  if grep -q "struct U128" "$TYPES_DIR/BasicTypes.swift" 2>/dev/null; then
    [[ -f "$TYPES_DIR/U128.swift" ]] && { echo "   -> rm U128.swift (duplicado)"; mv "$TYPES_DIR/U128.swift" "$BACKUP/"; }
  fi
fi

echo "== 1) Asegurar aliases que SÍ faltan (sin duplicar) =="
ALIA="$TYPES_DIR/AliasesExtra.swift"
> "$ALIA"
ADDED=0
if ! grep -R -q "typealias CryptoHash" "$TYPES_DIR" 2>/dev/null; then
  echo "public typealias CryptoHash = String" >> "$ALIA"; ADDED=1
fi
if ! grep -R -q "typealias Base64String" "$TYPES_DIR" 2>/dev/null; then
  echo "public typealias Base64String = String" >> "$ALIA"; ADDED=1
fi
[[ $ADDED -eq 0 ]] && rm -f "$ALIA"

echo "== 2) Crear tipos puente SOLO si faltan (evitar redeclarations) =="
BRIDGE="$TYPES_DIR/BridgingResults.swift"
echo "import Foundation" > "$BRIDGE"

need() { ! grep -R -q "$1" "$TYPES_DIR" 2>/dev/null; }

# BlockView -> Block (definido en RPCTypes.swift)
if need "struct BlockView" && need "typealias BlockView" && grep -R -q "struct Block: Codable" "$TYPES_DIR" 2>/dev/null; then
  echo "public typealias BlockView = Block" >> "$BRIDGE"
fi

# ChunkView (reutiliza ChunkHeader existente)
if need "struct ChunkView" ; then
  cat >> "$BRIDGE" <<'SWIFT'
public struct ChunkView: Codable, Equatable {
    public let header: ChunkHeader?
    public let transactions: [JSONValue]?
    public let receipts: [JSONValue]?
}
SWIFT
fi

# ValidatorStake (solo si no existe en ValidatorsLightClient.swift u otro)
if need "struct ValidatorStake"; then
  cat >> "$BRIDGE" <<'SWIFT'
public struct ValidatorStake: Codable, Equatable {
    public let accountId: String
    public let publicKey: String
    public let stake: U128
}
SWIFT
fi

# EpochValidatorInfo
if need "struct EpochValidatorInfo"; then
  cat >> "$BRIDGE" <<'SWIFT'
public struct EpochValidatorInfo: Codable, Equatable {
    public let currentValidators: [ValidatorStake]?
    public let nextValidators: [ValidatorStake]?
    public let currentProposals: [JSONValue]?
    public let epochStartHeight: UInt64?
}
SWIFT
fi

# ViewAccountResult
if need "struct ViewAccountResult"; then
  cat >> "$BRIDGE" <<'SWIFT'
public struct ViewAccountResult: Codable, Equatable {
    public let amount: U128?
    public let locked: U128?
    public let storagePaidAt: UInt64?
    public let storageUsage: UInt64?
}
SWIFT
fi

# AccessKeyInfo + ViewAccessKeyResult + ViewAccessKeyListResult (reusar AccessKey de BasicTypes)
if need "struct AccessKeyInfo"; then
  cat >> "$BRIDGE" <<'SWIFT'
public struct AccessKeyInfo: Codable, Equatable {
    public let publicKey: PublicKey
    public let accessKey: AccessKey
}
SWIFT
fi
if need "typealias ViewAccessKeyResult"; then
  echo "public typealias ViewAccessKeyResult = AccessKey" >> "$BRIDGE"
fi
if need "struct ViewAccessKeyListResult"; then
  cat >> "$BRIDGE" <<'SWIFT'
public struct ViewAccessKeyListResult: Codable, Equatable {
    public let keys: [AccessKeyInfo]
}
SWIFT
fi

# ViewCodeResult
if need "struct ViewCodeResult"; then
  cat >> "$BRIDGE" <<'SWIFT'
public struct ViewCodeResult: Codable, Equatable {
    public let codeBase64: Base64String
    public let hash: CryptoHash
}
SWIFT
fi

# StateItem + ViewStateResult
if need "struct StateItem"; then
  cat >> "$BRIDGE" <<'SWIFT'
public struct StateItem: Codable, Equatable {
    public let key: Base64String
    public let value: Base64String
}
SWIFT
fi
if need "struct ViewStateResult"; then
  cat >> "$BRIDGE" <<'SWIFT'
public struct ViewStateResult: Codable, Equatable {
    public let values: [StateItem]
    public let proof: [JSONValue]?
}
SWIFT
fi

# StateChangesResult
if need "struct StateChangesResult"; then
  cat >> "$BRIDGE" <<'SWIFT'
public struct StateChangesResult: Codable, Equatable {
    public let changes: [JSONValue]
    public let blockHash: CryptoHash?
}
SWIFT
fi

# Genesis/Protocol
if need "struct GenesisConfig"; then
  cat >> "$BRIDGE" <<'SWIFT'
public struct GenesisConfig: Codable, Equatable {
    public let chainId: String?
    public let protocolVersion: UInt64?
    public let validators: [ValidatorStake]?
}
SWIFT
fi
if need "struct ProtocolConfig"; then
  cat >> "$BRIDGE" <<'SWIFT'
public struct ProtocolConfig: Codable, Equatable {
    public let protocolVersion: UInt64?
    public let runtimeConfig: JSONValue?
}
SWIFT
fi

# Exec outcomes
if need "struct ExecutionOutcome"; then
  cat >> "$BRIDGE" <<'SWIFT'
public struct ExecutionOutcome: Codable, Equatable {
    public let logs: [String]?
    public let receiptIds: [String]?
    public let gasBurnt: UInt64?
    public let tokensBurnt: U128?
    public let executorId: AccountId?
    public let status: JSONValue?
}
SWIFT
fi
if need "struct FinalExecutionOutcome"; then
  cat >> "$BRIDGE" <<'SWIFT'
public struct FinalExecutionOutcome: Codable, Equatable {
    public let status: JSONValue?
    public let transaction: JSONValue?
    public let transactionOutcome: ExecutionOutcome?
    public let receiptsOutcome: [ExecutionOutcome]?
}
SWIFT
fi

# Light client
if need "struct LightClientExecutionProof"; then
  cat >> "$BRIDGE" <<'SWIFT'
public struct LightClientExecutionProof: Codable, Equatable {
    public let proof: JSONValue?
}
SWIFT
fi
if need "struct LightClientBlockView"; then
  cat >> "$BRIDGE" <<'SWIFT'
public struct LightClientBlockView: Codable, Equatable {
    public let hash: String?
    public let prevHash: String?
}
SWIFT
fi

# Si el archivo quedó vacío (solo import), borrarlo
if [[ $(wc -l < "$BRIDGE") -le 1 ]]; then rm -f "$BRIDGE"; fi

echo "== 3) Build =="
swift build

echo "== 4) Tests (continúa aunque haya fallos) =="
swift test --enable-code-coverage || true

echo "== DONE =="
