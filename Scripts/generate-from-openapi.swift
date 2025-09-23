#!/usr/bin/env swift
import Foundation
func loadOpenAPI() -> [String:Any] {
    let path = "Packages/NearJsonRpcTypes/Schemas/openapi.json"
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String:Any] else {
        fputs("No se pudo leer \(path)\n", stderr); exit(1)
    }
    return obj
}
func camel(_ s: String) -> String {
    let parts = s.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
    guard let first = parts.first?.lowercased() else { return s }
    return ([first] + parts.dropFirst().map { String($0).capitalized }).joined()
}
let spec = loadOpenAPI()
guard let paths = spec["paths"] as? [String:Any] else { fputs("Spec sin 'paths'\n", stderr); exit(2) }
let methods = paths.keys
    .map { $0.trimmingCharacters(in: CharacterSet(charactersIn:"/")) }
    .filter { !$0.isEmpty }
    .sorted()
let outDir = "Packages/NearJsonRpcClient/Sources/NearJsonRpcClient/Generated"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
let content = """
// AUTO-GENERATED. DO NOT EDIT.
// El cliente enviará todas las llamadas por POST "/" (JSON-RPC).
import Foundation
public enum NearRpcMethod: String, CaseIterable {
\(methods.map { "    case \($0.replacingOccurrences(of: ".", with: "_")) = \"\($0)\"" }.joined(separator:"\n"))
}
"""
try content.write(toFile: "\(outDir)/Methods.generated.swift", atomically: true, encoding: .utf8)
print("OK: Generados \\(methods.count) métodos.")
