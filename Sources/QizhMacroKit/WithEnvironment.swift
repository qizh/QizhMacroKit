//
//  WithEnvironment.swift
//  QizhMacroKit
//
//  Created by Qizh in December 2025.
//

// MARK: - WithEnv (Production)
/// Generates a helper wrapper struct that injects environment values into a view.
///
/// This macro produces a fileprivate struct conforming to `View` that fetches
/// environment dependencies and passes them to a content closure.
///
/// ## Usage
/// ```swift
/// #WithEnv("MyView", { var store: MyStore; var nav: MyNavigation })
/// // Then instantiate manually:
/// _MyView(content: { store, nav in Text("Hello") })
/// ```
///
/// This generates:
/// ```swift
/// fileprivate struct _MyView<Content: View>: View {
///     @EnvironmentObject private var store: MyStore
///     @Environment(MyNavigation.self) private var nav
///     let content: @MainActor @Sendable (MyStore, MyNavigation) -> Content
///     var body: some View { content(store, nav) }
/// }
/// ```
@freestanding(declaration, names: arbitrary)
public macro WithEnv(
	_ name: StringLiteralType? = nil,
	_ declarations: () -> Void
) = #externalMacro(module: "QizhMacroKitMacros", type: "WithEnvGenerator")

// MARK: - ProvidingEnvironment (Experimental)
/// Generates a wrapper struct AND instantiates it with the provided view expression.
///
/// This macro uses the experimental `codeItem` macro role which is not available
/// in production Swift compilers. It remains commented out for future use.
///
/// ## Usage (when CodeItemMacros is available)
/// ```swift
/// #ProvidingEnvironment("MyView", { var store: MyStore; var nav: MyNavigation }) {
///     Text("Hello, \(store.name)")
/// }
/// ```
///
/// This would generate:
/// ```swift
/// fileprivate struct _MyView_<hash><Content: View>: View {
///     @EnvironmentObject private var store: MyStore
///     @Environment(MyNavigation.self) private var nav
///     let content: @MainActor @Sendable (MyStore, MyNavigation) -> Content
///     var body: some View { content(store, nav) }
/// }
/// _MyView_<hash>(content: { store, nav in Text("Hello, \(store.name)") })
/// ```
// @freestanding(codeItem, names: arbitrary)
// public macro ProvidingEnvironment(
// 	_ name: StringLiteralType? = nil,
// 	_ declarations: () -> Void
// ) = #externalMacro(module: "QizhMacroKitMacros", type: "ProvidingEnvironmentGenerator")
