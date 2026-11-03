# Syntax

Canonical, presentation-neutral syntax identities and classified source spans.

## Source ownership

- `Position.Offset<Position.Unit.UTF8>` owns absolute UTF-8 offsets. `SyntaxSourceRange` is a half-open typed range and retains numeric `start`/`end` JSON fields.
- `Position.TextMap` owns exact UTF-8, UTF-16, UTF-32, Character and line/column conversion. `Syntax` does not maintain a second conversion table.
- `SyntaxDocument` checks that capture boundaries exist at Unicode-scalar boundaries in its immutable `String` snapshot. Both `\r` and `\n` in CRLF are independently capturable.
- `Position.TextMap` may reject projection inside CRLF, grapheme clusters, or other unsupported logical boundaries; callers must never round or coerce a failed conversion.
- A validated textual capture is not a general-purpose raw byte span. Invalid UTF-8 file bytes require a separate raw-source model.

## Classification ownership

`SyntaxLanguage` declares typed language constructs; `SyntaxVocabulary` provides runtime language identity. `SyntaxCapture` supports overlapping and discontiguous classifications, zero-width points, layers, roles, modifiers and structured `Primitives.JSONValue` metadata. `Primitives.Tree` remains optional.

## Boundaries

`Syntax` neither lexes nor parses. `Parsing`/language packages recognize source, while terminal, LSP and macOS adapters project classifications. EC should use its lexer's actual token spans rather than including skipped trivia in highlighted ranges. Preserve lexical comments, multiline spans and Unicode fidelity.

Run `swift run t_syntax` and a debug build before EC integration. `Position` retains its own targeted `t_position` tests; this package verifies the bridge without modifying the dependency.
