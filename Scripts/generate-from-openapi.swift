#!/usr/bin/env swift
// === near-swift-client: OpenAPI -> Swift codegen  ==========================================
// Generates Swift types (Codable) for OpenAPI schemas and typed RPC wrappers for methods.
// Output:
//   - Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes/Generated/Schemas.generated.swift
//   - Packages/NearJsonRpcClient/Sources/NearJsonRpcClient/Generated/Methods.generated.swift
//
// Usage:
//   swift Scripts/generate-from-openapi.swift
//
// Notes:
// - Focused on OpenAPI v3.0.x commonly used in NEAR JSON-RPC spec.
// - Snake_case keys are mapped to camelCase property names via CodingKeys.
// - Unsupported constructs fall back to `JSONValue` for safe decoding.
// - RPC wrappers ALWAYS call JSON‑RPC via POST "/" (spec paths are ignored).
// - If request/response shapes are ambiguous, wrappers use `JSONValue`.
// - This script is intentionally dependency‑free (Foundation only).
// ============================================================================================

import Foundation

// MARK: - Utilities

extension String {
    func toCamelCase() -> String {
        guard !isEmpty else { return self }
        // Split by non-alphanumeric and underscores
        let parts = self.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        guard !parts.isEmpty else { return self }
        let head = parts[0].lowercased()
        let tail = parts.dropFirst().map { $0.capitalized }
        return ([head] + tail).joined()
    }

    func toTypeName() -> String {
        // Make a nice PascalCase type name
        let parts = self.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        let joined = parts.map { $0.capitalized }.joined()
        // Avoid empty
        return joined.isEmpty ? "Unnamed" : joined
    }

    func safeSwiftIdentifier(isType: Bool = false) -> String {
        let keywords: Set<String> = [
            "class","struct","enum","protocol","extension","func","var","let","import",
            "deinit","init","inout","return","if","else","switch","case","default","break",
            "continue","fallthrough","for","while","repeat","do","try","catch","throw",
            "throws","rethrows","public","internal","private","fileprivate","open",
            "static","subscript","associatedtype","where","as","Any","Type","Self",
            "operator","infix","prefix","postfix","mutating","nonmutating","convenience",
            "required","optional","nil","true","false"
        ]
        let base = self
        if keywords.contains(base) {
            return isType ? "\(base.capitalized)Type" : "`\(base)`"
        }
        return base
    }
}

// Simple stderr print
@inline(__always) func warn(_ s: String) {
    FileHandle.standardError.write((s + "\n").data(using: .utf8)!)
}

// MARK: - OpenAPI Models (subset)

struct OpenAPI: Decodable {
    var info: Info?
    var components: Components?
    var paths: [String: PathItem]?
}

struct Info: Decodable { var title: String?; var version: String? }

struct Components: Decodable {
    var schemas: [String: Schema]?
}

struct PathItem: Decodable {
    var get: Operation?
    var post: Operation?
    var put: Operation?
    var delete: Operation?
    var patch: Operation?
}

struct Operation: Decodable {
    var operationId: String?
    var summary: String?
    var description: String?
    var requestBody: RequestBody?
    var responses: [String: Response]?
    // vendor extensions are allowed but we don't model them strictly
    // We’ll try to infer RPC method name from operationId or path later.
}

struct RequestBody: Decodable {
    var content: [String: MediaType]?
}

struct Response: Decodable {
    var description: String?
    var content: [String: MediaType]?
}

struct MediaType: Decodable {
    var schema: Schema?
}

struct Schema: Decodable {
    var ref: String?                       // $ref
    var type: String?
    var title: String?
    var description: String?
    var properties: [String: Schema]?
    var required: [String]?
    var items: Schema?
    var enumValues: [String]?
    var oneOf: [Schema]?
    var anyOf: [Schema]?
    var allOf: [Schema]?
    var additionalProperties: AdditionalProperties?

    enum CodingKeys: String, CodingKey {
        case ref = "$ref"
        case type, title, description, properties, required, items, oneOf, anyOf, allOf
        case enumValues = "enum"
        case additionalProperties
    }
}

enum AdditionalProperties: Decodable {
    case bool(Bool)
    case schema(Schema)
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let s = try? container.decode(Schema.self) {
            self = .schema(s)
        } else {
            self = .bool(true)
        }
    }
}

// MARK: - Resolver

final class Resolver {
    let components: Components?
    init(_ components: Components?) { self.components = components }

    func resolve(_ s: Schema) -> Schema {
        guard let r = s.ref else { return s }
        // Expecting "#/components/schemas/Name"
        guard r.hasPrefix("#/components/schemas/"),
              let name = r.split(separator: "/").last
        else { return s }
        if let target = components?.schemas?[String(name)] {
            return target
        }
        return s
    }
}

