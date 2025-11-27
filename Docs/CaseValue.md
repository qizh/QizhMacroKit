# CaseValue Macro

> Last Updated: May 31, 2025

An attached member macro that generates computed properties to extract associated values from enum cases.

## Overview

The `@CaseValue` macro automatically generates optional computed properties for each associated value in your enum cases. This eliminates boilerplate code when you need to access specific values from enum cases.

## Declaration

```swift
@attached(member, names: arbitrary)
public macro CaseValue()
```

## Usage

Apply the `@CaseValue` macro to any enum with associated values:

```swift
import QizhMacroKit

@CaseValue
enum Token {
    case int(Int)
    case text(String)
}

// Generated properties:
// - var int: Int?
// - var textString: String?

let number = Token.int(8)
print(number.int)         // Optional(8)
print(number.textString)  // nil

let word = Token.text("hello")
print(word.int)           // nil
print(word.textString)    // Optional("hello")
```

## Property Naming Conventions

The macro generates property names based on parameter names and types:

### Named Parameters

When a parameter has an explicit name, it's combined with the case name:

```swift
@CaseValue
enum Request {
    case fetch(url: URL)
    case submit(data: Data)
}

// Generated: fetchUrl: URL?, submitData: Data?
```

### Unnamed Parameters

When a parameter has no name, the type name is used:

```swift
@CaseValue
enum Value {
    case number(Int)
    case text(String)
}

// Generated: numberInt: Int?, textString: String?
```

### Same Name as Case

When the parameter name matches the case name (case-insensitive), only the case name is used:

```swift
@CaseValue
enum Option {
    case option(_ option: String)
}

// Generated: option: String?
```

### Multiple Same-Type Parameters

When multiple parameters have the same type, indices are appended:

```swift
@CaseValue
enum Visit {
    case log(UInt, String, Date, UInt)
}

// Generated: logUInt0: UInt?, logString: String?, logDate: Date?, logUInt3: UInt?
```

### Function Type Parameters

Function types are automatically wrapped in parentheses for the optional type:

```swift
@CaseValue
enum Callback {
    case onSelect(_ callback: () -> Void)
}

// Generated: onSelectCallback: (() -> Void)?
```

## Access Modifiers

The generated properties inherit the access level of the enum:

```swift
@CaseValue
public enum PublicToken {
    case value(Int)
}
// Generated: public var valueInt: Int?

@CaseValue
fileprivate enum PrivateToken {
    case value(Int)
}
// Generated: fileprivate var valueInt: Int?
```

## Complete Example

```swift
import QizhMacroKit

@CaseValue
enum NetworkResult {
    case success(data: Data)
    case failure(_ error: Error)
    case loading(progress: Double)
    case cancelled
}

let result: NetworkResult = .success(data: someData)

// Access associated values safely
if let data = result.successData {
    processData(data)
}

if let error = result.failureError {
    handleError(error)
}

if let progress = result.loadingProgress {
    updateProgressBar(progress)
}
```

## Limitations

- Only works with enums (applying to other types produces a compile-time error)
- Cases without associated values are skipped (no property generated)
- Reserved Swift keywords as case names must be escaped with backticks

## See Also

- [CaseName](CaseName.md) — Generate case name string properties
- [IsCase](IsCase.md) — Generate boolean case-checking properties
- [IsNotCase](IsNotCase.md) — Generate negated boolean case-checking properties
