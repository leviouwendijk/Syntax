/// Stable, language-qualified syntax identity, independent of a Swift enum.
public struct SyntaxIdentifier: Sendable, Codable, Hashable {
    public let language: String
    public let name: String

    public init(language: String, name: String) throws {
        guard !language.isEmpty, !language.allSatisfy(\.isWhitespace) else {
            throw SyntaxError.empty_identifier("language")
        }
        guard !name.isEmpty, !name.allSatisfy(\.isWhitespace) else {
            throw SyntaxError.empty_identifier("kind")
        }
        self.language = language
        self.name = name
    }

    public init<Kind: SyntaxKind>(language: String, kind: Kind) throws {
        try self.init(language: language, name: kind.rawValue)
    }

    private enum CodingKeys: String, CodingKey {
        case language
        case name
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            language: values.decode(String.self, forKey: .language),
            name: values.decode(String.self, forKey: .name)
        )
    }
}