// MARK: - Swift Type Mapping

struct SwiftField {
    let originalName: String
    let swiftName: String
    let typeString: String
    let isOptional: Bool
    let doc: String?
}

enum SwiftDecl {
    case object(name: String, doc: String?, fields: [SwiftField])
    case stringEnum(name: String, doc: String?, cases: [String])
    case alias(name: String, doc: String?, target: String)
}

final class Emitter {
    private let resolver: Resolver
    private var seen: Set<String> = []
    private(set) var decls: [SwiftDecl] = []

    init(resolver: Resolver) { self.resolver = resolver }

    func emitSchemas(_ schemas: [String: Schema]) {
        for (rawName, schema) in schemas {
            _ = swiftType(for: schema, suggestedName: rawName)
        }
    }

    // Returns swift type string; may schedule declarations for generation
    func swiftType(for schema: Schema, suggestedName: String) -> String {
        let s = resolver.resolve(schema)

        // $ref handled in resolve(), but handle nested refs
        if let ref = s.ref, ref.hasPrefix("#/components/schemas/") {
            let name = String(ref.split(separator: "/").last ?? Substring("Ref"))
            return name.toTypeName().safeSwiftIdentifier(isType: true)
        }

        // enum string
        if let t = s.type, t == "string", let ev = s.enumValues, !ev.isEmpty {
            let typeName = suggestedName.toTypeName().safeSwiftIdentifier(isType: true)
            scheduleStringEnum(name: typeName, doc: s.description, cases: ev)
            return typeName
        }

        // primitive
        if let t = s.type {
            switch t {
            case "string":
                return "String"
            case "integer":
                // default to Int (OpenAPI may have format: int64 etc)
                return "Int"
            case "number":
                return "Double"
            case "boolean":
                return "Bool"
            case "array":
                let item = s.items ?? Schema(type: "object", properties: [:])
                let el = swiftType(for: item, suggestedName: suggestedName + "Item")
                return "[\(el)]"
            case "object":
                // object w/ properties => struct
                if let props = s.properties {
                    let typeName = suggestedName.toTypeName().safeSwiftIdentifier(isType: true)
                    scheduleObject(name: typeName, doc: s.description, props: props, required: s.required ?? [])
                    return typeName
                }
                // dictionary-like
                switch s.additionalProperties {
                case .some(.schema(let inner)):
                    let v = swiftType(for: inner, suggestedName: suggestedName + "Value")
                    return "[String: \(v)]"
                case .some(.bool(true)), .none:
                    return "[String: JSONValue]"
                case .some(.bool(false)):
                    return "JSONValue"
                }
            default:
                break
            }
        }

        // oneOf/anyOf/allOf -> fallback to JSONValue (robust default)
        if s.oneOf != nil || s.anyOf != nil || s.allOf != nil {
            return "JSONValue"
        }

        // default fallback
        return "JSONValue"
    }

    private func scheduleStringEnum(name: String, doc: String?, cases: [String]) {
        guard !seen.contains(name) else { return }
        seen.insert(name)
        decls.append(.stringEnum(name: name, doc: doc, cases: cases))
    }

    private func scheduleObject(name: String, doc: String?, props: [String: Schema], required: [String]) {
        guard !seen.contains(name) else { return }
        seen.insert(name)

        var fields: [SwiftField] = []
        for (k, v) in props {
            let swName = k.toCamelCase().safeSwiftIdentifier()
            let typeStr = swiftType(for: v, suggestedName: name + k.toTypeName())
            let isReq = required.contains(k)
            fields.append(SwiftField(
                originalName: k,
                swiftName: swName,
                typeString: isReq ? typeStr : "\(typeStr)?",
                isOptional: !isReq,
                doc: v.description
            ))
        }
        decls.append(.object(name: name, doc: doc, fields: fields.sorted { $0.swiftName < $1.swiftName }))
    }
}

// MARK: - Method wrapper generation (client)

struct MethodSpec {
    let methodName: String          // JSON-RPC method string
    let funcName: String            // Swift func name
    let summary: String?
    let description: String?
    let paramsType: String          // generated or fallback
    let resultType: String          // generated or fallback
}

final class MethodEmitter {
    private let resolver: Resolver

    init(resolver: Resolver) { self.resolver = resolver }

