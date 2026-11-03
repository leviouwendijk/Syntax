import Position

/// An immutable source snapshot with typed UTF-8 capture ranges.
public struct SyntaxDocument: Sendable, Codable, Hashable {
    public let sourceID: String?
    public let source: String
    public let vocabularies: [SyntaxVocabulary]
    public let captures: [SyntaxCapture]

    public init(
        source: String,
        vocabularies: [SyntaxVocabulary],
        captures: [SyntaxCapture],
        sourceID: String? = nil
    ) throws {
        var declared: Set<SyntaxIdentifier> = []
        var languages: Set<String> = []
        for vocabulary in vocabularies {
            guard languages.insert(vocabulary.id).inserted else {
                throw SyntaxError.duplicate_language(vocabulary.id)
            }
            for definition in vocabulary.definitions {
                declared.insert(try SyntaxIdentifier(language: vocabulary.id, name: definition.name))
            }
        }

        let sourceLength = source.utf8.count
        var unresolvedBoundaries: Set<Int> = []
        for capture in captures {
            guard declared.contains(capture.kind) else {
                throw SyntaxError.unknown_kind(capture.kind)
            }
            for range in capture.segments {
                guard range.end.offset <= sourceLength else {
                    throw SyntaxError.range_out_of_bounds(
                        start: range.start.offset,
                        end: range.end.offset,
                        source_length: sourceLength
                    )
                }
                unresolvedBoundaries.insert(range.start.offset)
                unresolvedBoundaries.insert(range.end.offset)
            }
        }

        // Validate only the referenced boundaries, without allocating one record
        // per source scalar. CR and LF are distinct UTF-8 scalar boundaries.
        unresolvedBoundaries.remove(0)
        if !unresolvedBoundaries.isEmpty {
            var offset = 0
            for scalar in source.unicodeScalars {
                offset += scalar.utf8.count
                unresolvedBoundaries.remove(offset)
                if unresolvedBoundaries.isEmpty { break }
            }
            if let invalid = unresolvedBoundaries.min() {
                throw SyntaxError.unaligned_boundary(offset: invalid)
            }
        }

        self.sourceID = sourceID
        self.source = source
        self.vocabularies = vocabularies
        self.captures = captures
    }

    /// Build once and reuse across a batch of projections.
    public var textMap: Position.TextMap {
        Position.TextMap(source: source)
    }

    public var lineTable: LineTable {
        LineTable(text: source)
    }

    /// Only Character-aligned spans can be projected to legacy PositionRange.
    public func positionRange(for range: SyntaxSourceRange) throws -> PositionRange {
        try textMap.legacyRange(range.offsets)
    }

    /// Converts legacy Character spans to canonical typed UTF-8 spans.
    public func sourceRange(for range: PositionRange) throws -> SyntaxSourceRange {
        try SyntaxSourceRange(textMap.range(range, as: Position.Unit.UTF8.self))
    }

    public func roles(for capture: SyntaxCapture) -> [SyntaxRole] {
        let defaults = vocabularies.first { $0.id == capture.kind.language }?
            .definition(named: capture.kind.name)?.roles ?? []
        var result: [SyntaxRole] = []
        for role in defaults + capture.roles where !result.contains(role) {
            result.append(role)
        }
        return result
    }

    /// Text is extracted only at scalar boundaries; captures can split graphemes.
    public func text(in range: SyntaxSourceRange) -> Substring? {
        guard range.end.offset <= source.utf8.count else { return nil }
        let utf8 = source.utf8
        let start = utf8.index(utf8.startIndex, offsetBy: range.start.offset)
        let end = utf8.index(utf8.startIndex, offsetBy: range.end.offset)
        guard start.samePosition(in: source.unicodeScalars) != nil,
              end.samePosition(in: source.unicodeScalars) != nil else {
            return nil
        }
        return source[start..<end]
    }

    private enum CodingKeys: String, CodingKey {
        case sourceID
        case source
        case vocabularies
        case captures
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            source: values.decode(String.self, forKey: .source),
            vocabularies: values.decode([SyntaxVocabulary].self, forKey: .vocabularies),
            captures: values.decode([SyntaxCapture].self, forKey: .captures),
            sourceID: values.decodeIfPresent(String.self, forKey: .sourceID)
        )
    }
}
