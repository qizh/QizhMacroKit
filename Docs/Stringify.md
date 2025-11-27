# Stringify Macros

> Last Updated: August 22, 2025

Freestanding expression macros for converting expressions to their string representations.

## Overview

The Stringify module provides two complementary macros:

- **`#stringify`** — Returns only the source text of an expression as a `String`
- **`#dictionarify`** — Returns a key-value pair containing both the source text and the evaluated value

Both macros are useful for debugging, logging, and creating self-documenting code.

## Macros

### `#stringify`

Converts an expression to its source text representation.

```swift
@freestanding(expression)
public macro stringify<T>(_ value: T) -> String
```

#### Usage

```swift
import QizhMacroKit

let x = 5
let text = #stringify(x + 1)  // "x + 1"
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `value` | `T` | Any expression to convert to a string |

#### Returns

A `String` containing the source text of the expression exactly as written.

---

### `#dictionarify`

Returns a dictionary element containing both the source text as a key and the evaluated value.

```swift
@freestanding(expression)
public macro dictionarify<T>(_ value: T) -> Dictionary<String, T>.Element
```

#### Usage

```swift
import QizhMacroKit

let pair = #dictionarify(2 * 3)
print(pair.key)    // "2 * 3"
print(pair.value)  // 6
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `value` | `T` | Any expression to capture |

#### Returns

A `Dictionary<String, T>.Element` tuple with:
- `key`: The source text of the expression
- `value`: The evaluated result of the expression

## Examples

### Debugging Variables

```swift
let isConnected = false
let connectionID: Int? = 123

// Get just the expression text
print(#stringify(isConnected))                    // "isConnected"
print(#stringify(isConnected && connectionID != nil))  // "isConnected && connectionID != nil"

// Get both expression and value
let result = #dictionarify(connectionID != nil)
print("\(result.key) = \(result.value)")          // "connectionID != nil = true"
```

### Creating Self-Documenting Logs

```swift
func logValue<T>(_ pair: (key: String, value: T)) {
    print("[\(pair.key)] = \(pair.value)")
}

let count = 42
logValue(#dictionarify(count))          // "[count] = 42"
logValue(#dictionarify(count * 2))      // "[count * 2] = 84"
```

## Error Handling

The `#stringify` macro requires exactly one argument. Calling it without arguments will produce a compile-time error:

```swift
// Compile-time error: "Stringify requires one argument"
let invalid = #stringify()
```

## See Also

- [CaseName](CaseName.md) — Generate case name properties for enums
- [CaseValue](CaseValue.md) — Extract associated values from enum cases
