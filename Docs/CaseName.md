# CaseName Macro

> Last Updated: October 8, 2024

An attached member macro that generates a computed property returning the enum case name as a string.

## Overview

The `@CaseName` macro adds a `caseName` computed property to enums that returns the name of the current case as a `String`. This is useful for logging, debugging, serialization, and display purposes.

## Declaration

```swift
@attached(member, names: arbitrary)
public macro CaseName()
```

## Usage

Apply the `@CaseName` macro to any enum:

```swift
import QizhMacroKit

@CaseName
enum Status {
    case idle
    case loading
    case success(data: Data)
    case failure(_ error: Error)
}

// Generated property:
// var caseName: String { ... }

let status = Status.loading
print(status.caseName)  // "loading"

let result = Status.success(data: someData)
print(result.caseName)  // "success"
```

## Behavior

The `caseName` property returns **only** the case name, without any associated value information:

| Enum Value | `caseName` Result |
|------------|-------------------|
| `.idle` | `"idle"` |
| `.loading` | `"loading"` |
| `.success(data: someData)` | `"success"` |
| `.failure(error)` | `"failure"` |

## Reserved Keyword Case Names

When using Swift reserved keywords as case names (escaped with backticks), the property correctly returns the unescaped name:

```swift
@CaseName
enum Token {
    case `default`
    case custom(String)
}

let token = Token.default
print(token.caseName)  // "default"
```

## Access Modifiers

The generated property inherits the access level of the enum:

```swift
@CaseName
public enum PublicStatus {
    case ready
    case running
}
// Generated: public var caseName: String

@CaseName
fileprivate enum PrivateStatus {
    case on
    case off
}
// Generated: fileprivate var caseName: String
```

## Use Cases

### Logging

```swift
func logStateChange(_ newState: Status) {
    print("State changed to: \(newState.caseName)")
}
```

### Analytics Events

```swift
func trackEvent(_ event: AnalyticsEvent) {
    analytics.track(name: event.caseName, properties: event.properties)
}
```

### UI Display

```swift
@CaseName
enum Priority {
    case low
    case medium
    case high
    case critical
}

// In a SwiftUI view
Text(task.priority.caseName.capitalized)
```

### Switch Statement Labels

```swift
func describe(_ status: Status) -> String {
    "Current status: \(status.caseName)"
}
```

## Requirements

- The enum must have at least one case
- Applying to empty enums produces a compile-time error

## Error Messages

| Condition | Error Message |
|-----------|---------------|
| Applied to non-enum | `@CaseName can only be applied to enums` |
| Applied to empty enum | `@CaseName can only be applied to enums with cases` |

## Limitations

- Only works with enums (structs, classes, and other types are not supported)
- The enum must contain at least one case
- Does not include associated value information in the output

## See Also

- [IsCase](IsCase.md) — Generate boolean case-checking properties
- [IsNotCase](IsNotCase.md) — Generate negated boolean case-checking properties
- [CaseValue](CaseValue.md) — Extract associated values from enum cases
