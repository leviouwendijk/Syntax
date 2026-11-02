/// Presentation-neutral classifications shared by languages and consumers.
/// Domain-specific roles remain expressible without changing this enum.
public enum SyntaxRole: Sendable, Codable, Hashable {
    case keyword
    case identifier
    case declaration
    case property
    case type
    case function
    case namespace
    case reference
    case number
    case string
    case comment
    case operator_token
    case punctuation
    case text
    case invalid
    case custom(String)
}
