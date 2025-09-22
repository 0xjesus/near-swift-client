#!/usr/bin/env swift
import Foundation

// MARK: - Utilidades JSON
enum J {
    case obj([String:J]), arr([J]), str(String), num(Double), bool(Bool), nul
}
extension J {
    subscript(_ k: String) -> J? { if case let .obj(o)=self { return o[k] } ; return nil }
    var obj: [String:J]? { if case let .obj(o)=self { return o } ; return nil }
    var arr: [J]? { if case let .arr(a)=self { return a } ; return nil }
    var str: String? { if case let .str(s)=self { return s } ; return nil }
}

func parseJSON(_ data: Data) -> J {
    func toJ(_ x: Any) -> J {
        switch x {
        case let d as [String:Any]: return .obj(d.mapValues(toJ))
        case let a as [Any]: return .arr(a.map(toJ))
        case let s as String: return .str(s)
        case let n as NSNumber:
            if CFGetTypeID(n) == CFBooleanGetTypeID() { return .bool(n.boolValue) }
            return .num(n.doubleValue)
        default: return .nul
        }
    }
    let obj = (try? JSONSerialization.jsonObject(with: data)) ?? [:]
    return toJ(obj)
}

func stringify(_ j: J) -> String {
    func any(_ j: J) -> Any {
        switch j {
        case .obj(let o): return o.mapValues(any)
        case .arr(let a): return a.map(any)
        case .str(let s): return s
        case .num(let n): return n
        case .bool(let b): return b
        case .nul: return NSNull()
        }
    }
    let data = try! JSONSerialization.data(withJSONObject: any(j), options: [.sortedKeys,.prettyPrinted])
    return String(data: data, encoding: .utf8)!
}

func camel(_ s: String) -> String {
    let parts = s.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
    guard let first = parts.first?.lowercased() else { return s }
    return [first] + parts.dropFirst().map{ $0.capitalized }.joined()
}

// MARK: - Descarga del OpenAPI
let candidates = [
    // Si el nodo RPC ya expone openapi (issue en nearcore)
    "https://rpc.testnet.near.org/openapi-spec.json",
    "https://rpc.mainnet.near.org/openapi-spec.json",
    // nearcore (ruta evolutiva — fallback)
    "https://raw.githubusercontent.com/near/nearcore/master/chain/jsonrpc/res/openapi.json",
    "https://raw.githubusercontent.com/near/nearcore/master/chain/jsonrpc/res/openrpc.json",
    // (último recurso) copia del repo TS (si existiese pública)
    "https://raw.githubusercontent.com/near/near-jsonrpc-client-ts/main/packages/jsonrpc-types/openapi.json"
]

var specData: Data?
for url in candidates {
    if let u = URL(string: url), let d = try? Data(contentsOf: u), d.count > 0 {
        specData = d; break
    }
}
guard let data = specData else {
    fputs("ERROR: no se pudo descargar el OpenAPI\n", stderr); exit(1)
}
var spec = parseJSON(data)

// MARK: - Patch de paths -> "/"
if let paths = spec["paths"]?.obj {
    var methods: [String:J] = [:]
    for (path, item) in paths {
        let name = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !name.isEmpty else { continue }
        // Anotamos el nombre del método en una vendor extension para el generador
        if var o = item.obj {
            o["x-near-rpc-method"] = .str(name)
            methods[name] = .obj(o)
        }
    }
    // Guardamos los métodos bajo "/":{ "x-near-methods": { ... } } para dejar claro que ignoramos paths REST
    spec = .obj([
        "openapi": spec["openapi"] ?? .str("3.0.0"),
        "info": spec["info"] ?? .obj(["title": .str("NEAR JSON-RPC (patched)"), "version": .str("0")]),
        "paths": .obj([
            "/": .obj([
                "x-near-methods": .obj(methods)
            ])
        ]),
        "components": spec["components"] ?? .obj([:])
    ])
}

