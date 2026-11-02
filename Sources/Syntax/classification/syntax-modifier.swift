/// Meaning orthogonal to a construct's syntax role and language kind.
public enum SyntaxModifier: Sendable, Codable, Hashable {
    case declaration
    case definition
    case readonly
    case static_member
    case deprecated
    case unresolved
    case invalid
    case documentation
    case custom(String)
}
