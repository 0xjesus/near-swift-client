#!/usr/bin/env zsh
set -e

# --- Config ---
ROOT=$(pwd)
TYPES_DIR="Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes"
CLIENT_DIR="Packages/NearJsonRpcClient/Sources/NearJsonRpcClient"

echo "== Sanity check =="
test -d "$TYPES_DIR" || { echo "No existe $TYPES_DIR. Asegúrate de estar en la raíz del repo."; exit 1; }

# 1) Quitar archivos no-Swift de Sources (para evitar warnings de SPM)
echo "== 1) Mover archivos no-Swift fuera de Sources =="
mkdir -p "Packages/NearJsonRpcTypes/Schemas"
for f in "$TYPES_DIR"/*.json "$TYPES_DIR"/*.yaml "$TYPES_DIR"/*.yml; do
  [ -f "$f" ] && mv "$f" "Packages/NearJsonRpcTypes/Schemas/" || true
done

# Soportar un typo de carpeta (por si existe NearRPCTypes)
if [ -d "Packages/NearJsonRpcTypes/Sources/NearRPCTypes" ]; then
  mkdir -p "Packages/NearJsonRpcTypes/Schemas"
  for f in Packages/NearJsonRpcTypes/Sources/NearRPCTypes/*.(json|yaml|yml); do
    [ -f "$f" ] && mv "$f" "Packages/NearJsonRpcTypes/Schemas/" || true
  done
fi

# 2) Retirar Swift duplicado que choca (ambigüedades U128, BlockHeader, etc.)
echo "== 2) Quitar archivos Swift duplicados/obsoletos =="
mkdir -p "$TYPES_DIR/_trash"
for f in AccountsContracts.swift ProtocolGenesis.swift Primitives.swift Transactions.swift StateChanges.swift BlocksChunks.swift; do
  if [ -f "$TYPES_DIR/$f" ]; then
    mv "$TYPES_DIR/$f" "$TYPES_DIR/_trash/$f.bak"
    echo "   -> moved $f to _trash"
  fi
done

# 3) Reinstalar definiciones canónicas mínimas (evitamos duplicados)
echo "== 3) Escribir definiciones canónicas (Primitives.swift, JSONValue.swift, CaseConversion.swift) =="
cat > "$TYPES_DIR/Primitives.swift" <<'SWIFT'
import Foundation

public typealias AccountId = String
public typealias PublicKey = String
public typealias Hash = String
public typealias CryptoHash = String
public typealias BlockHeight = UInt64
public typealias Nonce = UInt64
public typealias Balance = String        // NEAR usa string decimal para cantidades
public typealias Base64String = String   // datos codificados (argsBase64)

/** Entero grande serializado como String (convención en RPC de NEAR). */
public struct U128: Codable, Hashable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let value: String
    public init(_ v: String) { self.value = v }
    public init(stringLiteral value: String) { self.value = value }
    public var description: String { value }
}

/** Análogo a U64, con envoltura explícita cuando el RPC lo usa como string. */
public struct U64: Codable, Hashable, ExpressibleByIntegerLiteral, CustomStringConvertible {
    public let value: UInt64
    public init(_ v: UInt64) { self.value = v }
    public init(integerLiteral value: UInt64) { self.value = value }
    public var description: String { String(value) }
}
SWIFT

cat > "$TYPES_DIR/JSONValue.swift" <<'SWIFT'
import Foundation

/** JSONValue: ayuda para mapear payloads heterogéneos del RPC */
public enum JSONValue: Codable, Equatable, Hashable {
    case string(String)
    case number(Double)
    case object([String: JSONValue])
    case array([JSONValue])
    case bool(Bool)
    case null

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let b = try? c.decode(Bool.self) { self = .bool(b); return }
        if let n = try? c.decode(Double.self) { self = .number(n); return }
        if let s = try? c.decode(String.self) { self = .string(s); return }
        if let a = try? c.decode([JSONValue].self) { self = .array(a); return }
        if let o = try? c.decode([String: JSONValue].self) { self = .object(o); return }
        throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported JSON value")
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let s): try c.encode(s)
        case .number(let n): try c.encode(n)
        case .object(let o): try c.encode(o)
        case .array(let a): try c.encode(a)
        case .bool(let b): try c.encode(b)
        case .null: try c.encodeNil()
        }
    }
}
SWIFT

