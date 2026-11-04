import Foundation
import Position
import Syntax
import Testing

enum SyntaxTestSuite {
    enum ECKind: String, SyntaxKind {
        case entry
        case identifier
        case embedded
    }

    enum OtherKind: String, SyntaxKind {
        case expression
    }

    struct AliasedKind: SyntaxKind {
        let rawValue: String
        let discriminator: Int

        init?(rawValue: String) {
            self.rawValue = rawValue
            self.discriminator = 0
        }

        init(_ rawValue: String, discriminator: Int) {
            self.rawValue = rawValue
            self.discriminator = discriminator
        }
    }

    enum FixtureError: Error {
        case unexpected_json_structure
    }

    static let suite = TestSuite("syntax", title: "Canonical syntax coordinates") {
        stylingSuite
        lspSuite
        Test("typed kinds are unique by canonical name") {
            do {
                _ = try SyntaxLanguage<AliasedKind>(
                    id: "ec",
                    definitions: [
                        .init(
                            kind: AliasedKind("entry", discriminator: 1),
                            role: .keyword
                        ),
                        .init(
                            kind: AliasedKind("entry", discriminator: 2),
                            role: .declaration
                        )
                    ]
                )
                try Expect.equal(true, false, "duplicate raw names must be rejected")
            } catch let error as SyntaxError {
                try Expect.equal(
                    error,
                    .duplicate_kind("entry"),
                    "canonical name determines kind identity"
                )
            }
        }

        Test("typed vocabularies and overlapping language roles remain intact") {
            let ec = try SyntaxLanguage<ECKind>(
                id: "ec",
                definitions: [
                    .init(kind: .entry, roles: [.declaration, .keyword]),
                    .init(kind: .identifier, role: .identifier)
                ]
            )
            let other = try SyntaxLanguage<OtherKind>(
                id: "other", definitions: [.init(kind: .expression, role: .number)]
            )
            let outer = try SyntaxCapture(
                language: "ec", kind: ECKind.entry,
                segments: [try SyntaxSourceRange(0..<8)], layer: .syntactic
            )
            let inner = try SyntaxCapture(
                language: "other", kind: OtherKind.expression,
                segments: [try SyntaxSourceRange(6..<8)], layer: .semantic,
                roles: [.reference]
            )
            let document = try SyntaxDocument(
                source: "entry 42", vocabularies: [ec.vocabulary(), other.vocabulary()],
                captures: [outer, inner]
            )
            try Expect.equal(document.roles(for: outer), [.declaration, .keyword], "default roles")
            try Expect.equal(document.roles(for: inner), [.number, .reference], "semantic roles")
            try Expect.equal(String(document.text(in: inner.segments[0]) ?? ""), "42", "source slice")
        }

        Test("UTF-8 offsets belong to Position and roundtrip across exact encodings") {
            let source = "e\u{301}\u{1F415}"
            let map = Position.TextMap(source: source)
            let insideGrapheme = try Position.Offset<Position.Unit.UTF8>(1)
            let scalar = try map.convert(insideGrapheme, to: Position.Unit.UTF32.self)
            try Expect.equal(scalar.offset, 1, "scalar boundary")
            try Expect.throwsError("grapheme interior cannot project to Character") {
                _ = try map.convert(insideGrapheme, to: Position.Unit.Character.self)
            }
            let eof = try map.convert(
                Position.Offset<Position.Unit.UTF8>(7),
                to: Position.Unit.UTF16.self
            )
            try Expect.equal(eof.offset, 4, "UTF-16 EOF")
            let range = try SyntaxSourceRange(
                start: Position.Offset<Position.Unit.UTF8>(0),
                end: Position.Offset<Position.Unit.UTF8>(3)
            )
            let utf16 = try map.convert(range.offsets, to: Position.Unit.UTF16.self)
            try Expect.equal(utf16.upperBound.offset, 2, "UTF-16 span")
        }

        Test("legacy Character bridge is exact and rejects partial graphemes") {
            let language = try SyntaxLanguage<ECKind>(
                id: "ec", definitions: [.init(kind: .identifier, role: .identifier)]
            )
            let source = "e\u{301}\u{1F415}"
            let capture = try SyntaxCapture(
                language: "ec", kind: ECKind.identifier,
                segments: [try SyntaxSourceRange(0..<3)], layer: .lexical
            )
            let document = try SyntaxDocument(
                source: source, vocabularies: [language.vocabulary()], captures: [capture]
            )
            try Expect.equal(try document.positionRange(for: capture.segments[0]), PositionRange(0..<1), "Character span")
            try Expect.equal(try document.sourceRange(for: PositionRange(0..<1)), capture.segments[0], "typed inverse")
            try Expect.throwsError("interior scalar is not a Character boundary") {
                _ = try document.positionRange(for: SyntaxSourceRange(1..<3))
            }
            try Expect.equal(String(document.text(in: SyntaxSourceRange(1..<3)) ?? ""), "\u{301}", "scalar slicing")
        }

        Test("CRLF bytes remain independently capturable without false logical coordinates") {
            let language = try SyntaxLanguage<ECKind>(
                id: "ec", definitions: [.init(kind: .embedded, role: .string)]
            )
            let capture = try SyntaxCapture(
                language: "ec", kind: ECKind.embedded,
                segments: [try SyntaxSourceRange(1..<2), try SyntaxSourceRange(2..<3)],
                layer: .lexical
            )
            let document = try SyntaxDocument(
                source: "a\r\nb", vocabularies: [language.vocabulary()], captures: [capture]
            )
            try Expect.equal(String(document.text(in: capture.segments[0]) ?? ""), "\r", "CR")
            try Expect.equal(String(document.text(in: capture.segments[1]) ?? ""), "\n", "LF")
            try Expect.throwsError("CRLF interior has no logical Character coordinate") {
                _ = try document.positionRange(for: capture.segments[0])
            }
        }

        Test("source document rejects mid-scalar and out-of-bounds capture ranges") {
            let language = try SyntaxLanguage<ECKind>(
                id: "ec", definitions: [.init(kind: .identifier, role: .identifier)]
            )
            let source = "\u{1F415}a"
            try Expect.throwsError("mid-scalar start") {
                let capture = try SyntaxCapture(
                    language: "ec", kind: ECKind.identifier,
                    segments: [try SyntaxSourceRange(1..<4)], layer: .lexical
                )
                _ = try SyntaxDocument(source: source, vocabularies: [language.vocabulary()], captures: [capture])
            }
            try Expect.throwsError("mid-scalar zero-width point") {
                let capture = try SyntaxCapture(
                    language: "ec", kind: ECKind.identifier,
                    segments: [try SyntaxSourceRange(2..<2)], layer: .syntactic
                )
                _ = try SyntaxDocument(source: source, vocabularies: [language.vocabulary()], captures: [capture])
            }
            try Expect.throwsError("out of source bounds") {
                let capture = try SyntaxCapture(
                    language: "ec", kind: ECKind.identifier,
                    segments: [try SyntaxSourceRange(0..<6)], layer: .lexical
                )
                _ = try SyntaxDocument(source: source, vocabularies: [language.vocabulary()], captures: [capture])
            }
        }

        Test("validated ranges retain legacy integer JSON encoding") {
            let typed = try SyntaxSourceRange(1..<3)
            let encoded = try JSONEncoder().encode(typed)
            let decoded = try JSONDecoder().decode(SyntaxSourceRange.self, from: encoded)
            try Expect.equal(decoded, typed, "round-trip")
            let object = try JSONSerialization.jsonObject(with: encoded) as? [String: Int]
            try Expect.equal(object?["start"], 1, "start remains numeric")
            try Expect.equal(object?["end"], 3, "end remains numeric")
            try Expect.throwsError("negative") { _ = try SyntaxSourceRange(start: -1, end: 0) }
            try Expect.throwsError("reversed") { _ = try SyntaxSourceRange(start: 4, end: 2) }
            try Expect.throwsError("corrupt decode") {
                _ = try JSONDecoder().decode(SyntaxSourceRange.self, from: Data("{\"start\":4,\"end\":2}".utf8))
            }
        }

        Test("malformed decoded document cannot bypass scalar-boundary checks") {
            let language = try SyntaxLanguage<ECKind>(
                id: "ec", definitions: [.init(kind: .identifier, role: .identifier)]
            )
            let capture = try SyntaxCapture(
                language: "ec", kind: ECKind.identifier,
                segments: [try SyntaxSourceRange(0..<4)], layer: .lexical
            )
            let document = try SyntaxDocument(
                source: "\u{1F415}a", vocabularies: [language.vocabulary()], captures: [capture]
            )
            let data = try JSONEncoder().encode(document)
            guard var object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  var captures = object["captures"] as? [[String: Any]],
                  var first = captures.first,
                  var segments = first["segments"] as? [[String: Any]],
                  var range = segments.first else {
                throw FixtureError.unexpected_json_structure
            }
            range["start"] = 1
            segments[0] = range
            first["segments"] = segments
            captures[0] = first
            object["captures"] = captures
            let malformed = try JSONSerialization.data(withJSONObject: object)
            try Expect.throwsError("decoded capture cannot bisect scalar") {
                _ = try JSONDecoder().decode(SyntaxDocument.self, from: malformed)
            }
        }

        Test("projection preserves CRLF, overlaps and unclassified gaps") {
            let vocabulary = try SyntaxLanguage<ECKind>(id: "ec", definitions: [
                .init(kind: .entry, role: .keyword),
                .init(kind: .identifier, role: .identifier)
            ])
            let broad = try SyntaxCapture(
                language: "ec", kind: ECKind.entry,
                segments: [try SyntaxSourceRange(0..<3)], layer: .lexical
            )
            let inner = try SyntaxCapture(
                language: "ec", kind: ECKind.identifier,
                segments: [try SyntaxSourceRange(1..<2), try SyntaxSourceRange(4..<4)],
                layer: .semantic
            )
            let document = try SyntaxDocument(
                source: "abc\r\nd", vocabularies: [vocabulary.vocabulary()],
                captures: [broad, inner]
            )
            let projection = try SyntaxProjection(document: document)
            try Expect.equal(projection.lines.count, 2, "two physical source lines")
            try Expect.equal(projection.lines[0].runs.map { $0.captures.count }, [1, 2, 1], "overlap retained")
            try Expect.equal(projection.lines[0].terminator.length, 2, "CRLF retained separately")
            try Expect.equal(projection.lines[1].runs[0].captures.count, 0, "unclassified content retained")
            try Expect.equal(projection.points.map(\.offset), [4], "zero-width point preserved")
            try Expect.equal(SyntaxSelector(role: .identifier).matches(inner, in: document), true, "role matches")
        }

        Test("zero-width, discontinuous and tree-backed captures remain supported") {
            let language = try SyntaxLanguage<ECKind>(
                id: "ec", definitions: [.init(kind: .embedded, role: .string)]
            )
            let capture = try SyntaxCapture(
                language: "ec", kind: ECKind.embedded,
                segments: [try SyntaxSourceRange(0..<0), try SyntaxSourceRange(1..<3)],
                layer: .syntactic,
                attributes: ["depth": .int(2)]
            )
            let document = try SyntaxDocument(
                source: "aBC", vocabularies: [language.vocabulary()], captures: [capture]
            )
            let tree = SyntaxTree(roots: [.init(capture)])
            try Expect.equal(tree.roots.count, 1, "tree root")
            try Expect.equal(String(document.text(in: capture.segments[1]) ?? ""), "BC", "second span")
            try Expect.equal(
                try JSONDecoder().decode(SyntaxDocument.self, from: JSONEncoder().encode(document)),
                document, "roundtrip"
            )
        }
    }
}
