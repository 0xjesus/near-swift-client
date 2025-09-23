import Foundation

public enum ExecutionStatus: Codable, Equatable {
    case successValue(String)
    case successReceiptId(String)
    case failure(JSONValue)
    case unknown(JSONValue)

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let o = try? c.decode([String:JSONValue].self) {
            if let v = o["SuccessValue"], case let .string(s) = v {
                self = .successValue(s); return
            }
            if let v = o["SuccessReceiptId"], case let .string(s) = v {
                self = .successReceiptId(s); return
            }
            if let f = o["Failure"] {
                self = .failure(f); return
            }
            self = .unknown(.object(o)); return
        }
        self = .unknown(.null)
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .successValue(let s): try c.encode(["SuccessValue": JSONValue.string(s)])
        case .successReceiptId(let s): try c.encode(["SuccessReceiptId": JSONValue.string(s)])
        case .failure(let f): try c.encode(["Failure": f])
        case .unknown(let x): try c.encode(x)
        }
    }
}

public struct ExecutionOutcome: Codable, Equatable {
    public let logs: [String]
    public let receiptIds: [String]
    public let gasBurnt: UInt64?
    public let tokensBurnt: String?
    public let executorId: String
    public let status: ExecutionStatus
    enum CodingKeys: String, CodingKey {
        case logs
        case receiptIds = "receipt_ids"
        case gasBurnt = "gas_burnt"
        case tokensBurnt = "tokens_burnt"
        case executorId = "executor_id"
        case status
    }
}

public struct TransactionView: Codable, Equatable {
    public let signerId: String
    public let publicKey: String
    public let nonce: UInt64
    public let receiverId: String
    public let actions: [JSONValue] // Representación genérica
    public let signature: String?
    public let hash: String?
    enum CodingKeys: String, CodingKey {
        case signerId = "signer_id"
        case publicKey = "public_key"
        case nonce
        case receiverId = "receiver_id"
        case actions
        case signature
        case hash
    }
}

public struct ExecutionOutcomeWithId: Codable, Equatable {
    public let id: String
    public let blockHash: String
    public let outcome: ExecutionOutcome
    enum CodingKeys: String, CodingKey {
        case id
        case blockHash = "block_hash"
        case outcome
    }
}

public struct FinalExecutionOutcome: Codable, Equatable {
    public let finalExecutionStatus: String?
    public let status: ExecutionStatus
    public let transaction: TransactionView
    public let transactionOutcome: ExecutionOutcomeWithId
    public let receiptsOutcome: [ExecutionOutcomeWithId]
    enum CodingKeys: String, CodingKey {
        case finalExecutionStatus = "final_execution_status"
        case status
        case transaction
        case transactionOutcome = "transaction_outcome"
        case receiptsOutcome = "receipts_outcome"
    }
}
