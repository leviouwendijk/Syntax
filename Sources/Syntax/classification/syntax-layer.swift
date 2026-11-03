/// Classification origin, not a rendering priority or precedence.
public enum SyntaxLayer: Sendable, Codable, Hashable {
    case lexical
    case syntactic
    case semantic
    case diagnostic
    case custom(String)
}
