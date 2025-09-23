#!/usr/bin/env zsh
set -e
setopt NULL_GLOB

ROOT=$PWD
TYPES_DIR="Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes"
SCHEMAS_DIR="Packages/NearJsonRpcTypes/Schemas"
CLIENT_DIR="Packages/NearJsonRpcClient/Sources/NearJsonRpcClient"
GEN_DIR="Packages/NearJsonRpcClient/Sources/NearJsonRpcClient/Generated"
BACKUP=".backup/$(date +%Y%m%d_%H%M%S)"

echo "== Sanity check =="
test -d "$TYPES_DIR" || { echo "No existe $TYPES_DIR. Corre esto desde la raíz del repo."; exit 1; }

mkdir -p "$BACKUP" "$SCHEMAS_DIR" "$CLIENT_DIR" "$GEN_DIR" Scripts

echo "== 1) Mover .json/.yaml fuera de Sources (SPM solo quiere .swift) =="
find "$TYPES_DIR" -maxdepth 1 -type f \( -name '*.json' -o -name '*.yaml' -o -name '*.yml' \) -print -exec mv {} "$SCHEMAS_DIR"/ \;

echo "== 2) Retirar archivos Swift duplicados conflictivos (backup en $BACKUP) =="
for f in BlocksChunks.swift AccountsContracts.swift ProtocolGenesis.swift Transactions.swift StateChanges.swift ValidatorsLightClient.swift Primitives.swift; do
  if [[ -f "$TYPES_DIR/$f" ]]; then
    echo "   backup & remove: $TYPES_DIR/$f"
    mv "$TYPES_DIR/$f" "$BACKUP/$f.bak"
  fi
done

echo "== 3) Descargar OpenAPI (intenta 3 fuentes) =="
TARGET="$SCHEMAS_DIR/openapi.json"
rm -f "$TARGET"
for URL in \
  "https://raw.githubusercontent.com/PolyProgrammist/near-openapi-client/main/openapi.json" \
  "https://raw.githubusercontent.com/near/near-jsonrpc-client-ts/main/packages/jsonrpc-types/openapi.json" \
  "https://raw.githubusercontent.com/near/nearcore/master/chain/jsonrpc/res/openapi.json"
do
  echo "   -> $URL"
  if curl -fsSL "$URL" -o "$TARGET"; then
    break
  fi
done
if [[ ! -f "$TARGET" ]]; then
  echo "ERROR: no se pudo descargar OpenAPI desde fuentes conocidas"; exit 2
fi

echo "== 4) Generador: crea enum de métodos y forzamos POST '/' en el cliente =="
cat > Scripts/generate-from-openapi.swift <<'SWIFT'
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
SWIFT
chmod +x Scripts/generate-from-openapi.swift

cat > "$CLIENT_DIR/ForceSlashTransport.swift" <<'SWIFT'
import Foundation

/// Transport que SIEMPRE hace POST "/" (requisito del bounty)
public final class ForceSlashTransport {
    private let baseURL: URL
    private let session: URLSession
    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    public func postJSON(body: Data, headers: [String:String] = [:]) async throws -> (Data, URLResponse) {
        var comps = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        comps.path = "/"
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "POST"
        req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        headers.forEach { k,v in req.setValue(v, forHTTPHeaderField: k) }
        return try await session.data(for: req)
    }
}
SWIFT

echo "== 5) Generar, compilar y testear =="
swift Scripts/generate-from-openapi.swift
swift build
swift test --enable-code-coverage

echo "== DONE =="
