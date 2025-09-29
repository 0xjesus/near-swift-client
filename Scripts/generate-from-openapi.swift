#!/usr/bin/env swift
import Foundation

// MARK: - Config
let openAPIPath = "Scripts/openapi/openapi.json"
let typesOutDir = "Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes/Generated"
let clientOutDir = "Packages/NearJsonRpcClient/Sources/NearJsonRpcClient/Generated"

// MARK: - Helpers
func loadOpenAPI() -> [String: Any] {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: openAPIPath)),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
        fputs("❌ No se pudo leer \(openAPIPath)\n", stderr)
        exit(1)
    }
    return obj
}

func camelCase(_ snake: String) -> String {
    let parts = snake.split(separator: "_")
    guard let first = parts.first else { return snake }
    return ([String(first).lowercased()] + parts.dropFirst().map { String($0).capitalized }).joined()
}

func pascalCase(_ snake: String) -> String {
    return snake.split(separator: "_").map { String($0).capitalized }.joined()
}

func swiftType(for schema: [String: Any], inSchemas schemas: [String: Any]) -> String {
    // Handle $ref
    if let ref = schema["$ref"] as? String {
        let name = ref.components(separatedBy: "/").last ?? "Unknown"
        return pascalCase(name)
    }
    
    // Handle type
    let type = schema["type"] as? String ?? "unknown"
    switch type {
    case "string":
        if let format = schema["format"] as? String {
            switch format {
            case "uint64": return "UInt64"
            case "uint32": return "UInt32"
            default: return "String"
            }
        }
        return "String"
    case "integer":
        return "Int"
    case "number":
        return "Double"
    case "boolean":
        return "Bool"
    case "array":
        if let items = schema["items"] as? [String: Any] {
            let itemType = swiftType(for: items, inSchemas: schemas)
            return "[\(itemType)]"
        }
        return "[Any]"
    case "object":
        return "[String: Any]"
    default:
        return "Any"
    }
}

// MARK: - Generate Types
func generateTypes(from spec: [String: Any]) -> String {
    guard let components = spec["components"] as? [String: Any],
          let schemas = components["schemas"] as? [String: Any] else {
        return "// No schemas found\n"
    }
    
    var output = """
    // AUTO-GENERATED from OpenAPI spec. DO NOT EDIT.
    // Generated: \(ISO8601DateFormatter().string(from: Date()))
    
    import Foundation
    
    """
    
    // Generate each schema as a struct
    for (schemaName, schemaObj) in schemas.sorted(by: { $0.key < $1.key }) {
        guard let schema = schemaObj as? [String: Any],
              let properties = schema["properties"] as? [String: Any] else {
            continue
        }
        
        let structName = pascalCase(schemaName)
        let required = schema["required"] as? [String] ?? []
        
        output += "\n// MARK: - \(structName)\n"
        output += "public struct \(structName): Codable, Equatable {\n"
        
        // Generate properties
        for (propName, propSchema) in properties.sorted(by: { $0.key < $1.key }) {
            guard let propObj = propSchema as? [String: Any] else { continue }
            
            let swiftName = camelCase(propName)
            let swiftPropType = swiftType(for: propObj, inSchemas: schemas)
            let isRequired = required.contains(propName)
            let optionalMarker = isRequired ? "" : "?"
            
            if let description = propObj["description"] as? String {
                output += "    /// \(description)\n"
            }
            output += "    public let \(swiftName): \(swiftPropType)\(optionalMarker)\n"
        }
        
        // Generate CodingKeys for snake_case mapping
        output += "\n    enum CodingKeys: String, CodingKey {\n"
        for propName in properties.keys.sorted() {
            let swiftName = camelCase(propName)
            if swiftName != propName {
                output += "        case \(swiftName) = \"\(propName)\"\n"
            } else {
                output += "        case \(swiftName)\n"
            }
        }
        output += "    }\n"
        
        output += "}\n"
    }
    
    return output
}

// MARK: - Generate Params
func generateParams(from spec: [String: Any]) -> String {
    guard let paths = spec["paths"] as? [String: Any] else {
        return "// No paths found\n"
    }
    
    var output = """
    // AUTO-GENERATED from OpenAPI spec. DO NOT EDIT.
    // Generated: \(ISO8601DateFormatter().string(from: Date()))
    
    import Foundation
    
    """
    
    for (path, pathObj) in paths.sorted(by: { $0.key < $1.key }) {
        guard let pathData = pathObj as? [String: Any],
              let post = pathData["post"] as? [String: Any],
              let requestBody = post["requestBody"] as? [String: Any],
              let content = requestBody["content"] as? [String: Any],
              let jsonContent = content["application/json"] as? [String: Any],
              let schema = jsonContent["schema"] as? [String: Any],
              let properties = schema["properties"] as? [String: Any],
              let params = properties["params"] as? [String: Any],
              let paramsProps = params["properties"] as? [String: Any]
        else { continue }
        
        let methodName = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let structName = pascalCase(methodName) + "Params"
        
        output += "\n// MARK: - \(structName)\n"
        output += "public struct \(structName): Encodable {\n"
        
        for (propName, propSchema) in paramsProps.sorted(by: { $0.key < $1.key }) {
            guard let propObj = propSchema as? [String: Any] else { continue }
            let swiftName = camelCase(propName)
            let swiftType = swiftType(for: propObj, inSchemas: [:])
            output += "    public let \(swiftName): \(swiftType)?\n"
        }
        
        // CodingKeys
        output += "\n    enum CodingKeys: String, CodingKey {\n"
        for propName in paramsProps.keys.sorted() {
            let swiftName = camelCase(propName)
            if swiftName != propName {
                output += "        case \(swiftName) = \"\(propName)\"\n"
            } else {
                output += "        case \(swiftName)\n"
            }
        }
        output += "    }\n"
        output += "}\n"
    }
    
    return output
}

// MARK: - Generate Methods Enum
func generateMethods(from spec: [String: Any]) -> String {
    guard let paths = spec["paths"] as? [String: Any] else {
        return "// No paths found\n"
    }
    
    let methods = paths.keys
        .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }
        .filter { !$0.isEmpty }
        .sorted()
    
    return """
    // AUTO-GENERATED from OpenAPI spec. DO NOT EDIT.
    // Generated: \(ISO8601DateFormatter().string(from: Date()))
    
    import Foundation
    
    public enum NearRpcMethod: String, CaseIterable, Codable {
    \(methods.map { "    case \(camelCase($0)) = \"\($0)\"" }.joined(separator: "\n"))
    }
    """
}

// MARK: - Main
print("🔧 Generando tipos desde OpenAPI...")

let spec = loadOpenAPI()

// Create output directories
try? FileManager.default.createDirectory(atPath: typesOutDir, withIntermediateDirectories: true)
try? FileManager.default.createDirectory(atPath: clientOutDir, withIntermediateDirectories: true)

// Generate files
let typesCode = generateTypes(from: spec)
let paramsCode = generateParams(from: spec)
let methodsCode = generateMethods(from: spec)

// Write files
try typesCode.write(toFile: "\(typesOutDir)/Types.generated.swift", atomically: true, encoding: .utf8)
try paramsCode.write(toFile: "\(typesOutDir)/Params.generated.swift", atomically: true, encoding: .utf8)
try methodsCode.write(toFile: "\(clientOutDir)/Methods.generated.swift", atomically: true, encoding: .utf8)

print("✅ Generados:")
print("   - \(typesOutDir)/Types.generated.swift")
print("   - \(typesOutDir)/Params.generated.swift")
print("   - \(clientOutDir)/Methods.generated.swift")