public typealias CryptoHash = String

// -----------------------------------------------------------------------------
// Compat: algunos tests referencian `Components.Schemas.BlockReference.case_Finality(...)`
// Si el OpenAPI generado no trae ese tipo, proveemos un stub mínimo aquí.
// Se apoya en `Components.Schemas.Finality` que ya existe en los tipos generados.
// -----------------------------------------------------------------------------
public extension Components.Schemas {
    struct BlockReference: Encodable, Equatable {
        public let finality: Components.Schemas.Finality

        public init(finality: Components.Schemas.Finality) {
            self.finality = finality
        }

        /// Constructor “case_” que esperan los tests
        public static func case_Finality(_ f: Components.Schemas.Finality) -> Self {
            .init(finality: f)
        }
    }
}
