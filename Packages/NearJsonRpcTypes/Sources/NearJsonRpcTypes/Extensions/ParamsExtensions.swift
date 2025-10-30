import Foundation

public struct BlockParams: Encodable {
    public let blockId: JSONValue?
    public let finality: Finality?

    public init(blockId: JSONValue? = nil, finality: Finality? = .final) {
        self.blockId = blockId
        self.finality = finality
    }
}

public struct ChunkParams: Encodable {
    public let chunkId: JSONValue?
    public let blockId: JSONValue?

    public init(chunkId: JSONValue? = nil, blockId: JSONValue? = nil) {
        self.chunkId = chunkId
        self.blockId = blockId
    }
}

public struct ViewAccountParams: Encodable {
    public let requestType = "view_account"
    public let accountId: AccountId
    public let finality: Finality?
    public let blockId: JSONValue?

    enum CodingKeys: String, CodingKey {
        case requestType = "request_type"
        case accountId = "account_id"
        case finality
        case blockId = "block_id"
    }

    public init(accountId: AccountId, finality: Finality? = .optimistic, blockId: JSONValue? = nil) {
        self.accountId = accountId
        self.finality = finality
        self.blockId = blockId
    }
}

public struct ViewCodeParams: Encodable {
    public let requestType = "view_code"
    public let accountId: AccountId
    public let finality: Finality?
    public let blockId: JSONValue?

    enum CodingKeys: String, CodingKey {
        case requestType = "request_type"
        case accountId = "account_id"
        case finality
        case blockId = "block_id"
    }

    public init(accountId: AccountId, finality: Finality? = .optimistic, blockId: JSONValue? = nil) {
        self.accountId = accountId
        self.finality = finality
        self.blockId = blockId
    }
}

public struct ViewStateParams: Encodable {
    public let requestType = "view_state"
    public let accountId: AccountId
    public let prefixBase64: Base64String
    public let finality: Finality?
    public let blockId: JSONValue?

    enum CodingKeys: String, CodingKey {
        case requestType = "request_type"
        case accountId = "account_id"
        case prefixBase64 = "prefix_base64"
        case finality
        case blockId = "block_id"
    }

    public init(accountId: AccountId, prefixBase64: Base64String, finality: Finality? = .optimistic, blockId: JSONValue? = nil) {
        self.accountId = accountId
        self.prefixBase64 = prefixBase64
        self.finality = finality
        self.blockId = blockId
    }
}

public struct ViewAccessKeyParams: Encodable {
    public let requestType = "view_access_key"
    public let accountId: AccountId
    public let publicKey: PublicKey
    public let finality: Finality?
    public let blockId: JSONValue?

    enum CodingKeys: String, CodingKey {
        case requestType = "request_type"
        case accountId = "account_id"
        case publicKey = "public_key"
        case finality
        case blockId = "block_id"
    }

    public init(accountId: AccountId, publicKey: PublicKey, finality: Finality? = .optimistic, blockId: JSONValue? = nil) {
        self.accountId = accountId
        self.publicKey = publicKey
        self.finality = finality
        self.blockId = blockId
    }
}

public struct ViewAccessKeyListParams: Encodable {
    public let requestType = "view_access_key_list"
    public let accountId: AccountId
    public let finality: Finality?
    public let blockId: JSONValue?

    enum CodingKeys: String, CodingKey {
        case requestType = "request_type"
        case accountId = "account_id"
        case finality
        case blockId = "block_id"
    }

    public init(accountId: AccountId, finality: Finality? = .optimistic, blockId: JSONValue? = nil) {
        self.accountId = accountId
        self.finality = finality
        self.blockId = blockId
    }
}

public struct CallFunctionParams: Encodable {
    public let requestType = "call_function"
    public let accountId: AccountId
    public let methodName: String
    public let argsBase64: Base64String
    public let finality: Finality?
    public let blockId: JSONValue?

    enum CodingKeys: String, CodingKey {
        case requestType = "request_type"
        case accountId = "account_id"
        case methodName = "method_name"
        case argsBase64 = "args_base64"
        case finality
        case blockId = "block_id"
    }

    public init(accountId: AccountId, methodName: String, argsBase64: Base64String, finality: Finality? = .optimistic, blockId: JSONValue? = nil) {
        self.accountId = accountId
        self.methodName = methodName
        self.argsBase64 = argsBase64
        self.finality = finality
        self.blockId = blockId
    }
}

public struct ChangesAccountParams: Encodable {
    public let changesType = "account_changes"
    public let accountIds: [AccountId]
    public let finality: Finality?
    public let blockId: JSONValue?

    enum CodingKeys: String, CodingKey {
        case changesType = "changes_type"
        case accountIds = "account_ids"
        case finality
        case blockId = "block_id"
    }

    public init(accountIds: [AccountId], finality: Finality? = .optimistic, blockId: JSONValue? = nil) {
        self.accountIds = accountIds
        self.finality = finality
        self.blockId = blockId
    }
}

public struct SendTxParams: Encodable {
    public enum WaitUntil: String, Encodable {
        case broadcast, included
        case executedOptimistic = "executed_optimistic"
        case executed, final
    }

    public let signedTxBase64: String
    public let waitUntil: WaitUntil?

    enum CodingKeys: String, CodingKey {
        case signedTxBase64 = "signed_tx_base64"
        case waitUntil = "wait_until"
    }

    public init(signedTxBase64: String, waitUntil: WaitUntil? = nil) {
        self.signedTxBase64 = signedTxBase64
        self.waitUntil = waitUntil
    }
}

public struct ValidatorsParams: Encodable {
    public let epochId: String?
    public let blockId: JSONValue?

    public static let current = ValidatorsParams(epochId: nil, blockId: nil)

    enum CodingKeys: String, CodingKey {
        case epochId = "epoch_id"
        case blockId = "block_id"
    }

    public init(epochId: String? = nil, blockId: JSONValue? = nil) {
        self.epochId = epochId
        self.blockId = blockId
    }
}

public struct ProtocolConfigParams: Encodable {
    public let finality: Finality?
    public let blockId: JSONValue?

    enum CodingKeys: String, CodingKey {
        case finality
        case blockId = "block_id"
    }

    public init(finality: Finality? = .final, blockId: JSONValue? = nil) {
        self.finality = finality
        self.blockId = blockId
    }
}

public struct TxStatusParams: Encodable {
    public let txHash: String
    public let senderId: String

    enum CodingKeys: String, CodingKey {
        case txHash = "tx_hash"
        case senderId = "sender_id"
    }

    public init(txHash: String, senderId: String) {
        self.txHash = txHash
        self.senderId = senderId
    }
}

public struct LightClientProofParams: Encodable {
    public let outcomeId: String
    public let lightClientHead: String

    enum CodingKeys: String, CodingKey {
        case outcomeId = "outcome_id"
        case lightClientHead = "light_client_head"
    }

    public init(outcomeId: String, lightClientHead: String) {
        self.outcomeId = outcomeId
        self.lightClientHead = lightClientHead
    }
}
