#!/usr/bin/env zsh
set -e
setopt NULL_GLOB

# Debe correrse en la raíz (donde está Package.swift)
[[ -f Package.swift ]] || { echo "ERROR: corre esto en la raíz del repo (Package.swift)"; exit 1; }

DIR="Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes"
BKP=".backup_fix_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BKP" "$DIR"

echo "== 1) Eliminar definiciones duplicadas que chocan =="
# Estos archivos redeclaran BlockHeader/ChunkHeader/AccessKey/U128/etc. y causan 'invalid redeclaration' / 'ambiguous'
for f in RPCResults.swift BlocksChunks.swift AccountsContracts.swift ProtocolGenesis.swift Primitives.swift Transactions.swift StateChanges.swift ; do
  if [[ -f "$DIR/$f" ]]; then
    echo "   -> backup & rm: $f"
    mv "$DIR/$f" "$BKP/"
  fi
done

echo "== 2) Aliases mínimos (solo si faltan) =="
ALIA="$DIR/AliasesExtra.swift"; : > "$ALIA"; ADDED=0
grep -R --include=\*.swift -q "typealias CryptoHash" "$DIR" || { print -r -- "public typealias CryptoHash = String" >> "$ALIA"; ADDED=1; }
grep -R --include=\*.swift -q "typealias Base64String" "$DIR" || { print -r -- "public typealias Base64String = String" >> "$ALIA"; ADDED=1; }
[[ $ADDED -eq 1 ]] || rm -f "$ALIA"

echo "== 3) Tipos puente (solo si faltan) =="
BR="$DIR/NearTypesBridge.swift"
print -r -- "import Foundation" > "$BR"

need() { ! grep -R --include=\*.swift -q "$1" "$DIR" 2>/dev/null; }

# Bloques / Chunks / Validadores
need "struct BlockView" && print -r -- "public typealias BlockView = Block" >> "$BR"

need "struct ChunkView" && cat >> "$BR" <<'SWIFT'
public struct ChunkView: Codable, Equatable {
    public let header: ChunkHeader?
    public let transactions: [JSONValue]?
    public let receipts: [JSONValue]?
}
SWIFT

need "struct ValidatorStake" && cat >> "$BR" <<'SWIFT'
public struct ValidatorStake: Codable, Equatable {
    public let accountId: String
    public let publicKey: String
    public let stake: U128
}
SWIFT

need "struct EpochValidatorInfo" && cat >> "$BR" <<'SWIFT'
public struct EpochValidatorInfo: Codable, Equatable {
    public let currentValidators: [ValidatorStake]?
    public let nextValidators: [ValidatorStake]?
    public let currentProposals: [JSONValue]?
    public let epochStartHeight: UInt64?
}
SWIFT

# Query / Accounts / Contracts
need "struct ViewAccountResult" && cat >> "$BR" <<'SWIFT'
public struct ViewAccountResult: Codable, Equatable {
    public let amount: U128?
    public let locked: U128?
    public let storagePaidAt: UInt64?
    public let storageUsage: UInt64?
}
SWIFT

need "struct AccessKeyInfo" && cat >> "$BR" <<'SWIFT'
public struct AccessKeyInfo: Codable, Equatable {
    public let publicKey: PublicKey
    public let accessKey: AccessKey
}
SWIFT

need "typealias ViewAccessKeyResult" && print -r -- "public typealias ViewAccessKeyResult = AccessKey" >> "$BR"

need "struct ViewAccessKeyListResult" && cat >> "$BR" <<'SWIFT'
public struct ViewAccessKeyListResult: Codable, Equatable {
    public let keys: [AccessKeyInfo]
}
SWIFT

need "struct StateItem" && cat >> "$BR" <<'SWIFT'
public struct StateItem: Codable, Equatable {
    public let key: Base64String
    public let value: Base64String
}
SWIFT

need "struct ViewStateResult" && cat >> "$BR" <<'SWIFT'
public struct ViewStateResult: Codable, Equatable {
    public let values: [StateItem]
    public let proof: [JSONValue]?
}
SWIFT

need "struct ViewCodeResult" && cat >> "$BR" <<'SWIFT'
public struct ViewCodeResult: Codable, Equatable {
    public let codeBase64: Base64String
    public let hash: CryptoHash
}
SWIFT

need "struct StateChangesResult" && cat >> "$BR" <<'SWIFT'
public struct StateChangesResult: Codable, Equatable {
    public let changes: [JSONValue]
    public let blockHash: CryptoHash?
}
SWIFT

# Protocolo / Génesis
need "struct GenesisConfig" && cat >> "$BR" <<'SWIFT'
public struct GenesisConfig: Codable, Equatable {
    public let chainId: String?
    public let protocolVersion: UInt64?
    public let validators: [ValidatorStake]?
}
SWIFT

need "struct ProtocolConfig" && cat >> "$BR" <<'SWIFT'
public struct ProtocolConfig: Codable, Equatable {
    public let protocolVersion: UInt64?
    public let runtimeConfig: JSONValue?
}
SWIFT

# Transacciones / Ejecución
need "struct ExecutionOutcome" && cat >> "$BR" <<'SWIFT'
public struct ExecutionOutcome: Codable, Equatable {
    public let logs: [String]?
    public let receiptIds: [String]?
    public let gasBurnt: UInt64?
    public let tokensBurnt: U128?
    public let executorId: AccountId?
    public let status: JSONValue?
}
SWIFT

need "struct FinalExecutionOutcome" && cat >> "$BR" <<'SWIFT'
public struct FinalExecutionOutcome: Codable, Equatable {
    public let status: JSONValue?
    public let transaction: JSONValue?
    public let transactionOutcome: ExecutionOutcome?
    public let receiptsOutcome: [ExecutionOutcome]?
}
SWIFT

# Light Client
need "struct LightClientExecutionProof" && print -r -- "public struct LightClientExecutionProof: Codable, Equatable { public let proof: JSONValue? }" >> "$BR"
need "struct LightClientBlockView" && print -r -- "public struct LightClientBlockView: Codable, Equatable { public let hash: String?; public let prevHash: String? }" >> "$BR"

# Si quedó vacío (solo el import), bórralo
[[ $(wc -l < "$BR") -le 1 ]] && rm -f "$BR"

echo "== 4) Limpiar caché y compilar =="
swift package reset >/dev/null 2>&1 || true
rm -rf .build

echo "== 5) Build =="
swift build

echo "== 6) Tests (no detiene si fallan) =="
swift test --enable-code-coverage || true

echo "== DONE ✅ =="
