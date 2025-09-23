#!/usr/bin/env zsh
set -euo pipefail

ts=$(date +%Y%m%d_%H%M%S)
mkdir -p ".backup/$ts"

echo "== 1) Mover archivos no-Swift fuera de Sources =="
mkdir -p Scripts/openapi
for f in \
  "Packages/NearJsonRpcTypes/Sources/NearRPCTypes/openapi.json" \
  "Packages/NearJsonRpcTypes/Sources/NearRPCTypes/openapi-generator-config.yaml" \
  "Packages/NearJsonRpcTypes/Sources/openapi.json" \
  "Packages/NearJsonRpcTypes/Sources/openapi-generator-config.yaml" ; do
  if [[ -f "$f" ]]; then
    echo "   moving $f -> Scripts/openapi/"
    mv "$f" "Scripts/openapi/"
  fi
done
rmdir "Packages/NearJsonRpcTypes/Sources/NearRPCTypes" 2>/dev/null || true

echo "== 2) Respaldar y retirar Swift duplicado que choca (U128, BlockHeader, etc.) =="
mkdir -p ".backup/$ts/dups"
types_to_remove=(
  "Packages/NearJsonRpcTypes/Sources/Primitives.swift"
  "Packages/NearJsonRpcTypes/Sources/BlocksChunks.swift"
  "Packages/NearJsonRpcTypes/Sources/AccountsContracts.swift"
  "Packages/NearJsonRpcTypes/Sources/ProtocolGenesis.swift"
  "Packages/NearJsonRpcTypes/Sources/ValidatorsLightClient.swift"
  "Packages/NearJsonRpcTypes/Sources/Transactions.swift"
  "Packages/NearJsonRpcTypes/Sources/StateChanges.swift"
  "Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes/BlocksChunks.swift"
  "Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes/ValidatorsLightClient.swift"
  "Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes/AccountsContracts.swift"
  "Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes/ProtocolGenesis.swift"
  "Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes/Primitives.swift"
  "Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes/Transactions.swift"
  "Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes/StateChanges.swift"
  "Packages/NearJsonRpcTypes/Sources/Generated/Schemas.generated.swift"
)
for f in $types_to_remove; do
  if [[ -f "$f" ]]; then
    echo "   backup & remove: $f"
    mv "$f" ".backup/$ts/dups/"
  fi
done

echo "== 3) Asegurar tipos básicos canónicos (si faltan) =="
basic_types="Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes/BasicTypes.swift"
if [[ ! -f "$basic_types" ]]; then
  mkdir -p "Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes"
  cat > "$basic_types" <<'SWIFT'
import Foundation

public typealias AccountId = String
public typealias PublicKey = String
public typealias Hash = String
public typealias BlockHeight = UInt64
public typealias Nonce = UInt64
public typealias Base64String = String

public struct U128: Codable, Equatable, Hashable {
    public let value: String
    public init(_ v: String) { self.value = v }
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) { self.value = s; return }
        if let d = try? c.decode(Double.self) { self.value = String(format: "%.0f", d); return }
        throw DecodingError.typeMismatch(U128.self, .init(codingPath: decoder.codingPath, debugDescription: "expected string/number"))
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(value)
    }
}
public typealias Balance = U128
SWIFT
fi

echo "== 4) Reinstalar generador con fix de camel() =="
mkdir -p Scripts
cat > Scripts/generate-from-openapi.swift <<'SWIFT'
#!/usr/bin/env swift
import Foundation

func camel(_ s: String) -> String {
    let parts = s.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
    guard let first = parts.first?.lowercased() else { return s }
    return ([first] + parts.dropFirst().map { String($0).capitalized }).joined()
}
func downloadFirstAvailable(from urls: [String]) -> Data? {
    for u in urls {
        if let url = URL(string: u), let d = try? Data(contentsOf: url), !d.isEmpty {
            return d
        }
    }
    return nil
}
let candidates = [
    "https://rpc.testnet.near.org/openapi-spec.json",
    "https://rpc.mainnet.near.org/openapi-spec.json",
    "https://raw.githubusercontent.com/near/nearcore/master/chain/jsonrpc/res/openapi.json",
    "https://raw.githubusercontent.com/near/nearcore/master/chain/jsonrpc/res/openrpc.json",
    "https://raw.githubusercontent.com/near/near-jsonrpc-client-ts/main/packages/jsonrpc-types/openapi.json"
]
guard let data = downloadFirstAvailable(from: candidates) else {
    fputs("ERROR: no se pudo descargar OpenAPI desde fuentes conocidas\n", stderr); exit(1)
}
guard let specAny = try? JSONSerialization.jsonObject(with: data) as? [String:Any] else {
    fputs("ERROR: JSON inválido\n", stderr); exit(1)
}
var methodNames = [String]()
if let paths = specAny["paths"] as? [String:Any] {
    for (path, _) in paths {
        let name = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !name.isEmpty else { continue }
        methodNames.append(name)
    }
}
methodNames.sort()
let genDir = FileManager.default.currentDirectoryPath + "/Packages/NearJsonRpcClient/Sources/Generated"
try? FileManager.default.createDirectory(atPath: genDir, withIntermediateDirectories: true)
let out = """
// AUTO-GENERATED. DO NOT EDIT.
import Foundation
public enum NearRpcMethod: String, CaseIterable {
\(methodNames.map { "    case \($0.replacingOccurrences(of: ".", with: "_")) = \"\($0)\"" }.joined(separator: "\n"))
}
"""
try out.write(toFile: genDir + "/Methods.generated.swift", atomically: true, encoding: .utf8)
print("OK: Generados \(methodNames.count) métodos.")
SWIFT
chmod +x Scripts/generate-from-openapi.swift

echo "== 5) Generar, compilar, test =="
./Scripts/generate-from-openapi.swift
swift build
swift test --enable-code-coverage
