import Foundation

public struct StateChangesResult: Codable, Equatable {
    public let blockHash: String
    public let changes: [JSONValue]
    enum CodingKeys: String, CodingKey {
        case blockHash = "block_hash"
        case changes
    }
}
