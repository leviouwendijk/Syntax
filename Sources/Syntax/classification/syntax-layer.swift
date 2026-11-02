/// Classification origin. Different layers may overlap in source.
public enum SyntaxLayer: String, Sendable, Codable, Hashable {
    case lexical
    case syntactic
    case semantic
}
