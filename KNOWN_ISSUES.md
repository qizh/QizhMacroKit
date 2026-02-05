# Known Issues

> Last Updated: January 14, 2026

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

### Test Coverage Limitations

#### Untestable Code Paths

**Status**: By Design  
**Affected**: `_QizhMacroKitMacro.swift`

The macro plugin entry point (`_QizhMacroKitMacro.swift`) registers macros with the Swift compiler via the `CompilerPlugin` protocol. This code:

- Is invoked by the Swift compiler during compilation, not at runtime
- Cannot be directly tested via unit tests
- Appears as 0% coverage in code coverage reports

This is expected behavior for Swift macro plugins. The actual macro implementations (generators) are fully testable and covered.

---

## Resolved Issues

### @_exported Imports in Macro Target (PR #46)

**Status**: Fixed (February 6, 2025)  
**Affected**: All macros when used as dependency in Xcode 26.3 RC  
**Resolution**: Removed `@_exported` from macro implementation imports

Macro implementation files incorrectly used `@_exported` to re-export SwiftSyntax modules (SwiftCompilerPlugin, SwiftSyntax, SwiftSyntaxMacros, etc.). This caused consuming projects to fail with:

```
error: No such module 'SwiftCompilerPlugin'
```

**Root Cause**: `.macro` targets are compiler plugins that execute at build time, not library code. Their dependencies are internal implementation details and should never leak to consuming projects via `@_exported`.

**Fix**: Removed `@_exported` from all macro implementation imports and added proper `import` statements to each generator file as needed.

---

### @OptionSet Mixed Case Bit Collisions (PR #45)

**Status**: Fixed (January 13, 2026)  
**Affected**: `@OptionSet` macro  
**Resolution**: Commit `776085c`

When an `Options` enum contained both simple cases and cases with associated values, the generated code would produce bit collisions. Swift prohibits raw types on enums with associated values, so `.rawValue` cannot be used on simple cases when any case has associated values.

**Fix**: The macro now detects if ANY case has associated values and uses manual bit indexing (`1 << index`) for ALL cases in that scenario.

---

### Unused Diagnostic Cases (PR #45)

**Status**: Fixed (January 13, 2026)  
**Affected**: `OptionSetMacroDiagnostic`  
**Resolution**: Removed dead code

The diagnostic cases `associatedEnumNotFound` and `associatedEnumMissingCases` were declared but never emitted. Since the silent fallback to simple generation is intentional behavior (for external types), the unused diagnostics were removed.

---

## External Issues

### Xcode "No such module 'SwiftCompilerPlugin'" Error

**Status**: Xcode Bug  
**Affected**: Projects depending on QizhMacroKit when building for iOS  
**Reported**: January 14, 2026  
**Xcode Versions**: 26.x RC (and earlier versions)

When building a project that depends on QizhMacroKit for an iOS destination, Xcode may incorrectly attempt to compile the macro target (`QizhMacroKitMacros`) for the destination platform instead of the host platform (macOS).

**Symptoms**:

- `No such module 'SwiftCompilerPlugin'` error in `_QizhMacroKitMacro.swift`
- Error only appears when building for iOS/tvOS/watchOS destinations
- `swift build` from terminal works correctly

**Root Cause**: Xcode uses prebuilt swift-syntax modules that may be compiled with a different Swift compiler version than the one bundled with your Xcode. When there's a version mismatch, the modules become incompatible, causing cascading import failures for `SwiftSyntax`, `SwiftDiagnostics`, `SwiftSyntaxMacros`, `SwiftSyntaxBuilder`, and `SwiftCompilerPlugin`.

**Build Log Indicators**:

```text
warning: Module file '...SwiftSyntax.swiftmodule...' is incompatible with this Swift compiler: compiled with a different version of the compiler
```

**Workarounds** (in order of effectiveness):

1. **Reset Package Caches**:
   - `File → Packages → Reset Package Caches`
   - Clean build folder: `Cmd+Shift+K`

2. **Delete DerivedData**:

   ```zsh
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

3. **Trust Macros**: Check the Issue Navigator for "Trust & Enable" prompts

4. **Restart Xcode** after resetting caches

5. **Build for Mac first**, then switch to iOS destination

#### If "Trust & Enable" Prompt Doesn't Appear

If the standard workarounds don't help and the macro trust prompt never appears:

1. **Force trust all macros** (temporary, has security implications):

   ```zsh
   defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
   ```

   Then restart Xcode. To revert:

   ```zsh
   defaults delete com.apple.dt.Xcode IDESkipMacroFingerprintValidation
   ```

2. **Reset macro trust preferences** to force the prompt to reappear:

   ```zsh
   rm -rf ~/Library/Developer/Xcode/UserData/IDEFingerprintStore/
   ```

   Then restart Xcode.

3. **Build via xcodebuild** with the skip validation flag:

   ```zsh
   xcodebuild -skipMacroValidation -scheme YourScheme -destination 'platform=iOS Simulator,name=iPhone 16'
   ```

**Note**: This is NOT a bug in QizhMacroKit. The package configuration is correct — `swift build` works perfectly.

---

### Codex Code Review GitHub Integration

**Status**: OpenAI Backend Issue  
**Reported**: January 13, 2026

The Codex Code Review feature may fail to connect to GitHub repositories even when:

- GitHub App is properly installed
- Repository is in the authorized list
- All permissions are granted

**Symptoms**:

- "Action required: Update your GitHub permissions" banner persists
- "Update" button doesn't resolve the issue
- Stale/phantom repositories appear in settings that cannot be removed

**Workaround**: Contact OpenAI support. This is a backend OAuth token validation issue.

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
