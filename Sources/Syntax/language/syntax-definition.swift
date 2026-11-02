/// One declared language construct and its default classification.
/// Grammar rules are deliberately not embedded in this first-pass value.
public struct SyntaxDefinition<Kind: SyntaxKind>: Sendable, Codable, Hashable {
    public let kind: Kind
    public let role: SyntaxRole
    public let description: String?

    public init(
        kind: Kind,
        role: SyntaxRole,
        description: String? = nil
    ) {
        self.kind = kind
        self.role = role
        self.description = description
    }
}