# Reescribir CaseConversion.swift para avisos de @unchecked Sendable y key strategy
cat > "$TYPES_DIR/CaseConversion.swift" <<'SWIFT'
import Foundation

/** convierte snake_case a camelCase */
func snakeToCamel(_ s: String) -> String {
    let parts = s.split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { !$0.isEmpty }
    guard let first = parts.first?.lowercased() else { return s }
    let rest = parts.dropFirst().map { $0.capitalized }
    return ([first] + rest).joined()
}

/** Encoder/Decoder con estrategias Near */
@unchecked Sendable
public class NearJSONDecoder: JSONDecoder {
    public override init() {
        super.init()
        keyDecodingStrategy = .custom { keys in
            let last = keys.last!.stringValue
            return AnyKey(stringValue: snakeToCamel(last))
        }
        dateDecodingStrategy = .iso8601
    }
}

@unchecked Sendable
public class NearJSONEncoder: JSONEncoder {
    public override init() {
        super.init()
        keyEncodingStrategy = .convertToSnakeCase
        outputFormatting = [.withoutEscapingSlashes]
        dateEncodingStrategy = .iso8601
    }
}

fileprivate struct AnyKey: CodingKey {
    var stringValue: String
    init(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { nil }
    init?(intValue: Int) { return nil }
}
SWIFT

# 4) Fix al generador: paréntesis en camel() y fuentes de OpenAPI
echo "== 4) Arreglar Scripts/generate-from-openapi.swift (si existe) =="
GEN="Scripts/generate-from-openapi.swift"
if [ -f "$GEN" ]; then
  # asegurar que el bug de camel() con .joined() tenga paréntesis
  sed -i '' -E 's/return \[first\] \+ parts\.dropFirst\(\)\.map\{ \\\$0\.capitalized \}\.joined\(\)/return (\[first\] \+ parts.dropFirst\(\).map{ \\\$0.capitalized }).joined()/' "$GEN" || true

  # Inyectar una función fetchOpenAPI si no existe
  if ! grep -q "func fetchOpenAPISpec" "$GEN"; then
    cat >> "$GEN" <<'SWIFT'

import Foundation

func fetchOpenAPISpec(to path: String) throws {
    let urls = [
        // Intento "oficial" (puede cambiar)
        "https://raw.githubusercontent.com/near/nearcore/master/chain/jsonrpc/res/openapi.json",
        // Repo TS monorepo (puede cambiar)
        "https://raw.githubusercontent.com/near/near-jsonrpc-client-ts/main/packages/jsonrpc-types/openapi.json",
        // Fallback verificado (tercero)
        "https://raw.githubusercontent.com/PolyProgrammist/near-openapi-client/main/openapi.json"
    ]
    for u in urls {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["curl","-fsSL","-o", path, u]
        task.launch()
        task.waitUntilExit()
        if task.terminationStatus == 0 { return }
    }
    throw NSError(domain: "OpenAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se pudo descargar OpenAPI de fuentes conocidas"])
}
SWIFT
  fi
fi

# 5) Descargar OpenAPI (usando fallback) a Schemas/openapi.json
echo "== 5) Descargar OpenAPI =="
SCHEMA_PATH="Packages/NearJsonRpcTypes/Schemas/openapi.json"
rm -f "$SCHEMA_PATH"
# Primero intentamos con curl directamente al fallback que sí existe:
if ! curl -fsSL -o "$SCHEMA_PATH" "https://raw.githubusercontent.com/PolyProgrammist/near-openapi-client/main/openapi.json"; then
  echo "   Fallback directo falló, intentando con script Swift (si existe)…"
  if [ -f "$GEN" ]; then
    swift "$GEN" || true
  fi
fi
test -f "$SCHEMA_PATH" || { echo "ERROR: no se pudo descargar OpenAPI desde fuentes conocidas"; exit 2; }

# 6) Build + Tests
echo "== 6) Build y Tests con cobertura =="
swift build
swift test --enable-code-coverage

echo "== OK =="
