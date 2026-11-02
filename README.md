# Syntax

A presentation-neutral, typed foundation for describing language constructs and source classifications.

`Syntax` does not lex, parse, bind names, emit ANSI, or generate Tree-sitter grammars. Language implementations supply positioned captures from their existing parsers. Consumers project those captures to terminal styles, LSP semantic tokens, macOS attributed text, or editor queries.

## Dependencies

- `Position`: canonical half-open `PositionRange` using Swift `Character` offsets and `LineTable` for source positions.
- `Primitives`: `Tree` reused through `SyntaxTree` instead of introducing another hierarchy type.
- `Testing`: lightweight `t_syntax` TestFlows executable.

## Core model

- `SyntaxKind`: language-specific typed enum conformance.
- `SyntaxDefinition`: declared construct and default role.
- `SyntaxLanguage`: validated language identity and definitions.
- `SyntaxCapture`: positioned classification with lexical, syntactic, or semantic layer; optional role override and modifiers.
- `SyntaxDocument`: source and captures; rejects undeclared kinds and out-of-bounds ranges on construction and decoding.
- `SyntaxTree`: `Primitives.Tree<SyntaxCapture<Kind>>`.

Captures may overlap. Layer precedence remains presentation policy. Source text is preserved unmodified, with captures referring to ranges rather than copied or normalized tokens.

## Next passes

1. Adapt Accounting's EC highlighter and LSP semantic tokens to shared classifications without changing compiler semantics.
2. Add a separate terminal syntax-to-style adapter, with themes outside this package.
3. Audit existing `Parsing.StructuredParser.Grammar` and `GrammarNode` before introducing portable grammar declarations. Do not duplicate the parser framework.
4. Add optional Tree-sitter query generation from compatible metadata.
5. Harden Markdown parsing separately and reuse Syntax classifications for fenced code.

Run `swift run t_syntax` to execute the targeted TestFlows.
