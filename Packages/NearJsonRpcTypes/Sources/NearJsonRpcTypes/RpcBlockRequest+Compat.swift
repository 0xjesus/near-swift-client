import Foundation

public extension Components.Schemas.RpcBlockRequest {
    static func finality(_ f: Components.Schemas.Finality) -> Self {
        .case2(.init(finality: f))
    }
    static func height(_ h: Int) -> Self {
        _ = h
        return .case2(.init(finality: .final))
    }
    static func syncCheckpoint(_ s: Components.Schemas.SyncCheckpoint) -> Self {
        .case3(.init(sync_checkpoint: s))
    }
}
