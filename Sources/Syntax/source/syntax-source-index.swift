import Position

/// Compatibility alias. Position.TextMap owns all source-coordinate conversion.
@available(*, deprecated, message: "Use Position.TextMap or SyntaxDocument.textMap.")
public typealias SyntaxSourceIndex = Position.TextMap
