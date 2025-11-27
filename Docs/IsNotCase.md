# IsNotCase Macro

> Last Updated: February 6, 2025

An attached member macro that generates negated boolean properties for checking enum cases.

## Overview

The `@IsNotCase` macro generates `isNot<CaseName>` computed properties for each case in an enum. These properties return `true` when the enum value is **not** the specified case, providing a convenient way to write negation checks.

## Declaration

```swift
@attached(member, names: arbitrary)
public macro IsNotCase()
```

## Usage

Apply the `@IsNotCase` macro to any enum:

```swift
import QizhMacroKit

@IsNotCase
enum Direction {
    case left
    case right
    case up
    case down
}

// Generated properties:
// - var isNotLeft: Bool
// - var isNotRight: Bool
// - var isNotUp: Bool
// - var isNotDown: Bool

let direction = Direction.left
print(direction.isNotLeft)   // false
print(direction.isNotRight)  // true
print(direction.isNotUp)     // true
print(direction.isNotDown)   // true
```

## Property Naming

Properties are named using the pattern `isNot<CaseName>` where the first letter of the case name is capitalized:

| Case Name | Generated Property |
|-----------|-------------------|
| `idle` | `isNotIdle` |
| `loading` | `isNotLoading` |
| `success` | `isNotSuccess` |
| `inProgress` | `isNotInProgress` |

## Cases with Associated Values

The macro works seamlessly with cases that have associated values:

```swift
@IsNotCase
enum Status {
    case idle
    case loading
    case success(data: Data)
    case failure(error: Error)
}

let status = Status.success(data: someData)
print(status.isNotIdle)     // true
print(status.isNotLoading)  // true
print(status.isNotSuccess)  // false
print(status.isNotFailure)  // true
```

## Reserved Keyword Case Names

When using Swift reserved keywords as case names (escaped with backticks), the generated property names handle them correctly:

```swift
@IsNotCase
enum Token {
    case `default`(Bool)
    case `is`(_ value: Bool)
    case custom(String)
}

let token = Token.default(true)
print(token.isNotDefault)  // false
print(token.isNotIs)       // true
print(token.isNotCustom)   // true
```

## Access Modifiers

Generated properties inherit the access level of the enum:

```swift
@IsNotCase
public enum PublicState {
    case active
    case inactive
}
// Generated: public var isNotActive: Bool, public var isNotInactive: Bool

@IsNotCase
fileprivate enum PrivateState {
    case on
    case off
}
// Generated: fileprivate var isNotOn: Bool, fileprivate var isNotOff: Bool
```

## Use Cases

### Guard Statements

```swift
func processIfNotLoading(_ status: Status) {
    guard status.isNotLoading else {
        print("Cannot process while loading")
        return
    }
    // Continue processing...
}
```

### Filtering Collections

```swift
let statuses: [Status] = [.idle, .loading, .success(data: data), .failure(error: error)]

// Get all non-idle statuses
let activeStatuses = statuses.filter(\.isNotIdle)
```

### Conditional UI Updates

```swift
// SwiftUI example
Button("Submit") {
    submit()
}
.disabled(formState.isNotReady)
```

## Comparison with IsCase

While `@IsCase` generates `is<CaseName>` properties that return `true` when matched, `@IsNotCase` generates the inverse. You can use both macros together:

```swift
@IsCase
@IsNotCase
enum LoadingState {
    case idle
    case loading
    case complete
}

let state = LoadingState.loading
print(state.isLoading)     // true (from @IsCase)
print(state.isNotLoading)  // false (from @IsNotCase)
```

## Limitations

- Only works with enums (applying to other types produces a compile-time error)
- Empty enums will generate no properties

## See Also

- [IsCase](IsCase.md) — Generate boolean `is<CaseName>` properties
- [CaseName](CaseName.md) — Generate case name string properties
- [CaseValue](CaseValue.md) — Extract associated values from enum cases
