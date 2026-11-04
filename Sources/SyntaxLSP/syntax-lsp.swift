import Position
import Syntax

/// Semantic-token and diagnostic projections; no JSON-RPC transport or theme selection.
public enum SyntaxLSP {
    public enum Failure: Swift.Error, Equatable, Sendable {
        case duplicate_type(String)
        case unknown_type(String)
        case duplicate_modifier(String)
        case unknown_modifier(String)
        case too_many_modifiers(Int)
    }

    public struct Legend: Sendable {
        public let types: [String]
        public let modifiers: [String]

        public init(types: [String], modifiers: [String] = []) throws {
            var seenTypes: Set<String> = []
            for type in types {
                guard seenTypes.insert(type).inserted else {
                    throw Failure.duplicate_type(type)
                }
            }
            guard modifiers.count <= 32 else {
                throw Failure.too_many_modifiers(modifiers.count)
            }
            var seenModifiers: Set<String> = []
            for modifier in modifiers {
                guard seenModifiers.insert(modifier).inserted else {
                    throw Failure.duplicate_modifier(modifier)
                }
            }
            self.types = types
            self.modifiers = modifiers
        }
    }

    public struct Rule: Sendable {
        public let selector: SyntaxSelector
        public let type: String
        public let modifiers: [String]
        public let priority: Int

        public init(
            selector: SyntaxSelector,
            type: String,
            modifiers: [String] = [],
            priority: Int = 0
        ) {
            self.selector = selector
            self.type = type
            self.modifiers = modifiers
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

    public struct Location: Sendable, Equatable {
        public let line: Int
        public let character: Int
    }

    public struct Diagnostic: Sendable, Equatable {
        public let start: Location
        public let end: Location
        public let severity: SyntaxDiagnostic.Severity
        public let message: String
        public let code: String?
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

                var mask = 0
                for name in rule.modifiers {
                    guard let index = legend.modifiers.firstIndex(of: name) else {
                        throw Failure.unknown_modifier(name)
                    }
                    mask |= 1 << index
                }
                let captured = run.captures.filter {
                    rule.selector.matches($0, in: document)
                }
                for capture in captured {
                    for modifier in capture.modifiers {
                        if let index = legend.modifiers.firstIndex(of: name(for: modifier)) {
                            mask |= 1 << index
                        }
                    }
                }
                if let last = result.last,
                   last.line == line.index,
                   last.column + last.length == begin,
                   last.typeIndex == typeIndex,
                   last.modifiers == mask {
                    result[result.count - 1] = Token(
                        line: last.line, column: last.column,
                        length: last.length + end - begin,
                        typeIndex: typeIndex, modifiers: mask
                    )
                } else {
                    result.append(Token(
                        line: line.index, column: begin, length: end - begin,
                        typeIndex: typeIndex, modifiers: mask
                    ))
                }
            }
        }
        return result
    }

    /// Project canonical source diagnostics into zero-based LSP UTF-16 positions.
    public static func diagnostics(
        document: SyntaxDocument,
        values: [SyntaxDiagnostic]
    ) throws -> [Diagnostic] {
        let map = Position.TextMap(source: document.source)

        func location(_ offset: Position.Offset<Position.Unit.UTF8>) throws -> Location {
            // TextMap is the authority for line/column boundaries, including CRLF.
            // Unrepresentable boundaries fail explicitly instead of being rounded.
            let utf8 = try map.coordinate(at: offset)
            let utf16 = try map.convert(utf8, to: Position.Unit.UTF16.self)
            return Location(line: utf16.line - 1, character: utf16.column - 1)
        }

        return try values.map { value in
            Diagnostic(
                start: try location(value.range.start),
                end: try location(value.range.end),
                severity: value.severity,
                message: value.message,
                code: value.code
            )
        }
    }

    private static func name(for modifier: SyntaxModifier) -> String {
        switch modifier {
        case .declaration: "declaration"
        case .definition: "definition"
        case .readonly: "readonly"
        case .static_member: "static_member"
        case .deprecated: "deprecated"
        case .unresolved: "unresolved"
        case .invalid: "invalid"
        case .documentation: "documentation"
        case .custom(let name): name
        }
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
