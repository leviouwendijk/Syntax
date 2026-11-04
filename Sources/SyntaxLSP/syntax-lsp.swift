import Position
import Syntax

/// Semantic-token data projection, independent of JSON-RPC transport and editing.
public enum SyntaxLSP {
    public enum Failure: Swift.Error, Equatable, Sendable {
        case duplicate_type(String)
        case unknown_type(String)
    }

    public struct Legend: Sendable {
        public let types: [String]

        public init(types: [String]) throws {
            var seen: Set<String> = []
            for type in types {
                guard seen.insert(type).inserted else {
                    throw Failure.duplicate_type(type)
                }
            }
            self.types = types
        }
    }

    public struct Rule: Sendable {
        public let selector: SyntaxSelector
        public let type: String
        public let priority: Int

        public init(selector: SyntaxSelector, type: String, priority: Int = 0) {
            self.selector = selector
            self.type = type
            self.priority = priority
        }
    }

    public struct Token: Sendable, Equatable {
        public let line: Int
        public let column: Int
        public let length: Int
        public let typeIndex: Int
        public let modifiers: Int
    }

    public static func project(
        document: SyntaxDocument,
        legend: Legend,
        rules: [Rule]
    ) throws -> [Token] {
        let projection = try SyntaxProjection(document: document)
        let map = Position.TextMap(source: document.source)
        var result: [Token] = []

        for line in projection.lines {
            let lineOffset = try map.convert(
                Position.Offset<Position.Unit.UTF8>(line.content.start.offset),
                to: Position.Unit.UTF16.self
            ).offset
            for run in line.runs {
                let matching = rules.enumerated().filter { _, rule in
                    run.captures.contains { rule.selector.matches($0, in: document) }
                }.sorted { lhs, rhs in
                    if lhs.element.priority != rhs.element.priority {
                        return lhs.element.priority < rhs.element.priority
                    }
                    if lhs.element.selector.specificity != rhs.element.selector.specificity {
                        return lhs.element.selector.specificity < rhs.element.selector.specificity
                    }
                    return lhs.offset < rhs.offset
                }
                guard let rule = matching.last?.element else { continue }
                guard let typeIndex = legend.types.firstIndex(of: rule.type) else {
                    throw Failure.unknown_type(rule.type)
                }
                let begin = try map.convert(
                    Position.Offset<Position.Unit.UTF8>(run.range.start.offset),
                    to: Position.Unit.UTF16.self
                ).offset - lineOffset
                let end = try map.convert(
                    Position.Offset<Position.Unit.UTF8>(run.range.end.offset),
                    to: Position.Unit.UTF16.self
                ).offset - lineOffset
                guard end > begin else { continue }
                if let last = result.last,
                   last.line == line.index,
                   last.column + last.length == begin,
                   last.typeIndex == typeIndex,
                   last.modifiers == 0 {
                    result[result.count - 1] = Token(
                        line: last.line, column: last.column,
                        length: last.length + end - begin,
                        typeIndex: typeIndex, modifiers: 0
                    )
                } else {
                    result.append(Token(
                        line: line.index, column: begin, length: end - begin,
                        typeIndex: typeIndex, modifiers: 0
                    ))
                }
            }
        }
        return result
    }

    /// LSP's ordered five-integer delta encoding.
    public static func encode(_ tokens: [Token]) -> [Int] {
        var result: [Int] = []
        result.reserveCapacity(tokens.count * 5)
        var previousLine = 0
        var previousColumn = 0
        for token in tokens {
            let lineDelta = token.line - previousLine
            let columnDelta = lineDelta == 0 ? token.column - previousColumn : token.column
            result.append(contentsOf: [
                lineDelta, columnDelta, token.length, token.typeIndex, token.modifiers
            ])
            previousLine = token.line
            previousColumn = token.column
        }
        return result
    }
}
