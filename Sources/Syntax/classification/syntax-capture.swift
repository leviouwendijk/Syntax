import Position

/// A positioned recognition result, not a copy of captured text.
/// PositionRange uses canonical half-open Swift Character offsets.
public struct SyntaxCapture<Kind: SyntaxKind>: Sendable, Codable, Hashable {
    public let kind: Kind
    public let range: PositionRange
    public let layer: SyntaxLayer
    public let roleOverride: SyntaxRole?
    public let modifiers: [SyntaxModifier]

    public init(
        kind: Kind,
        range: PositionRange,
        layer: SyntaxLayer,
        roleOverride: SyntaxRole? = nil,
        modifiers: [SyntaxModifier] = []
    ) {
        self.kind = kind
        self.range = range
        self.layer = layer
        self.roleOverride = roleOverride
        self.modifiers = modifiers
    }
}
