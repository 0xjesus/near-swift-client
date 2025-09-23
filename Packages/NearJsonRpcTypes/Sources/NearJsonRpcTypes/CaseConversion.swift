import Foundation

public extension String {
    /// Convert snake_case to camelCase
    var camelCased: String {
        let components = self.split(separator: "_")
        guard !components.isEmpty else { return self }
        
        let first = String(components[0])
        let rest = components.dropFirst().map { 
            String($0).capitalized 
        }
        
        return ([first] + rest).joined()
    }
    
    /// Convert camelCase to snake_case
    var snakeCased: String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.stringByReplacingMatches(
            in: self,
            range: range,
            withTemplate: "$1_$2"
        ).lowercased()
    }
}

/// Custom JSON Decoder with snake_case to camelCase conversion
public final class NearJSONDecoder: JSONDecoder, @unchecked Sendable {
    public override init() {
        super.init()
        self.keyDecodingStrategy = .custom { keys in
            let key = keys.last!.stringValue
            let camelKey = key.camelCased
            return AnyCodingKey(stringValue: camelKey)!
        }
    }
}

/// Custom JSON Encoder with camelCase to snake_case conversion
public final class NearJSONEncoder: JSONEncoder, @unchecked Sendable {
    public override init() {
        super.init()
        self.keyEncodingStrategy = .custom { keys in
            let key = keys.last!.stringValue
            let snakeKey = key.snakeCased
            return AnyCodingKey(stringValue: snakeKey)!
        }
    }
}

private struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}
