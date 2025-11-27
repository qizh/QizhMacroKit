# QizhMacroKit

A Swift package providing a collection of powerful macros for enhanced enum handling and code generation.

[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20|%20macOS%2014%20|%20Mac%20Catalyst%2014-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Overview

QizhMacroKit uses Swift Macros (introduced in Swift 5.9) to generate compile-time code, reducing boilerplate and enhancing enum ergonomics. All macros are powered by SwiftSyntax and execute during compilation with zero runtime overhead.

## Features

| Macro | Type | Description |
|-------|------|-------------|
| [`@CaseName`](Docs/CaseName.md) | Attached | Generates a `caseName` property returning the case name as a String |
| [`@CaseValue`](Docs/CaseValue.md) | Attached | Generates properties to extract associated values from cases |
| [`@IsCase`](Docs/IsCase.md) | Attached | Generates `is<CaseName>` boolean properties and membership checking |
| [`@IsNotCase`](Docs/IsNotCase.md) | Attached | Generates `isNot<CaseName>` boolean properties |
| [`#stringify`](Docs/Stringify.md) | Freestanding | Converts an expression to its source text |
| [`#dictionarify`](Docs/Stringify.md) | Freestanding | Returns a key-value pair with source text and evaluated value |

## Requirements

- **Swift**: 6.2+
- **Platforms**: iOS 17+, macOS 14+, Mac Catalyst 14+
- **Dependencies**: [swift-syntax](https://github.com/swiftlang/swift-syntax) 602.0.0+

## Installation

### Swift Package Manager

Add QizhMacroKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/qizh/QizhMacroKit.git", from: "1.1.0")
]
```

Then add the dependency to your target:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["QizhMacroKit"]
    )
]
```

### Xcode Project

1. File → Add Package Dependencies...
2. Enter: `https://github.com/qizh/QizhMacroKit.git`
3. Select version requirements
4. Add to your target

## Quick Start

### Import the Package

```swift
import QizhMacroKit
```

### @CaseName — Get Case Names as Strings

```swift
@CaseName
enum Status {
    case idle
    case loading
    case success(Data)
    case failure(Error)
}

let status = Status.loading
print(status.caseName)  // "loading"
```

### @IsCase — Boolean Case Checking

```swift
@IsCase
enum NetworkState {
    case disconnected
    case connecting
    case connected(session: Session)
}

let state = NetworkState.connecting

// Boolean properties
if state.isConnecting {
    showLoadingIndicator()
}

// Membership checking
if state.isAmong(.disconnected, .connecting) {
    retryConnection()
}
```

### @IsNotCase — Negated Case Checking

```swift
@IsNotCase
enum Permission {
    case granted
    case denied
    case notDetermined
}

let permission = Permission.notDetermined

if permission.isNotGranted {
    requestPermission()
}
```

### @CaseValue — Extract Associated Values

```swift
@CaseValue
enum Result {
    case success(data: Data)
    case failure(error: Error)
}

let result = Result.success(data: responseData)

// Optional extraction
if let data = result.successData {
    process(data)
}
```

### #stringify — Expression to String

```swift
let x = 42
let text = #stringify(x * 2 + 1)
print(text)  // "x * 2 + 1"
```

### #dictionarify — Expression with Value

```swift
let pair = #dictionarify(2 + 2)
print(pair.key)    // "2 + 2"
print(pair.value)  // 4
```

## Documentation

Detailed documentation for each component:

### Macros (sorted by date updated)

1. [Stringify Macros](Docs/Stringify.md) — `#stringify` and `#dictionarify` (August 2025)
2. [CaseValue](Docs/CaseValue.md) — Associated value extraction (May 2025)
3. [IsNotCase](Docs/IsNotCase.md) — Negated case checking (February 2025)
4. [CaseName](Docs/CaseName.md) — Case name as string (October 2024)
5. [IsCase](Docs/IsCase.md) — Boolean case checking (October 2024)

### Internal Utilities

- [String Helpers](Docs/Helpers.md) — Case conversion, keyword escaping, backtick handling

### Project Status

- [Known Issues](KNOWN_ISSUES.md) — Current limitations and workarounds
- [TODO / Roadmap](TODO.md) — Planned features and improvements

## Project Structure

```
QizhMacroKit/
├── Sources/
│   ├── QizhMacroKit/           # Public API (macro declarations)
│   ├── QizhMacroKitMacros/     # Macro implementations (SwiftSyntax)
│   │   └── Helpers/            # String manipulation utilities
│   └── QizhMacroKitClient/     # Example usage
├── Tests/                      # Test suites
├── Docs/                       # Documentation
├── Package.swift               # SPM manifest
├── KNOWN_ISSUES.md             # Current limitations
├── TODO.md                     # Roadmap
└── README.md                   # This file
```

## Building

```bash
# Build all targets
swift build

# Build library only (works on Linux)
swift build --target QizhMacroKit

# Run tests
swift test

# Run tests with verbose output
swift test --parallel --verbose
```

## Contributing

Contributions are welcome! Please:

1. Check [TODO.md](TODO.md) for planned work
2. Review [KNOWN_ISSUES.md](KNOWN_ISSUES.md) for bugs to fix
3. Open an issue to discuss significant changes
4. Submit a PR with tests for new functionality

## License

QizhMacroKit is available under the MIT license. See the LICENSE file for more info.

## Author

**Serhii Shevchenko** — [@qizh](https://github.com/qizh)
