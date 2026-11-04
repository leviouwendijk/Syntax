/// A nonoverlapping text slice with every source classification that applies.
public struct SyntaxRun: Sendable, Hashable {
    public let range: SyntaxSourceRange
    public let captures: [SyntaxCapture]
}

public struct SyntaxPoint: Sendable, Hashable {
    public let offset: Int
    public let capture: SyntaxCapture
}

public struct SyntaxLine: Sendable, Hashable {
    public let index: Int
    public let content: SyntaxSourceRange
    public let terminator: SyntaxSourceRange
    public let runs: [SyntaxRun]
    public let terminatorRuns: [SyntaxRun]
}

/// Splits source without discarding trivia, overlap, empty lines or newline bytes.
public struct SyntaxProjection: Sendable {
    public let lines: [SyntaxLine]
    public let points: [SyntaxPoint]

    public init(document: SyntaxDocument) throws {
        let bytes = Array(document.source.utf8)
        var result: [SyntaxLine] = []
        var start = 0
        var offset = 0

        func appendLine(contentEnd: Int, terminatorEnd: Int) throws {
            let range = try SyntaxSourceRange(start: start, end: contentEnd)
            result.append(SyntaxLine(
                index: result.count,
                content: range,
                terminator: try SyntaxSourceRange(start: contentEnd, end: terminatorEnd),
                runs: try Self.makeRuns(in: range, document: document),
                terminatorRuns: try Self.makeRuns(
                    in: SyntaxSourceRange(start: contentEnd, end: terminatorEnd),
                    document: document
                )
            ))
        }

        while offset < bytes.count {
            if bytes[offset] == 10 || bytes[offset] == 13 {
                var end = offset + 1
                if bytes[offset] == 13, end < bytes.count, bytes[end] == 10 {
                    end += 1
                }
                try appendLine(contentEnd: offset, terminatorEnd: end)
                offset = end
                start = end
            } else {
                offset += 1
            }
        }
        try appendLine(contentEnd: bytes.count, terminatorEnd: bytes.count)
        lines = result
        points = document.captures.flatMap { capture in
            capture.segments.filter(\.isEmpty).map {
                SyntaxPoint(offset: $0.start.offset, capture: capture)
            }
        }
    }

    private static func makeRuns(
        in line: SyntaxSourceRange,
        document: SyntaxDocument
    ) throws -> [SyntaxRun] {
        let lower = line.start.offset
        let upper = line.end.offset
        if lower == upper { return [] }
        var boundaries: Set<Int> = [lower, upper]
        for capture in document.captures {
            for segment in capture.segments where !segment.isEmpty {
                let begin = max(lower, segment.start.offset)
                let end = min(upper, segment.end.offset)
                if begin < end {
                    boundaries.insert(begin)
                    boundaries.insert(end)
                }
            }
        }
        let sorted = boundaries.sorted()
        var runs: [SyntaxRun] = []
        for index in 0..<(sorted.count - 1) {
            let begin = sorted[index]
            let end = sorted[index + 1]
            let active = document.captures.filter { capture in
                capture.segments.contains { segment in
                    !segment.isEmpty && segment.start.offset <= begin && segment.end.offset >= end
                }
            }
            runs.append(SyntaxRun(
                range: try SyntaxSourceRange(start: begin, end: end),
                captures: active
            ))
        }
        return runs
    }
}
