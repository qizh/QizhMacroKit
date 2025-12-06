# @WithEnvironment

`@WithEnvironment` is a freestanding code-item macro that wraps a SwiftUI view expression into a generated view struct, injecting environment dependencies defined in a closure. The macro fetches `ObservableObject` instances via `@EnvironmentObject` and `Observable` instances via `@Environment(Type.self)` and passes them into the wrapped content.

## Usage

```swift
@WithEnvironment("Sample") {
	var store: MacroStore
	var navigation: MacroNavigation
}
Text("Hello")
```

This expansion produces a fileprivate wrapper view named using the provided prefix and a deterministic hash suffix, with environment accessors and a `content` closure that supplies the requested variables to the original expression.

## Rules

- Declare one or more variables inside the closure; each must provide a type annotation and no initializer.
- Variable names and types must be unique within the macro invocation.
- Types conforming to `ObservableObject` are fetched with `@EnvironmentObject`.
- Types conforming to `Observable` are fetched with `@Environment(Type.self)`.
- Other types emit a warning and become unavailable properties.
- The macro must annotate a SwiftUI view expression; otherwise, it emits an error diagnostic.

## Example Expansion

```swift
fileprivate struct _Sample_89ABCDEF<Content: View>: View {
	@EnvironmentObject private var store: MacroStore
	@Environment(MacroNavigation.self) private var navigation

	let content: @MainActor @Sendable (MacroStore, MacroNavigation) -> Content

	var body: some View {
		content(store, navigation)
	}
}

_Sample_89ABCDEF(content: { store, navigation in 
	Text("Hello")
})
```
