import Primitives

/// Optional hierarchical view of canonical captures.
/// Overlapping and discontiguous classifications need not form a tree.
public typealias SyntaxTree = Tree<SyntaxCapture>
