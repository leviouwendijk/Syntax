import Syntax
import SyntaxLSP
import Testing

extension SyntaxTestSuite {
    static var lspSuite: TestSuite {
        TestSuite("syntax-lsp") {
            Test("UTF-16 semantic ranges split around CRLF with exact emoji lengths") {
                let language = try SyntaxLanguage<ECKind>(id: "ec", definitions: [
                    .init(kind: .entry, role: .string),
                    .init(kind: .identifier, role: .identifier)
                ])
                let first = try SyntaxCapture(
                    language: "ec", kind: ECKind.entry,
                    segments: [try SyntaxSourceRange(0..<6)], layer: .lexical
                )
                let second = try SyntaxCapture(
                    language: "ec", kind: ECKind.identifier,
                    segments: [try SyntaxSourceRange(7..<12)], layer: .lexical
                )
                let third = try SyntaxCapture(
                    language: "ec", kind: ECKind.entry,
                    segments: [try SyntaxSourceRange(14..<16)], layer: .lexical
                )
                let doc = try SyntaxDocument(
                    source: "\"🙂\" café\r\n42", vocabularies: [language.vocabulary()],
                    captures: [first, second, third]
                )
                let legend = try SyntaxLSP.Legend(types: ["string", "variable"])
                let tokens = try SyntaxLSP.project(document: doc, legend: legend, rules: [
                    .init(selector: .init(role: .string), type: "string"),
                    .init(selector: .init(role: .identifier), type: "variable")
                ])
                try Expect.equal(SyntaxLSP.encode(tokens), [
                    0, 0, 4, 0, 0,
                    0, 5, 4, 1, 0,
                    1, 0, 2, 0, 0
                ], "UTF-16 lengths and per-line delta positions")
            }
            Test("unknown semantic legend types are rejected") {
                let lang = try SyntaxLanguage<ECKind>(id: "ec", definitions: [
                    .init(kind: .entry, role: .keyword)
                ])
                let capture = try SyntaxCapture(
                    language: "ec", kind: ECKind.entry,
                    segments: [try SyntaxSourceRange(0..<3)], layer: .lexical
                )
                let doc = try SyntaxDocument(
                    source: "key", vocabularies: [lang.vocabulary()], captures: [capture]
                )
                try Expect.throwsError("unknown semantic token type") {
                    _ = try SyntaxLSP.project(document: doc,
                        legend: SyntaxLSP.Legend(types: ["variable"]),
                        rules: [.init(selector: .init(role: .keyword), type: "keyword")])
                }
            }
        }
    }
}
