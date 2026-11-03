/// Typed authoring catalog for one language.
public struct SyntaxLanguage<Kind: SyntaxKind>: Sendable, Codable, Hashable {
    public let id: String
    public let definitions: [SyntaxDefinition<Kind>]

    public init(id: String, definitions: [SyntaxDefinition<Kind>]) throws {
        guard !id.isEmpty, !id.allSatisfy(\.isWhitespace) else {
            throw SyntaxError.empty_identifier("language")
        }
        var seen: Set<String> = []
        for definition in definitions {
            let name = definition.kind.rawValue
            guard !name.isEmpty, !name.allSatisfy(\.isWhitespace) else {
                throw SyntaxError.empty_identifier("kind")
            }
            guard seen.insert(name).inserted else {
                throw SyntaxError.duplicate_kind(name)
            }
        }
        self.id = id
        self.definitions = definitions
    }

    public func vocabulary() throws -> SyntaxVocabulary {
        try SyntaxVocabulary(
            id: id,
            definitions: definitions.map {
                try SyntaxDefinitionRecord(
                    name: $0.kind.rawValue,
                    roles: $0.roles,
                    description: $0.description
                )
            }
        )
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
}

/// Type-erased vocabulary supporting several languages in one document.
public struct SyntaxVocabulary: Sendable, Codable, Hashable {
    public let id: String
    public let definitions: [SyntaxDefinitionRecord]

    public init(id: String, definitions: [SyntaxDefinitionRecord]) throws {
        guard !id.isEmpty, !id.allSatisfy(\.isWhitespace) else {
            throw SyntaxError.empty_identifier("language")
        }
        var seen: Set<String> = []
        for definition in definitions {
            guard seen.insert(definition.name).inserted else {
                throw SyntaxError.duplicate_kind(definition.name)
            }
        }
        self.id = id
        self.definitions = definitions
    }

    public func definition(named name: String) -> SyntaxDefinitionRecord? {
        definitions.first { $0.name == name }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case definitions
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: values.decode(String.self, forKey: .id),
            definitions: values.decode([SyntaxDefinitionRecord].self, forKey: .definitions)
        )
    }
}
