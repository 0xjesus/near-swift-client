#!/usr/bin/env zsh
set -e
setopt NULL_GLOB

TYPES_DIR="Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes"
CLIENT_GEN_DIR="Packages/NearJsonRpcClient/Sources/NearJsonRpcClient/Generated"
mkdir -p "$TYPES_DIR" "$CLIENT_GEN_DIR"

echo "== 0) Asegurar JSONValue y aliases/U128 si faltan =="

# JSONValue (solo si no existe)
if ! grep -R -q "enum JSONValue" "$TYPES_DIR" 2>/dev/null; then
  cat > "$TYPES_DIR/JSONValue.swift" <<'SWIFT'
import Foundation

public enum JSONValue: Codable, Equatable, Hashable {
    case string(String), number(Double), object([String: JSONValue]), array([JSONValue]), bool(Bool), null
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let b = try? c.decode(Bool.self) { self = .bool(b); return }
        if let n = try? c.decode(Double.self) { self = .number(n); return }
        if let s = try? c.decode(String.self) { self = .string(s); return }
        if let a = try? c.decode([JSONValue].self) { self = .array(a); return }
        if let o = try? c.decode([String: JSONValue].self) { self = .object(o); return }
        throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported JSON value")
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let s): try c.encode(s)
        case .number(let n): try c.encode(n)
        case .object(let o): try c.encode(o)
        case .array(let a): try c.encode(a)
        case .bool(let b): try c.encode(b)
        case .null: try c.encodeNil()
        }
    }
}
SWIFT
fi

# Aliases básicos (solo si NO existen)
if ! grep -R -q "typealias AccountId" "$TYPES_DIR" 2>/dev/null; then
  cat > "$TYPES_DIR/Aliases.swift" <<'SWIFT'
import Foundation
public typealias AccountId = String
public typealias PublicKey = String
public typealias Hash = String
public typealias CryptoHash = String
public typealias BlockHeight = UInt64
public typealias Nonce = UInt64
public typealias Base64String = String
public typealias Balance = String
SWIFT
fi

# U128 (solo si NO existe)
if ! grep -R -q "struct U128" "$TYPES_DIR" 2>/dev/null; then
  cat > "$TYPES_DIR/U128.swift" <<'SWIFT'
import Foundation
public struct U128: Codable, Equatable, Hashable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let value: String
    public init(_ v: String) { self.value = v }
    public init(stringLiteral value: String) { self.value = value }
    public var description: String { value }
}
SWIFT
fi

echo "== 1) Escribir params de RPC requeridos por el cliente =="

cat > "$TYPES_DIR/RPCParams.swift" <<'SWIFT'
import Foundation

public struct BlockParams: Encodable {
    public let blockId: JSONValue?
    public let finality: String?
    public init(blockId: JSONValue? = nil, finality: String? = "final") {
        self.blockId = blockId; self.finality = finality
    }
}

public struct ChunkParams: Encodable {
    public let chunkId: String?
    public let blockId: JSONValue?
    public init(chunkId: String? = nil, blockId: JSONValue? = nil) {
        self.chunkId = chunkId; self.blockId = blockId
    }
}

public struct ValidatorsParams: Encodable {
    public let epochId: String?
    public let blockId: JSONValue?
    public init(epochId: String? = nil, blockId: JSONValue? = nil) {
        self.epochId = epochId; self.blockId = blockId
    }
    public static let current = ValidatorsParams()
}

public struct ViewAccountParams: Encodable {
    public let requestType: String = "view_account"
    public let accountId: AccountId
    public let finality: String?
    public let blockId: JSONValue?
    public init(accountId: AccountId, finality: String? = "optimistic", blockId: JSONValue? = nil) {
        self.accountId = accountId; self.finality = finality; self.blockId = blockId
    }
}

public struct ViewAccessKeyParams: Encodable {
    public let requestType: String = "view_access_key"
    public let accountId: AccountId
    public let publicKey: PublicKey
    public init(accountId: AccountId, publicKey: PublicKey) {
        self.accountId = accountId; self.publicKey = publicKey
    }
}

public struct ViewAccessKeyListParams: Encodable {
    public let requestType: String = "view_access_key_list"
    public let accountId: AccountId
    public init(accountId: AccountId) { self.accountId = accountId }
}

public struct ViewCodeParams: Encodable {
    public let requestType: String = "view_code"
    public let accountId: AccountId
    public init(accountId: AccountId) { self.accountId = accountId }
}

public struct ViewStateParams: Encodable {
    public let requestType: String = "view_state"
    public let accountId: AccountId
    public let prefixBase64: Base64String
    public let finality: String?
    public let blockId: JSONValue?
    public init(accountId: AccountId, prefixBase64: Base64String, finality: String? = "optimistic", blockId: JSONValue? = nil) {
        self.accountId = accountId; self.prefixBase64 = prefixBase64; self.finality = finality; self.blockId = blockId
    }
}

public struct ChangesAccountParams: Encodable {
    public let changesType: String = "account_changes"
    public let accountIds: [AccountId]
    public let finality: String?
    public let blockId: JSONValue?
    public init(accountIds: [AccountId], finality: String? = "final", blockId: JSONValue? = nil) {
        self.accountIds = accountIds; self.finality = finality; self.blockId = blockId
    }
}

