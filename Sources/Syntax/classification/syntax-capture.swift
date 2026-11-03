import Primitives

/// One observation about source, independent of how it is presented.
/// Segments can be discontiguous; captures may nest and overlap.
public struct SyntaxCapture: Sendable, Codable, Hashable {
    public let kind: SyntaxIdentifier
    public let segments: [SyntaxSourceRange]
    public let layer: SyntaxLayer
    public let roles: [SyntaxRole]
    public let modifiers: [SyntaxModifier]
    public let attributes: [String: JSONValue]

    public init(
        kind: SyntaxIdentifier,
        segments: [SyntaxSourceRange],
        layer: SyntaxLayer,
        roles: [SyntaxRole] = [],
        modifiers: [SyntaxModifier] = [],
        attributes: [String: JSONValue] = [:]
    ) throws {
        guard !segments.isEmpty else {
            throw SyntaxError.empty_segments
        }
        for index in segments.indices.dropFirst() {
            guard segments[index - 1].end <= segments[index].start else {
                throw SyntaxError.unordered_segments
            }
        }
        self.kind = kind
        self.segments = segments
        self.layer = layer
        self.roles = roles
        self.modifiers = modifiers
        self.attributes = attributes
    }

    public init<Kind: SyntaxKind>(
        language: String,
        kind: Kind,
        segments: [SyntaxSourceRange],
        layer: SyntaxLayer,
        roles: [SyntaxRole] = [],
        modifiers: [SyntaxModifier] = [],
        attributes: [String: JSONValue] = [:]
    ) throws {
        try self.init(
            kind: SyntaxIdentifier(language: language, kind: kind),
            segments: segments,
            layer: layer,
            roles: roles,
            modifiers: modifiers,
            attributes: attributes
        )
    }

    private enum CodingKeys: String, CodingKey {
        case kind
        case segments
        case layer
        case roles
        case modifiers
        case attributes
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            kind: values.decode(SyntaxIdentifier.self, forKey: .kind),
            segments: values.decode([SyntaxSourceRange].self, forKey: .segments),
            layer: values.decode(SyntaxLayer.self, forKey: .layer),
            roles: values.decodeIfPresent([SyntaxRole].self, forKey: .roles) ?? [],
            modifiers: values.decodeIfPresent([SyntaxModifier].self, forKey: .modifiers) ?? [],
            attributes: values.decodeIfPresent([String: JSONValue].self, forKey: .attributes) ?? [:]
        )
    }
}
