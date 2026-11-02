/// A language's strongly typed names for source constructs.
/// Parsing and rendering remain external to this protocol.
public protocol SyntaxKind: RawRepresentable, Codable, Hashable, Sendable where RawValue == String {}
