# String Helper Utilities

> Last Updated: November 25, 2025

Internal string manipulation utilities used by QizhMacroKit macro generators.

## Overview

QizhMacroKit includes several internal string extensions that power the macro generators. While these are not part of the public API, understanding them can help when debugging generated code or contributing to the project.

## Utilities

### String Case Conversion

> Source: `String+wordsArray.swift`  
> Last Updated: November 25, 2025

Converts strings between different naming conventions:

| Property/Method | Description | Example |
|-----------------|-------------|---------|
| `toCamelCase` | Converts to camelCase | `"some_text"` → `"someText"` |
| `toPascalCase` | Converts to PascalCase | `"some_text"` → `"SomeText"` |
| `toSnakeCase` | Converts to snake_case | `"someText"` → `"some_text"` |
| `toKebabCase` | Converts to kebab-case | `"someText"` → `"some-text"` |
| `toDotCase` | Converts to dot.case | `"someText"` → `"some.text"` |
| `toWordsArray()` | Splits into lowercase words | `"someText"` → `["some", "text"]` |

These conversions use Unicode-aware word boundary detection, supporting:

- camelCase boundaries
- Acronyms (e.g., `"HTMLParser"` → `["html", "parser"]`)
- Numbers (e.g., `"value123"` → `["value", "123"]`)
- International characters

---

### Swift Keyword Escaping

> Source: `String+swiftKeywordEscaping.swift`  
> Last Updated: November 25, 2025

Handles Swift reserved keywords in generated identifiers:

```swift
// Internal property
var escapedSwiftIdentifier: String
```

Reserved keywords are automatically wrapped in backticks:

| Input | Output |
|-------|--------|
| `"class"` | `` `class` `` |
| `"import"` | `` `import` `` |
| `"default"` | `` `default` `` |
| `"myVariable"` | `"myVariable"` |

#### Supported Keywords

The following Swift keywords are recognized:

- **Declarations**: `class`, `struct`, `enum`, `protocol`, `func`, `var`, `let`, `typealias`, `import`, `init`, `deinit`, `extension`, `subscript`, `operator`, `macro`, `actor`
- **Modifiers**: `public`, `private`, `internal`, `fileprivate`, `open`, `static`, `final`, `inout`
- **Statements**: `if`, `else`, `for`, `while`, `do`, `switch`, `case`, `default`, `break`, `continue`, `return`, `throw`, `throws`, `rethrows`, `try`, `catch`, `defer`, `guard`, `repeat`, `where`, `fallthrough`
- **Expressions**: `as`, `is`, `in`, `self`, `Self`, `super`, `any`, `some`
- **Concurrency**: `async`, `await`

---

### Backtick Trimming

> Source: `String+trimmingBackticks.swift`  
> Last Updated: November 25, 2025

Removes backticks from escaped identifiers:

```swift
// Internal property
var withBackticksTrimmed: String
```

| Input | Output |
|-------|--------|
| `` `default` `` | `"default"` |
| `` `class` `` | `"class"` |
| `"normal"` | `"normal"` |

This is used when extracting case names from enum declarations where the syntax tree preserves the backticks.

## Usage in Macros

### CaseName Macro

The `@CaseName` macro uses `withBackticksTrimmed` to get clean case names:

```swift
// Input
case `default`

// Generated output
case .default: "default"  // Not "`default`"
```

### CaseValue Macro

The `@CaseValue` macro uses `toCamelCase` for property naming:

```swift
// Input
case submit(request_data: Data)

// Generated property name
var submitRequestData: Data?  // camelCase combination
```

### IsCase Macro

The `@IsCase` macro uses `escapedSwiftIdentifier` for the `Cases` enum:

```swift
// Input
case `class`

// Generated Cases enum
enum Cases {
    case `class`  // Properly escaped
}
```

## Contributing

When adding new macro generators or modifying existing ones:

1. Use `withBackticksTrimmed` when extracting identifiers from syntax nodes
2. Use `escapedSwiftIdentifier` when generating identifiers that might be keywords
3. Use case conversion methods for consistent naming conventions

## See Also

- [CaseName](CaseName.md) — Uses backtick trimming for clean output
- [CaseValue](CaseValue.md) — Uses camelCase conversion for property names
- [IsCase](IsCase.md) — Uses keyword escaping for `Cases` enum