    func collectMethods(api: OpenAPI) -> [MethodSpec] {
        var out: [MethodSpec] = []

        guard let paths = api.paths else { return out }

        for (path, item) in paths {
            // prefer POST, but accept GET for completeness
            let ops: [(String, Operation?)] = [("post", item.post), ("get", item.get)]
            for (verb, opOpt) in ops {
                guard let op = opOpt else { continue }

                // Heuristic for JSON‑RPC method name:
                // 1) operationId if present
                // 2) last path component
                // 3) verb + path hash
                let rpc = (op.operationId ?? path.split(separator: "/").last.map(String.init) ?? "\(verb)\(path)")
                let rpcMethod = rpc.trimmingCharacters(in: .whitespacesAndNewlines)
                let funcName = rpcMethod.toCamelCase().safeSwiftIdentifier()

                // Params type guessing from requestBody app/json schema
                var paramsType = "JSONValue"
                if let s = op.requestBody?.content?["application/json"]?.schema {
                    paramsType = typeNameForRequestSchema(s, suggested: rpcMethod.toTypeName() + "Params")
                }

                // Result type guessing from 200/app-json schema
                var resultType = "JSONValue"
                if let resp = op.responses?["200"] ?? op.responses?["201"] ?? op.responses?["default"],
                   let s = resp.content?["application/json"]?.schema {
                    resultType = typeNameForResponseSchema(s, suggested: rpcMethod.toTypeName() + "Result")
                }

                out.append(MethodSpec(
                    methodName: rpcMethod,
                    funcName: funcName,
                    summary: op.summary,
                    description: op.description,
                    paramsType: paramsType,
                    resultType: resultType
                ))
            }
        }

        // De-duplicate by methodName keeping first occurrence
        var seen = Set<String>()
        let dedup = out.filter { spec in
            if seen.contains(spec.methodName) { return false }
            seen.insert(spec.methodName); return true
        }
        return dedup.sorted { $0.funcName < $1.funcName }
    }

    private func typeNameForRequestSchema(_ s: Schema, suggested: String) -> String {
        // For JSON-RPC, params is often an object/array; generate a nice struct/alias if possible.
        // Reuse logic: if it’s an object with properties -> struct name.
        let rs = resolver.resolve(s)
        if let t = rs.type {
            if t == "object", let props = rs.properties, !props.isEmpty {
                return suggested.toTypeName().safeSwiftIdentifier(isType: true)
            }
            if t == "array" {
                // represent as array of inferred element type
                return "[JSONValue]" // safe fallback
            }
        }
        // Fallback
        return "JSONValue"
    }

    private func typeNameForResponseSchema(_ s: Schema, suggested: String) -> String {
        let rs = resolver.resolve(s)
        // NEAR usually wraps JSON-RPC envelopes; we expect "result" inside transport layer.
        // When spec gives concrete result shape, take it; otherwise fallback.
        if let t = rs.type, t == "object", let props = rs.properties, !props.isEmpty {
            return suggested.toTypeName().safeSwiftIdentifier(isType: true)
        }
        return "JSONValue"
    }
}

// MARK: - File Writers

struct Writers {
    static func writeSchemasFile(at url: URL, api: OpenAPI, decls: [SwiftDecl], generatedAt: String) throws {
        var src = ""
        src += header(banner: "Schemas.generated.swift", info: api.info, generatedAt: generatedAt)
        src += """
        import Foundation

        // NOTE:
        //  - This file is AUTO-GENERATED from OpenAPI. Do not edit by hand.
        //  - Unknown/complex constructs fall back to JSONValue for robust decoding.

        """

        for d in decls {
            switch d {
            case .stringEnum(let name, let doc, let cases):
                if let doc = doc { src += docblock(doc) }
                src += "public enum \(name): String, Codable, Equatable {\n"
                for c in cases {
                    let caseName = c.toCamelCase().safeSwiftIdentifier()
                    src += "    case \(caseName) = \"\(c)\"\n"
                }
                src += "}\n\n"
            case .object(let name, let doc, let fields):
                if let doc = doc { src += docblock(doc) }
                src += "public struct \(name): Codable, Equatable {\n"
                for f in fields {
                    if let doc = f.doc { src += "    /// \(sanitizeDoc(doc))\n" }
                    src += "    public let \(f.swiftName): \(f.typeString)\n"
                }
                // CodingKeys (only if mapping differs)
                let needsCodingKeys = fields.contains { $0.swiftName != $0.originalName }
                if needsCodingKeys {
                    src += "\n    enum CodingKeys: String, CodingKey {\n"
                    for f in fields {
                        if f.swiftName == f.originalName {
                            src += "        case \(f.swiftName)\n"
                        } else {
                            src += "        case \(f.swiftName) = \"\(f.originalName)\"\n"
                        }
                    }
                    src += "    }\n"
                }
                // Memberwise init
                src += "\n    public init(\n"
                for (i,f) in fields.enumerated() {
                    let comma = i == fields.count - 1 ? "" : ","
                    src += "        \(f.swiftName): \(f.typeString)\(comma)\n"
                }
                src += "    ) {\n"
                for f in fields {
                    src += "        self.\(f.swiftName) = \(f.swiftName)\n"
                }
                src += "    }\n"
                src += "}\n\n"
            case .alias(let name, let doc, let target):
                if let doc = doc { src += docblock(doc) }
                src += "public typealias \(name) = \(target)\n\n"
            }
        }

        try ensureDir(url.deletingLastPathComponent())
        try src.write(to: url, atomically: true, encoding: .utf8)
    }

