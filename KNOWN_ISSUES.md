# Known Issues

> Last Updated: November 27, 2025

This document lists known limitations and issues in QizhMacroKit.

## Current Limitations

### Platform-Specific Constraints

#### macOS-Only Macro Execution

**Status**: By Design  
**Affected**: All macros  
**Since**: v1.0.0

Swift macros require the macro compiler plugin to run on the host machine during compilation. This means:

- Macros can only be **expanded** on macOS (where Xcode runs)
- The compiled code **works** on all supported platforms (iOS, macOS, Mac Catalyst)
- Tests using `SwiftSyntaxMacrosTestSupport` are wrapped in `#if os(macOS)`

---

### Enum Requirements

#### Empty Enums

**Status**: By Design  
**Affected**: `@CaseName`, `@IsCase`

Applying `@CaseName` to an empty enum produces an error:

```swift
@CaseName
enum Empty { }
// Error: @CaseName can only be applied to enums with cases
```

Applying `@IsCase` to an empty enum produces a warning and generates no members:

```swift
@IsCase
enum Empty { }
// Warning: There are no cases in the enum, so `@IsCase` can NOT be applied.
```

---

### Property Name Collisions

#### Generated Properties May Conflict

**Status**: Known Issue  
**Affected**: `@CaseValue`, `@IsCase`, `@IsNotCase`

In rare cases, generated property names may conflict with existing properties or each other:

```swift
@CaseValue
enum Example {
    case data(_ data: Data)
    case dataBackup(_ data: Data)  // Both generate "data" property
}
// Potential conflict: both cases may generate similar property names
```

**Workaround**: Use distinct parameter names or manually implement conflicting accessors.

---

### Swift Keyword Limitations

#### Incomplete Keyword List

**Status**: Known Issue  
**Affected**: All enum macros  
**Since**: v1.1.0

The `escapedSwiftIdentifier` helper recognizes most common Swift keywords, but may miss:

- Newly introduced keywords in future Swift versions
- Context-dependent keywords
- Attributes that can be used as identifiers

**Workaround**: When using case names that cause issues, explicitly escape them with backticks in your source code.

---

### Build Environment

#### SwiftUI Client Example

**Status**: Environment Limitation  
**Affected**: `QizhMacroKitClient` target

The client example target includes SwiftUI imports that fail to build on non-Apple platforms (Linux CI environments):

```swift
// Sources/QizhMacroKitClient/IsCase.swift
import SwiftUI  // Fails on Linux
```

This doesn't affect the library functionality—only the example client.

**Workaround**: Build only the `QizhMacroKit` target on non-macOS platforms:

```bash
swift build --target QizhMacroKit
```

---

## Reporting Issues

Found a bug or have a feature request? Please [open an issue](https://github.com/qizh/QizhMacroKit/issues/new) with:

1. A minimal reproducible example
2. Expected vs. actual behavior
3. Swift version and platform information
4. Any relevant error messages

## See Also

- [TODO](TODO.md) — Planned features and improvements
- [README](../README.md) — Project overview and installation
