/// Strongly typed construct with non-exclusive default roles.
public struct SyntaxDefinition<Kind: SyntaxKind>: Sendable, Codable, Hashable {
    public let kind: Kind
    public let roles: [SyntaxRole]
    public let description: String?

    public init(kind: Kind, roles: [SyntaxRole], description: String? = nil) {
        self.kind = kind
        self.roles = roles
        self.description = description
    }

    public init(kind: Kind, role: SyntaxRole, description: String? = nil) {
        self.init(kind: kind, roles: [role], description: description)
    }
}

/// Runtime counterpart of a typed declaration for mixed-language documents.
public struct SyntaxDefinitionRecord: Sendable, Codable, Hashable {
    public let name: String
    public let roles: [SyntaxRole]
    public let description: String?

    public init(name: String, roles: [SyntaxRole], description: String? = nil) throws {
        guard !name.isEmpty, !name.allSatisfy(\.isWhitespace) else {
            throw SyntaxError.empty_identifier("kind")
        }
        self.name = name
        self.roles = roles
        self.description = description
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case roles
        case description
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            name: values.decode(String.self, forKey: .name),
            roles: values.decode([SyntaxRole].self, forKey: .roles),
            description: values.decodeIfPresent(String.self, forKey: .description)
        )
    }
}
