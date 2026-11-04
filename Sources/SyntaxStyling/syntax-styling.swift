import Syntax

public struct SyntaxColor: Sendable, Equatable, Hashable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

/// Optional fields allow a rule to override only the attributes it specifies.
public struct SyntaxStyle: Sendable, Equatable {
    public var foreground: SyntaxColor?
    public var background: SyntaxColor?
    public var bold: Bool?
    public var italic: Bool?
    public var underline: Bool?

    public init(
        foreground: SyntaxColor? = nil,
        background: SyntaxColor? = nil,
        bold: Bool? = nil,
        italic: Bool? = nil,
        underline: Bool? = nil
    ) {
        self.foreground = foreground
        self.background = background
        self.bold = bold
        self.italic = italic
        self.underline = underline
    }

    public func applying(_ override: Self) -> Self {
        Self(
            foreground: override.foreground ?? foreground,
            background: override.background ?? background,
            bold: override.bold ?? bold,
            italic: override.italic ?? italic,
            underline: override.underline ?? underline
        )
    }
}

public struct SyntaxStyleRule: Sendable {
    public let selector: SyntaxSelector
    public let style: SyntaxStyle
    public let priority: Int

    public init(selector: SyntaxSelector, style: SyntaxStyle, priority: Int = 0) {
        self.selector = selector
        self.style = style
        self.priority = priority
    }
}

public struct SyntaxTheme: Sendable {
    public let name: String
    public let base: SyntaxStyle
    public let rules: [SyntaxStyleRule]

    public init(name: String, base: SyntaxStyle = .init(), rules: [SyntaxStyleRule] = []) {
        self.name = name
        self.base = base
        self.rules = rules
    }

    /// Later rules of equal priority/specificity win; custom overrides can
    /// also use higher priorities without discarding other style fields.
    public func adding(_ overrides: [SyntaxStyleRule]) -> Self {
        Self(name: name, base: base, rules: rules + overrides)
    }

    public static let plain = Self(name: "plain")

    public static let dark = Self(name: "dark", rules: [
        .init(selector: .init(role: .keyword), style: .init(
            foreground: .init(red: 190, green: 145, blue: 255), bold: true)),
        .init(selector: .init(role: .string), style: .init(
            foreground: .init(red: 145, green: 220, blue: 150))),
        .init(selector: .init(role: .number), style: .init(
            foreground: .init(red: 240, green: 190, blue: 120))),
        .init(selector: .init(role: .comment), style: .init(
            foreground: .init(red: 125, green: 135, blue: 145), italic: true)),
        .init(selector: .init(role: .invalid), style: .init(
            foreground: .init(red: 255, green: 105, blue: 105)))
    ])

    public static let light = Self(name: "light", rules: [
        .init(selector: .init(role: .keyword), style: .init(
            foreground: .init(red: 110, green: 60, blue: 170), bold: true)),
        .init(selector: .init(role: .string), style: .init(
            foreground: .init(red: 30, green: 120, blue: 55))),
        .init(selector: .init(role: .number), style: .init(
            foreground: .init(red: 160, green: 85, blue: 25))),
        .init(selector: .init(role: .comment), style: .init(
            foreground: .init(red: 110, green: 120, blue: 125), italic: true)),
        .init(selector: .init(role: .invalid), style: .init(
            foreground: .init(red: 190, green: 35, blue: 35)))
    ])
}

public struct StyledSyntaxRun: Sendable {
    public let source: SyntaxRun
    public let style: SyntaxStyle
}

public struct StyledSyntaxLine: Sendable {
    public let source: SyntaxLine
    public let runs: [StyledSyntaxRun]
}

/// Resolves presentation-neutral styles; no terminal, HTML or AppKit coupling.
public enum SyntaxStyling {
    public static func project(
        document: SyntaxDocument,
        theme: SyntaxTheme
    ) throws -> [StyledSyntaxLine] {
        let projection = try SyntaxProjection(document: document)
        return projection.lines.map { line in
            StyledSyntaxLine(source: line, runs: line.runs.map { run in
                let matches = theme.rules.enumerated().filter { _, rule in
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
                let resolved = matches.reduce(theme.base) { current, match in
                    current.applying(match.element.style)
                }
                return StyledSyntaxRun(source: run, style: resolved)
            })
        }
    }
}
