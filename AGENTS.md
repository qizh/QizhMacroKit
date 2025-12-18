# AGENTS.md – QizhMacroKit

## Agent Personality

- 70% Professional
- 20% Sarcastic
- 10% Self-ironic
- 0% Forgetful & refusing

---

## Project Overview

QizhMacroKit is a Swift package providing a collection of Swift macros for enhanced enum handling, option sets, and code generation. It uses Swift Macros (introduced in Swift 5.9) powered by SwiftSyntax to generate compile-time code.

## Project Structure

```
QizhMacroKit/
├── Sources/
│   ├── QizhMacroKit/             # Public API – macro declarations
│   ├── QizhMacroKitMacros/       # Macro implementations (SwiftSyntax-based)
│   │   └── Helpers/              # Utility extensions for string manipulation
│   └── QizhMacroKitClient/       # Example client executable
├── Tests/
│   ├── CaseNameTests/
│   ├── CaseValueTests/
│   ├── DiagnosticTests/
│   ├── HelperTests/
│   ├── IsCaseTests/
│   ├── IsNotCaseTests/
│   ├── OptionSetTests/
│   └── StringifyTests/
├── Docs/                         # Per-macro documentation (.md files)
├── TestPlans/                    # Xcode test plans
├── Package.swift                 # Swift Package Manager manifest
├── README.md
├── TODO.md
├── KNOWN_ISSUES.md
└── .github/
    └── workflows/                # CI/CD workflows
```

## Key Technologies

- **Swift 6.2** with Swift 6 language mode
- **Swift Package Manager** for dependency management
- **SwiftSyntax 602.0.0+** for macro implementation
- **Swift Testing** framework for unit tests
- Supported platforms: iOS 17+, macOS 14+, Mac Catalyst 17+

## Available Macros

| Macro | Description |
|-------|-------------|
| `@CaseName` | Generates a `caseName` property returning the enum case name as a String |
| `@CaseValue` | Generates value extraction for enum cases with associated values |
| `@IsCase` | Generates boolean `is<CaseName>` properties for enum cases |
| `@IsNotCase` | Generates boolean `isNot<CaseName>` properties for enum cases |
| `@OptionSet<RawType>` | Creates an `OptionSet` from a struct containing a nested `Options` enum |
| `#stringify` | Converts expressions to their string representation |

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

---

## Coding Conventions

### General Style

- Use **tabs** for indentation
- Follow Swift API Design Guidelines
- Keep macro implementations focused and single-purpose
- Use descriptive variable names
- Include file headers with copyright info

### File Organization

- Each macro has a corresponding generator file in `Sources/QizhMacroKitMacros/`
- Public macro declarations go in `Sources/QizhMacroKit/`
- Helper utilities go in `Sources/QizhMacroKitMacros/Helpers/`
- Tests are organized by macro in `Tests/<MacroName>Tests/`
- Per-macro documentation in `Docs/<MacroName>.md`

### Macro Implementation Pattern

When implementing a new macro:

1. Create the public declaration in `Sources/QizhMacroKit/<MacroName>.swift`
2. Create the generator in `Sources/QizhMacroKitMacros/<MacroName>Generator.swift`
3. Register the generator in `_QizhMacroKitMacro.swift`
4. Add tests in `Tests/<MacroName>Tests/`
5. Add documentation in `Docs/<MacroName>.md`

### Error Handling

- Use `QizhMacroGeneratorDiagnostic` for macro-specific errors
- Provide clear, actionable error messages
- Validate input declarations before processing

### Testing

- Use Swift Testing framework (`@Test`, `@Suite`, `#expect`)
- Wrap tests in `#if os(macOS)` since macros require macOS
- Test both success cases and error conditions
- Use `SwiftSyntaxMacrosTestSupport` for macro expansion testing

---

## Agent Responsibilities

### Code Generation

- Generate Swift 6.2+ code upon request
- Generate SwiftUI code upon request
- Review code written by others
- Find & fix potential bugs & issues
- Suggest improvements

### Dependency Management

- Check dependency versions and update them if needed

**IMPORTANT:**
- Never update a dependency to a version which introduces breaking changes for entities used in this repository without getting explicit confirmation
  - Instead: Update to the latest dependency version with no breaking changes
- If you can auto-update the code to adopt a dependency's breaking change – ask the author for confirmation first
  - Otherwise: Create a corresponding Issue for the dependency update adoption when possible and mention it in your report

### Documentation

For all added or updated code entities:
- Generate or update documentation following DocC best practices
- Generate or update tests

For each major repository component:
- Generate or update `Docs/<ComponentName>.md` documentation files following GitHub documentation best practices
- Update the main `README.md` file
  - Add or update references to all component documentation files

### Before Finishing

- Build all targets with Swift 6.2+ compiler to ensure no errors
- Run all tests to ensure none fail
- Generate and post a report
- Update the PR description with the results

### Auto-Commit Policy

Automatically commit changes (with a generated commit title and description) when **ALL** of the following conditions are met:

1. **Task successfully finished** — The requested work is complete
2. **Code is documented** — All added/updated code has proper documentation
3. **Code is tested** — All added/updated code is covered by tests
4. **Tests pass** — All tests run successfully (`swift test` exits with code 0)
5. **Documentation updated** — Relevant `.md` files are updated (README, Docs/, KNOWN_ISSUES, etc.)

Commit message format:
```
<concise title summarizing the change>

<detailed description of what was changed and why>

## Changes
- List of specific changes made

## Testing
- Summary of test results
```

---

## Dependencies

- **swift-syntax** (602.0.0+): Required for macro implementation
  - SwiftSyntax
  - SwiftSyntaxMacros
  - SwiftCompilerPlugin
  - SwiftSyntaxBuilder
  - SwiftDiagnostics
  - SwiftSyntaxMacrosTestSupport (for tests)

## CI/CD

The repository uses GitHub Actions for continuous integration:
- Builds run on `macos-latest`
- Uses Swift 6.2 toolchain
- Runs on push to `main` and pull requests targeting `main`
