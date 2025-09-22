import Foundation

public typealias AccountId = String
public typealias PublicKey = String
public typealias CryptoHash = String

public struct U128: Codable, Hashable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let value: String
    public init(_ v: String) { self.value = v }
    public init(stringLiteral value: String) { self.value = value }
    public var description: String { value }
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) { self.value = s; return }
        if let d = try? c.decode(Double.self) { self.value = String(format: "%.0f", d); return }
        throw DecodingError.typeMismatch(U128.self, .init(codingPath: decoder.codingPath, debugDescription: "expected string/number"))
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer(); try c.encode(value)
    }
}
