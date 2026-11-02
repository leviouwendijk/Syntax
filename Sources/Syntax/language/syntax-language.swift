public enum SyntaxLanguageError: Error, Sendable, Equatable {
    case empty_id
    case duplicate_kind(String)
}

/// An inspectable catalog of typed language constructs.
/// Lexer and parser implementations remain independent.
public struct SyntaxLanguage<Kind: SyntaxKind>: Sendable, Codable, Hashable {
    public let id: String
    public let definitions: [SyntaxDefinition<Kind>]

    public init(
        id: String,
        definitions: [SyntaxDefinition<Kind>]
    ) throws {
        guard !id.isEmpty, !id.allSatisfy(\.isWhitespace) else {
            throw SyntaxLanguageError.empty_id
        }

        var seen: Set<Kind> = []
        for definition in definitions {
            guard seen.insert(definition.kind).inserted else {
                throw SyntaxLanguageError.duplicate_kind(definition.kind.rawValue)
            }
        }

        self.id = id
        self.definitions = definitions
    }

    public func definition(for kind: Kind) -> SyntaxDefinition<Kind>? {
        definitions.first { $0.kind == kind }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case definitions
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: values.decode(String.self, forKey: .id),
            definitions: values.decode([SyntaxDefinition<Kind>].self, forKey: .definitions)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(definitions, forKey: .definitions)
    }
}
