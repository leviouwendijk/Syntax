public enum SyntaxError: Error, Equatable, Sendable {
    case empty_identifier(String)
    case duplicate_language(String)
    case duplicate_kind(String)
    case unknown_kind(SyntaxIdentifier)
    case invalid_range(start: Int, end: Int)
    case range_out_of_bounds(start: Int, end: Int, source_length: Int)
    case unaligned_boundary(offset: Int)
    case empty_segments
    case unordered_segments
}
