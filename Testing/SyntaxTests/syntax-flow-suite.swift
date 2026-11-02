import Position
import Syntax
import Testing

enum SyntaxTestSuite {
    enum ECKind: String, SyntaxKind {
        case entry
        case entry_id
        case identifier
        case undeclared
    }

    static let suite = TestSuite(
        "syntax",
        title: "Syntax foundation"
    ) {
        Test("typed definitions resolve roles without renderer knowledge") {
            let language = try SyntaxLanguage<ECKind>(
                id: "ec",
                definitions: [
                    .init(kind: .entry, role: .declaration),
                    .init(kind: .entry_id, role: .property),
                    .init(kind: .identifier, role: .identifier)
                ]
            )
            let capture = SyntaxCapture(
                kind: ECKind.entry,
                range: PositionRange(0..<5),
                layer: .syntactic
            )
            let document = try SyntaxDocument(
                source: "entry",
                language: language,
                captures: [capture]
            )
            try Expect.equal(document.role(for: capture), SyntaxRole.declaration, "default role")
            try Expect.equal(String(document.text(in: capture.range) ?? ""), "entry", "source text")
        }

        Test("semantic and syntactic captures may overlap") {
            let language = try SyntaxLanguage<ECKind>(
                id: "ec",
                definitions: [
                    .init(kind: .entry, role: .declaration),
                    .init(kind: .entry_id, role: .number)
                ]
            )
            let outer = SyntaxCapture(kind: ECKind.entry, range: PositionRange(0..<9), layer: .syntactic)
            let inner = SyntaxCapture(
                kind: ECKind.entry_id,
                range: PositionRange(5..<9),
                layer: .semantic,
                roleOverride: .reference,
                modifiers: [.definition]
            )
            let document = try SyntaxDocument(
                source: "entry2582",
                language: language,
                captures: [outer, inner]
            )
            try Expect.equal(document.captures.count, 2, "overlap accepted")
            try Expect.equal(document.role(for: inner), SyntaxRole.reference, "override")
            try Expect.equal(String(document.text(in: inner.range) ?? ""), "2582", "inner text")
        }

        Test("Unicode uses Character coordinates and existing LineTable") {
            let source = "entry\n👨‍👩‍👧‍👦"
            let language = try SyntaxLanguage<ECKind>(
                id: "ec",
                definitions: [.init(kind: .identifier, role: .identifier)]
            )
            let capture = SyntaxCapture(
                kind: ECKind.identifier,
                range: PositionRange(6..<7),
                layer: .lexical
            )
            let document = try SyntaxDocument(source: source, language: language, captures: [capture])
            let span = document.lineTable.displaySpan(for: capture.range)
            try Expect.equal(span.start.line, 2, "line")
            try Expect.equal(span.start.column, 1, "column")
            try Expect.equal(String(document.text(in: capture.range) ?? ""), "👨‍👩‍👧‍👦", "grapheme")
        }

        Test("duplicate kinds and undeclared captures fail on construction") {
            try Expect.throwsError("duplicate kind") {
                _ = try SyntaxLanguage<ECKind>(
                    id: "ec",
                    definitions: [
                        .init(kind: .entry, role: .declaration),
                        .init(kind: .entry, role: .keyword)
                    ]
                )
            }
            let language = try SyntaxLanguage<ECKind>(
                id: "ec",
                definitions: [.init(kind: .entry, role: .declaration)]
            )
            try Expect.throwsError("unknown kind") {
                _ = try SyntaxDocument(
                    source: "entry",
                    language: language,
                    captures: [
                        .init(kind: .undeclared, range: PositionRange(0..<5), layer: .lexical)
                    ]
                )
            }
            try Expect.throwsError("out of bounds") {
                _ = try SyntaxDocument(
                    source: "entry",
                    language: language,
                    captures: [
                        .init(kind: .entry, range: PositionRange(0..<6), layer: .lexical)
                    ]
                )
            }
        }

        Test("Primitives tree accepts syntax captures") {
            let capture = SyntaxCapture(
                kind: ECKind.entry,
                range: PositionRange(0..<5),
                layer: .syntactic
            )
            let tree = SyntaxTree<ECKind>(roots: [.init(capture)])
            try Expect.equal(tree.roots.count, 1, "tree root")
            try Expect.equal(tree.roots[0].value.kind, ECKind.entry, "typed kind")
        }
    }
}
