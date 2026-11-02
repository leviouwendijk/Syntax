import Position

public enum SyntaxDocumentError: Error, Sendable, Equatable {
    case unknown_kind(String)
    case range_out_of_bounds(kind: String, start: Int, end: Int, sourceLength: Int)
}

/// Source material and independent, potentially overlapping classifications.
/// Construction establishes that captures belong to the language and source.
public struct SyntaxDocument<Kind: SyntaxKind>: Sendable, Codable, Hashable {
    public let sourceID: String?
    public let source: String
    public let language: SyntaxLanguage<Kind>
    public let captures: [SyntaxCapture<Kind>]

    public init(
        source: String,
        language: SyntaxLanguage<Kind>,
        captures: [SyntaxCapture<Kind>],
        sourceID: String? = nil
    ) throws {
        let length = source.count
        let declared = Set(language.definitions.map(\.kind))

        for capture in captures {
            guard declared.contains(capture.kind) else {
                throw SyntaxDocumentError.unknown_kind(capture.kind.rawValue)
            }
            let start = capture.range.start.offset
            let end = capture.range.end.offset
            guard start >= 0, end >= start, end <= length else {
                throw SyntaxDocumentError.range_out_of_bounds(
                    kind: capture.kind.rawValue,
                    start: start,
                    end: end,
                    sourceLength: length
                )
            }
        }

        self.sourceID = sourceID
        self.source = source
        self.language = language
        self.captures = captures
    }

    public var lineTable: LineTable {
        LineTable(text: source)
    }

    public func role(for capture: SyntaxCapture<Kind>) -> SyntaxRole? {
        capture.roleOverride ?? language.definition(for: capture.kind)?.role
    }

    public func text(in range: PositionRange) -> Substring? {
        let lower = range.start.offset
        let upper = range.end.offset
        guard lower >= 0, upper >= lower, upper <= source.count else {
            return nil
        }
        let start = source.index(source.startIndex, offsetBy: lower)
        let end = source.index(source.startIndex, offsetBy: upper)
        return source[start..<end]
    }

    private enum CodingKeys: String, CodingKey {
        case sourceID
        case source
        case language
        case captures
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            source: values.decode(String.self, forKey: .source),
            language: values.decode(SyntaxLanguage<Kind>.self, forKey: .language),
            captures: values.decode([SyntaxCapture<Kind>].self, forKey: .captures),
            sourceID: values.decodeIfPresent(String.self, forKey: .sourceID)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(sourceID, forKey: .sourceID)
        try values.encode(source, forKey: .source)
        try values.encode(language, forKey: .language)
        try values.encode(captures, forKey: .captures)
    }
}