// MARK: - Salida: generar Swift
let repoRoot = FileManager.default.currentDirectoryPath
let genTypesDir = "\(repoRoot)/Packages/NearJsonRpcTypes/Sources/Generated"
let genClientDir = "\(repoRoot)/Packages/NearJsonRpcClient/Sources/Generated"
try? FileManager.default.createDirectory(atPath: genTypesDir, withIntermediateDirectories: true)
try? FileManager.default.createDirectory(atPath: genClientDir, withIntermediateDirectories: true)

// 1) Generar lista de métodos
let methods: [String]
if let m = spec["paths"]?["/"]?["x-near-methods"]?.obj {
    methods = m.keys.sorted()
} else {
    methods = []
}
let methodsSwift = """
// AUTO-GENERATED. DO NOT EDIT.
// Generado desde OpenAPI con consolidación de paths -> "/"
import Foundation

public enum NearRpcMethod: String, CaseIterable {
\(methods.map{ "    case \($0.replacingOccurrences(of: ".", with: "_")) = \"\($0)\"" }.joined(separator: "\n"))
}
"""
try methodsSwift.write(toFile: "\(genClientDir)/Methods.generated.swift", atomically: true, encoding: .utf8)

// 2) Generar tipos básicos a partir de components.schemas (best effort)
func swiftType(for schema: J) -> String {
    if let type = schema["type"]?.str {
        switch type {
        case "string": return "String"
        case "integer": return "Int"
        case "number": return "Double"
        case "boolean": return "Bool"
        case "array": return "[\(swiftType(for: schema["items"] ?? .obj([:])))]"
        case "object": return "JSONValue" // lo refinamos al expandir propiedades abajo
        default: return "JSONValue"
        }
    }
    return "JSONValue"
}

var typesOut = """
// AUTO-GENERATED (best effort) desde components.schemas
import Foundation

public enum JSONValue: Codable, Equatable {
    case string(String), number(Double), bool(Bool), object([String:JSONValue]), array([JSONValue]), null
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let b = try? c.decode(Bool.self) { self = .bool(b); return }
        if let n = try? c.decode(Double.self) { self = .number(n); return }
        if let s = try? c.decode(String.self) { self = .string(s); return }
        if let a = try? c.decode([JSONValue].self) { self = .array(a); return }
        if let o = try? c.decode([String:JSONValue].self) { self = .object(o); return }
        throw DecodingError.typeMismatch(JSONValue.self, .init(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON"))
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case .bool(let b): try c.encode(b)
        case .number(let n): try c.encode(n)
        case .string(let s): try c.encode(s)
        case .array(let a): try c.encode(a)
        case .object(let o): try c.encode(o)
        }
    }
}
"""

if let schemas = spec["components"]?["schemas"]?.obj {
    for (name, schema) in schemas.sorted(by: { $0.key < $1.key }) {
        // Sólo generamos structs para object con properties { ... }
        if let props = schema["properties"]?.obj, schema["type"]?.str == "object" {
            let fields = props.map { (k,v) in
                let st = swiftType(for: v)
                return "    public var \(camel(k)): \(st)?"
            }.sorted().joined(separator: "\n")
            let codingKeys = props.keys.sorted().map { "        case \(camel($0)) = \"\($0)\"" }.joined(separator: "\n")
            typesOut += """

public struct \(name): Codable, Equatable {
\(fields.isEmpty ? "    public init() {}" : fields)
    public init(\(props.keys.sorted().map { "\(camel($0)): \(swiftType(for: props[$0]!))?" }.joined(separator: ", "))) {
\(props.keys.sorted().map { "        self.\(camel($0)) = \(camel($0))" }.joined(separator: "\n"))
    }
    enum CodingKeys: String, CodingKey {
\(codingKeys)
    }
}
"""
        }
    }
}
try typesOut.write(toFile: "\(genTypesDir)/Schemas.generated.swift", atomically: true, encoding: .utf8)

print("OK: Generados \(methods.count) métodos y tipos desde OpenAPI.")
