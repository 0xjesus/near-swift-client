import Foundation

// MARK: - Dynamic JSON primitives used by tests

/// Primitive used inside RPCParams (object/array). Matches test expectations:
/// supports .int, .string, .bool, .double, .array, .object, .null
public enum RPCLiteral: Codable, Equatable {
    case int(Int)
    case string(String)
    case bool(Bool)
    case double(Double)
    case array([RPCLiteral])
    case object([String: RPCLiteral])
    case null

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let v = try? c.decode(Int.self) { self = .int(v); return }
        if let v = try? c.decode(Bool.self) { self = .bool(v); return }
        if let v = try? c.decode(Double.self) { self = .double(v); return }
        if let v = try? c.decode(String.self) { self = .string(v); return }
        if let v = try? c.decode([RPCLiteral].self) { self = .array(v); return }
        if let v = try? c.decode([String: RPCLiteral].self) { self = .object(v); return }
        throw DecodingError.typeMismatch(
            RPCLiteral.self,
            .init(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON literal")
        )
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case let .int(v): try c.encode(v)
        case let .bool(v): try c.encode(v)
        case let .double(v): try c.encode(v)
        case let .string(v): try c.encode(v)
        case let .array(v): try c.encode(v)
        case let .object(v): try c.encode(v)
        }
    }
}

/// Parameters wrapper the tests expect: encodes directly as an object or array (no wrapper keys).
public enum RPCParams: Codable, Equatable {
    case object([String: RPCLiteral])
    case array([RPCLiteral])

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let obj = try? c.decode([String: RPCLiteral].self) {
            self = .object(obj); return
        }
        if let arr = try? c.decode([RPCLiteral].self) {
            self = .array(arr); return
        }
        throw DecodingError.typeMismatch(
            RPCParams.self,
            .init(codingPath: decoder.codingPath, debugDescription: "Expected object or array for RPCParams")
        )
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case let .object(o): try c.encode(o)
        case let .array(a): try c.encode(a)
        }
    }
}

/// Request ID that can be integer or string, as used by tests.
public enum RPCRequestID: Codable, Equatable {
    case int(Int)
    case string(String)

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let i = try? c.decode(Int.self) { self = .int(i); return }
        if let s = try? c.decode(String.self) { self = .string(s); return }
        throw DecodingError.typeMismatch(
            RPCRequestID.self,
            .init(codingPath: decoder.codingPath, debugDescription: "Expected int or string for RPCRequestID")
        )
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case let .int(i): try c.encode(i)
        case let .string(s): try c.encode(s)
        }
    }
}

// MARK: - Envelopes expected by tests

// Reutilizamos JSONValue del módulo (definido en RPCEnvelope.swift)
public typealias RPCError = JSONRPCError

public struct RPCRequestEnvelope: Codable {
    public let jsonrpc: String
    public let id: RPCRequestID
    public let method: String
    public let params: RPCParams

    public init(jsonrpc: String = "2.0", id: RPCRequestID, method: String, params: RPCParams) {
        self.jsonrpc = jsonrpc
        self.id = id
        self.method = method
        self.params = params
    }
}

public struct RPCResponseEnvelope: Codable {
    public let jsonrpc: String
    public let id: RPCRequestID?
    private let _result: JSONValue?
    private let _error: RPCError?

    public enum Result {
        case success(JSONValue)
        case failure(RPCError)
    }

    /// Tests expect a `result` enum they can switch on.
    public var result: Result {
        if let e = _error { return .failure(e) }
        return .success(_result ?? .null)
    }

    public init(jsonrpc: String = "2.0", id: RPCRequestID?, result: JSONValue?, error: RPCError?) {
        self.jsonrpc = jsonrpc
        self.id = id
        _result = result
        _error = error
    }

    private enum CodingKeys: String, CodingKey {
        case jsonrpc
        case id
        case _result = "result"
        case _error = "error"
    }
}
