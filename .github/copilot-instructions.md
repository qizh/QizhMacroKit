# Copilot Instructions for QizhMacroKit

## Project Overview

QizhMacroKit is a Swift package that provides a collection of Swift macros for enhanced enum handling and code generation. It uses Swift Macros (introduced in Swift 5.9) powered by SwiftSyntax to generate compile-time code.

## Project Structure

```
QizhMacroKit/
├── Sources/
│   ├── QizhMacroKit/           # Public API - macro declarations
│   ├── QizhMacroKitMacros/     # Macro implementations (SwiftSyntax-based)
│   │   └── Helpers/            # Utility extensions for string manipulation
│   └── QizhMacroKitClient/     # Example client executable
├── Tests/                      # Test suites for each macro
├── Package.swift               # Swift Package Manager manifest
└── .github/
    └── workflows/              # CI/CD workflows
```

## Key Technologies

- **Swift 6.2** with Swift 6 language mode
- **Swift Package Manager** for dependency management
- **SwiftSyntax 602.0.0+** for macro implementation
- **Swift Testing** framework for unit tests
- Supported platforms: iOS 17+, macOS 14+, Mac Catalyst 14+

## Available Macros

- `@CaseName` - Generates a `caseName` property returning the enum case name as a String
- `@CaseValue` - Generates value extraction for enum cases
- `@IsCases` - Generates boolean `is<CaseName>` properties for enum cases
- `@IsNotCases` - Generates boolean `isNot<CaseName>` properties for enum cases
- `#stringify` - Converts expressions to their string representation
- `#dictionarify` - Returns a dictionary element containing the value and its source text as a key-value pair

## Build and Test Commands

```bash
# Build the package
swift build

# Build in debug configuration
swift build --configuration debug

# Run all tests
swift test

# Run tests in parallel with verbose output
swift test --parallel --verbose
```

## Coding Conventions

### General Style

- Use tabs for indentation
- Follow Swift API Design Guidelines
- Keep macro implementations focused and single-purpose
- Use descriptive variable names

### File Organization

- Each macro has a corresponding generator file in `Sources/QizhMacroKitMacros/`
- Public macro declarations go in `Sources/QizhMacroKit/`
- Helper utilities go in `Sources/QizhMacroKitMacros/Helpers/`
- Tests are organized by macro in `Tests/<MacroName>Tests/`

### Macro Implementation Pattern

When implementing a new macro:

1. Create the public declaration in `Sources/QizhMacroKit/<MacroName>.swift`
2. Create the generator in `Sources/QizhMacroKitMacros/<MacroName>Generator.swift`
3. Register the generator in `_QizhMacroKitMacro.swift`
4. Add tests in `Tests/<MacroName>Tests/`

### Error Handling

- Use `QizhMacroGeneratorDiagnostic` for macro-specific errors
- Provide clear, actionable error messages
- Validate input declarations before processing

### Testing

- Use Swift Testing framework (`@Test`, `@Suite`, `#expect`)
- Wrap tests in `#if os(macOS)` since macros require macOS
- Test both success cases and error conditions
- Use `SwiftSyntaxMacrosTestSupport` for macro expansion testing

## Dependencies

- **swift-syntax** (602.0.0+): Required for macro implementation
  - SwiftSyntax
  - SwiftSyntaxMacros
  - SwiftCompilerPlugin
  - SwiftSyntaxBuilder
  - SwiftDiagnostics

## CI/CD

The repository uses GitHub Actions for continuous integration:
- Builds run on `macos-latest`
- Uses Swift 6.2 toolchain
- Runs on push to `main` and pull requests targeting `main`
