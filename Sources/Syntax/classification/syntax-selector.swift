/// A reusable matching rule. Specified fields are conjunctive.
public struct SyntaxSelector: Sendable, Hashable {
    public let language: String?
    public let kind: String?
    public let role: SyntaxRole?
    public let modifier: SyntaxModifier?
    public let layer: SyntaxLayer?

    public init(
        language: String? = nil,
        kind: String? = nil,
        role: SyntaxRole? = nil,
        modifier: SyntaxModifier? = nil,
        layer: SyntaxLayer? = nil
    ) {
        self.language = language
        self.kind = kind
        self.role = role
        self.modifier = modifier
        self.layer = layer
    }

    public var specificity: Int {
        [language != nil, kind != nil, role != nil, modifier != nil, layer != nil]
            .filter { $0 }.count
    }

    public func matches(_ capture: SyntaxCapture, in document: SyntaxDocument) -> Bool {
        if let language, language != capture.kind.language { return false }
        if let kind, kind != capture.kind.name { return false }
        if let role, !document.roles(for: capture).contains(role) { return false }
        if let modifier, !capture.modifiers.contains(modifier) { return false }
        if let layer, layer != capture.layer { return false }
        return true
    }
}