    static func writeMethodsFile(at url: URL, api: OpenAPI, methods: [MethodSpec], generatedAt: String) throws {
        var src = ""
        src += header(banner: "Methods.generated.swift", info: api.info, generatedAt: generatedAt)
        src += """
        import Foundation
        import NearJsonRpcTypes

        // NOTE:
        //  - This file is AUTO-GENERATED from OpenAPI. Do not edit by hand.
        //  - All calls are forced to JSON-RPC POST "/" as per NEAR’s implementation.

        extension NearJsonRpcClient {

        """

        for m in methods {
            let doc = m.summary ?? m.description
            if let doc = doc { src += docblock(doc) }

            src += "    @discardableResult\n"
            src += "    public func \(m.funcName)(_ params: \(m.paramsType)) async throws -> \(m.resultType) {\n"
            src += "        // JSON-RPC over POST \"/\" forced by client transport.\n"
            src += "        return try await self.send(method: \"\(m.methodName)\", params: params)\n"
            src += "    }\n\n"
        }

        src += "}\n"

        try ensureDir(url.deletingLastPathComponent())
        try src.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func header(banner: String, info: Info?, generatedAt: String) -> String {
        let title = info?.title ?? "NEAR JSON‑RPC"
        let version = info?.version ?? "unknown"
        return """
        // === \(banner) (auto-generated) ======================================================
        // Source: \(title) (v\(version))
        // Generated at: \(generatedAt)
        // =====================================================================================

        """
    }

    private static func docblock(_ s: String) -> String {
        "/// " + sanitizeDoc(s).replacingOccurrences(of: "\n", with: "\n/// ") + "\n"
    }

    private static func sanitizeDoc(_ s: String) -> String {
        s.replacingOccurrences(of: "*/", with: "") // keep it simple
    }

    private static func ensureDir(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
}

// MARK: - Main

// 1) Locate OpenAPI spec
let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let candidates = [
    cwd.appendingPathComponent("Scripts/schemas/near-openapi.json"),
    cwd.appendingPathComponent("Scripts/openapi.json"),
    cwd.appendingPathComponent("openapi.json")
]
let specURL = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) })

guard let openapiURL = specURL else {
    warn("ERROR: Could not find OpenAPI JSON. Expected at Scripts/schemas/near-openapi.json (or Scripts/openapi.json).")
    exit(1)
}

let data = try Data(contentsOf: openapiURL)
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .useDefaultKeys
let api = try decoder.decode(OpenAPI.self, from: data)

// 2) Prepare resolvers & emitters
let resolver = Resolver(api.components)
let emitter = Emitter(resolver: resolver)
if let schemas = api.components?.schemas {
    emitter.emitSchemas(schemas)
} else {
    warn("WARN: components.schemas is empty - no types to generate.")
}

let methodEmitter = MethodEmitter(resolver: resolver)
let methods = methodEmitter.collectMethods(api: api)

// 3) Write files
let generatedAt = ISO8601DateFormatter().string(from: Date())

// Types target
let typesOut = cwd
    .appendingPathComponent("Packages")
    .appendingPathComponent("NearJsonRpcTypes")
    .appendingPathComponent("Sources")
    .appendingPathComponent("NearJsonRpcTypes")
    .appendingPathComponent("Generated")
    .appendingPathComponent("Schemas.generated.swift")

try Writers.writeSchemasFile(at: typesOut, api: api, decls: emitter.decls, generatedAt: generatedAt)

// Client target
let clientOut = cwd
    .appendingPathComponent("Packages")
    .appendingPathComponent("NearJsonRpcClient")
    .appendingPathComponent("Sources")
    .appendingPathComponent("NearJsonRpcClient")
    .appendingPathComponent("Generated")
    .appendingPathComponent("Methods.generated.swift")

try Writers.writeMethodsFile(at: clientOut, api: api, methods: methods, generatedAt: generatedAt)

// 4) Post‑generation hints
print("✓ Generated types → \(typesOut.path)")
print("✓ Generated methods → \(clientOut.path)")
print("Done.")
