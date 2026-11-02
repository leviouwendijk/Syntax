import Primitives

/// Reuse the existing Primitives tree for hierarchical syntax views.
/// Captures remain reusable in flat and hierarchical projections.
public typealias SyntaxTree<Kind: SyntaxKind> = Tree<SyntaxCapture<Kind>>