public struct ProtocolConfigParams: Encodable {
    public let finality: String?
    public let blockId: JSONValue?
    public init(finality: String? = "final", blockId: JSONValue? = nil) {
        self.finality = finality; self.blockId = blockId
    }
}

public struct SendTxParams: Encodable {
    public let signedTxBase64: String
    public init(signedTxBase64: String) { self.signedTxBase64 = signedTxBase64 }
}

public struct TxStatusParams: Encodable {
    public let txHash: String
    public let senderId: AccountId
    public init(txHash: String, senderId: AccountId) { self.txHash = txHash; self.senderId = senderId }
}

public struct LightClientProofParams: Encodable {
    public let outcomeId: String
    public let lightClientHead: String
    public init(outcomeId: String, lightClientHead: String) {
        self.outcomeId = outcomeId; self.lightClientHead = lightClientHead
    }
}
SWIFT

echo "== 2) Escribir resultados/Tipos usados por el cliente =="

cat > "$TYPES_DIR/RPCResults.swift" <<'SWIFT'
import Foundation

public struct BlockHeader: Codable, Equatable {
    public let height: UInt64?
    public let epochId: String?
    public let hash: String?
    public init(height: UInt64? = nil, epochId: String? = nil, hash: String? = nil) {
        self.height = height; self.epochId = epochId; self.hash = hash
    }
}

public struct ChunkHeader: Codable, Equatable {
    public let chunkHash: String?
    public let heightCreated: UInt64?
    public init(chunkHash: String? = nil, heightCreated: UInt64? = nil) {
        self.chunkHash = chunkHash; self.heightCreated = heightCreated
    }
}

public struct BlockView: Codable, Equatable {
    public let author: AccountId?
    public let header: BlockHeader?
    public let chunks: [ChunkHeader]?
}

public struct ChunkView: Codable, Equatable {
    public let header: ChunkHeader?
    public let transactions: [JSONValue]?
    public let receipts: [JSONValue]?
}

public struct ValidatorStake: Codable, Equatable {
    public let accountId: String
    public let publicKey: String
    public let stake: U128
}

public struct EpochValidatorInfo: Codable, Equatable {
    public let currentValidators: [ValidatorStake]?
    public let nextValidators: [ValidatorStake]?
    public let currentProposals: [JSONValue]?
    public let epochStartHeight: UInt64?
}

public struct ViewAccountResult: Codable, Equatable {
    public let amount: U128?
    public let locked: U128?
    public let storagePaidAt: UInt64?
    public let storageUsage: UInt64?
}

public struct AccessKey: Codable, Equatable {
    public let nonce: Nonce
    public let permission: JSONValue
}

public struct AccessKeyInfo: Codable, Equatable {
    public let publicKey: PublicKey
    public let accessKey: AccessKey
}

public typealias ViewAccessKeyResult = AccessKey

public struct ViewAccessKeyListResult: Codable, Equatable {
    public let keys: [AccessKeyInfo]
}

public struct ViewCodeResult: Codable, Equatable {
    public let codeBase64: Base64String
    public let hash: CryptoHash
}

public struct StateItem: Codable, Equatable {
    public let key: Base64String
    public let value: Base64String
}

public struct ViewStateResult: Codable, Equatable {
    public let values: [StateItem]
    public let proof: [JSONValue]?
}

public struct StateChangesResult: Codable, Equatable {
    public let changes: [JSONValue]
    public let blockHash: CryptoHash?
}

public struct GenesisConfig: Codable, Equatable {
    public let chainId: String?
    public let protocolVersion: UInt64?
    public let validators: [ValidatorStake]?
}

public struct ProtocolConfig: Codable, Equatable {
    public let protocolVersion: UInt64?
    public let runtimeConfig: JSONValue?
}

public struct ExecutionOutcome: Codable, Equatable {
    public let logs: [String]?
    public let receiptIds: [String]?
    public let gasBurnt: UInt64?
    public let tokensBurnt: U128?
    public let executorId: AccountId?
    public let status: JSONValue?
}

public struct FinalExecutionOutcome: Codable, Equatable {
    public let status: JSONValue?
    public let transaction: JSONValue?
    public let transactionOutcome: ExecutionOutcome?
    public let receiptsOutcome: [ExecutionOutcome]?
}

public struct LightClientExecutionProof: Codable, Equatable {
    public let proof: JSONValue?
}

public struct LightClientBlockView: Codable, Equatable {
    public let hash: String?
    public let prevHash: String?
}
SWIFT

echo "== 3) Silenciar warnings de @unchecked Sendable en CaseConversion.swift (si existe) =="
CASE="$TYPES_DIR/CaseConversion.swift"
if [[ -f "$CASE" ]]; then
  /usr/bin/perl -0777 -pe 's/public class NearJSONDecoder: JSONDecoder\s*{/public final class NearJSONDecoder: JSONDecoder, @unchecked Sendable {/' -i '' "$CASE" || true
  /usr/bin/perl -0777 -pe 's/public class NearJSONEncoder: JSONEncoder\s*{/public final class NearJSONEncoder: JSONEncoder, @unchecked Sendable {/' -i '' "$CASE" || true
fi

echo "== 4) Build =="
swift build

echo "== 5) Tests =="
swift test --enable-code-coverage

echo "== OK =="
