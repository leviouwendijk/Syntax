import Syntax
import SyntaxStyling
import Testing

extension SyntaxTestSuite {
    static var stylingSuite: TestSuite {
        TestSuite("syntax-styling") {
            Test("preset theme supports specific property-preserving overrides") {
                let lang = try SyntaxLanguage<ECKind>(
                    id: "ec", definitions: [.init(kind: .entry, role: .keyword)]
                )
                let capture = try SyntaxCapture(
                    language: "ec", kind: ECKind.entry,
                    segments: [try SyntaxSourceRange(0..<3)], layer: .lexical
                )
                let document = try SyntaxDocument(
                    source: "key", vocabularies: [lang.vocabulary()], captures: [capture]
                )
                let custom = SyntaxTheme.dark.adding([
                    .init(selector: .init(language: "ec", kind: "entry"),
                          style: .init(underline: true), priority: 10)
                ])
                let runs = try SyntaxStyling.project(document: document, theme: custom)
                try Expect.equal(runs[0].runs[0].style.bold, true, "preset bold retained")
                try Expect.equal(runs[0].runs[0].style.underline, true, "override underline applied")
                try Expect.equal(runs[0].runs[0].style.foreground,
                                 SyntaxColor(red: 190, green: 145, blue: 255), "preset color retained")
            }
            Test("plain theme contains no implicit color or ANSI") {
                let document = try SyntaxDocument(source: "plain", vocabularies: [], captures: [])
                let runs = try SyntaxStyling.project(document: document, theme: .plain)
                try Expect.equal(runs[0].runs[0].style, SyntaxStyle(), "plain style")
            }
        }
    }
}
