import Foundation

public struct BlockHeader: Codable, Equatable {
    public let height: Int?
    public let hash: String?
    public let epochId: String?
    enum CodingKeys: String, CodingKey {
        case height
        case hash
        case epochId = "epoch_id"
    }
}

public struct BlockView: Codable, Equatable {
    public let header: BlockHeader?
    public let author: String?
    public let chunks: [JSONValue]?
}

public struct ChunkView: Codable, Equatable {
    public let chunkHash: String?
    public let shardId: Int?
    public let txRoot: String?
    enum CodingKeys: String, CodingKey {
        case chunkHash = "chunk_hash"
        case shardId = "shard_id"
        case txRoot = "tx_root"
    }
}
