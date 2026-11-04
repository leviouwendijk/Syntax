/// Presentation-neutral source diagnostic, using canonical UTF-8 coordinates.
public struct SyntaxDiagnostic: Sendable, Hashable {
    public enum Severity: String, Sendable, Hashable {
        case error
        case warning
        case information
        case hint
    }

    public let message: String
    public let severity: Severity
    public let range: SyntaxSourceRange
    public let code: String?

    public init(
        message: String,
        severity: Severity = .error,
        range: SyntaxSourceRange,
        code: String? = nil
    ) {
        self.message = message
        self.severity = severity
        self.range = range
        self.code = code
    }
}
