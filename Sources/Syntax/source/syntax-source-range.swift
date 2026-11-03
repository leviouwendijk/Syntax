import Position

/// Half-open UTF-8 byte span. Exact textual boundary validation belongs to SyntaxDocument.
public struct SyntaxSourceRange: Sendable, Codable, Hashable {
    public typealias Offset = Position.Offset<Position.Unit.UTF8>

    public let start: Offset
    public let end: Offset

    public init(start: Offset, end: Offset) throws {
        guard start <= end else {
            throw SyntaxError.invalid_range(start: start.offset, end: end.offset)
        }
        self.start = start
        self.end = end
    }

    public init(start: Int, end: Int) throws {
        guard start >= 0, end >= start else {
            throw SyntaxError.invalid_range(start: start, end: end)
        }
        try self.init(start: Offset(start), end: Offset(end))
    }

    public init(_ range: Range<Int>) throws {
        try self.init(start: range.lowerBound, end: range.upperBound)
    }

    public init(_ range: Range<Offset>) throws {
        try self.init(start: range.lowerBound, end: range.upperBound)
    }

    public var offsets: Range<Offset> { start..<end }
    public var isEmpty: Bool { start == end }
    public var length: Int { end.offset - start.offset }

    private enum CodingKeys: String, CodingKey { case start, end }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            start: values.decode(Int.self, forKey: .start),
            end: values.decode(Int.self, forKey: .end)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(start.offset, forKey: .start)
        try values.encode(end.offset, forKey: .end)
    }
}
