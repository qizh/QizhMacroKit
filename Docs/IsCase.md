# IsCase Macro

> Last Updated: November 25, 2025

An attached member macro that generates boolean properties and membership utilities for enum cases.

## Overview

The `@IsCase` macro is a powerful enum enhancement tool that generates:

1. **Boolean properties** — `is<CaseName>` properties for checking the current case
2. **Cases enum** — A parameterless representation of all cases
3. **Membership methods** — `isAmong(_:)` methods for checking against multiple cases

## Declaration

```swift
@attached(member, names: arbitrary)
public macro IsCase()
```

## Basic Usage

Apply the `@IsCase` macro to any enum:

```swift
import QizhMacroKit

@IsCase
enum Status {
    case idle
    case loading
    case success(data: Data)
    case failure(error: Error)
}

let status = Status.loading

// Boolean properties
print(status.isIdle)     // false
print(status.isLoading)  // true
print(status.isSuccess)  // false
print(status.isFailure)  // false
```

## Generated Members

### Boolean Properties

For each case, a computed property `is<CaseName>` is generated:

```swift
@IsCase
enum Direction {
    case north
    case south
    case east
    case west
}

// Generated:
// var isNorth: Bool
// var isSouth: Bool
// var isEast: Bool
// var isWest: Bool
```

### Single-Case Optimization

When an enum has only one case, the generated property always returns `true`:

```swift
@IsCase
enum SingleState {
    case active
}

let state = SingleState.active
print(state.isActive)  // Always true
```

### Cases Enum

A nested `Cases` enum is generated, providing a parameterless representation:

```swift
@IsCase
enum NetworkResult {
    case success(Data)
    case failure(Error)
    case loading
}

// Generated:
// enum Cases: Equatable, CaseIterable {
//     case success
//     case failure
//     case loading
// }
```

### parametersErasedCase Property

Converts the current value to its `Cases` representation:

```swift
let result = NetworkResult.success(someData)
let caseOnly = result.parametersErasedCase  // Cases.success
```

### Membership Methods

Two overloaded `isAmong(_:)` methods are generated:

```swift
// Array-based
func isAmong(_ cases: [Cases]) -> Bool

// Variadic
func isAmong(_ cases: Cases...) -> Bool
```

#### Usage

```swift
@IsCase
enum Action {
    case setup(api: String)
    case update
    case cache
    case export(target: String)
    case `import`(String)
    case sync
}

let action: Action = .sync

// Check against multiple cases
print(action.isAmong(.setup, .update, .sync))  // true
print(action.isAmong([.export, .import]))      // false
```

## Reserved Keyword Handling

Swift reserved keywords used as case names are properly escaped:

```swift
@IsCase
enum Token {
    case `class`
    case `struct`
    case `enum`
    case identifier(String)
}

let token = Token.class
print(token.isClass)   // true
print(token.isStruct)  // false

// Membership check with escaped keywords
print(token.isAmong(.class, .struct))  // true
```

## Access Modifiers

Generated members inherit the enum's access level:

```swift
@IsCase
public enum PublicState {
    case active
    case inactive
}

// Generated:
// public var isActive: Bool
// public var isInactive: Bool
// public enum Cases: Equatable, CaseIterable { ... }
// public var parametersErasedCase: Cases
// public func isAmong(_ cases: [Cases]) -> Bool
// public func isAmong(_ cases: Cases...) -> Bool
```

Supported access levels: `public`, `open`, `package`, `internal`, `fileprivate`, `private`

## Empty Enum Warning

Applying `@IsCase` to an empty enum produces a warning:

```swift
@IsCase
enum Empty { }
// Warning: There are no cases in the enum, so `@IsCase` can NOT be applied.
```

## Complete Example

```swift
import QizhMacroKit

@IsCase
enum AppState {
    case launching
    case onboarding(step: Int)
    case authenticated(user: User)
    case error(Error)
}

class AppCoordinator {
    var state: AppState = .launching
    
    func canShowMainContent() -> Bool {
        state.isAuthenticated
    }
    
    func isInSetupFlow() -> Bool {
        state.isAmong(.launching, .onboarding)
    }
    
    func handleStateChange() {
        switch state.parametersErasedCase {
        case .launching:
            showSplash()
        case .onboarding:
            showOnboarding()
        case .authenticated:
            showMainApp()
        case .error:
            showError()
        }
    }
}
```

## Use Cases

### SwiftUI Bindings

```swift
struct ContentView: View {
    @State private var loadState: LoadState = .idle
    
    var body: some View {
        VStack {
            if loadState.isLoading {
                ProgressView()
            }
            
            Button("Load") {
                load()
            }
            .disabled(!loadState.isIdle)
        }
    }
}
```

### State Machine Guards

```swift
func transition(to newState: State) {
    guard state.isAmong(.idle, .paused) else {
        print("Cannot transition from \(state)")
        return
    }
    state = newState
}
```

## Limitations

- Only works with enums (applying to other types produces a compile-time error)
- Empty enums generate a warning and no members
- The `Cases` enum strips all associated values

## See Also

- [IsNotCase](IsNotCase.md) — Generate negated boolean properties
- [CaseName](CaseName.md) — Generate case name string properties
- [CaseValue](CaseValue.md) — Extract associated values from enum cases
