//
//  WithEnvironment.swift
//  QizhMacroKit
//
//  Created by Qizh in December 2025.
//

/// Generates a helper wrapper struct that injects environment values into a view.
///
/// This macro produces a fileprivate struct conforming to `View` that fetches
/// environment dependencies and passes them to a content closure.
///
/// ## Usage
/// ```swift
/// #WithEnvironment("MyView", { var store: MyStore; var nav: MyNavigation })
/// ```
///
/// This generates:
/// ```swift
/// fileprivate struct _MyView_<hash><Content: View>: View {
///     @EnvironmentObject private var store: MyStore
///     @Environment(MyNavigation.self) private var nav
///     let content: @MainActor @Sendable (MyStore, MyNavigation) -> Content
///     var body: some View { content(store, nav) }
/// }
/// ```
@freestanding(declaration, names: arbitrary)
public macro WithEnvironment(
	_ name: StringLiteralType? = nil,
	_ declarations: () -> Void
) = #externalMacro(module: "QizhMacroKitMacros", type: "WithEnvironmentDeclarationGenerator")

// MARK: - Experimental CodeItem Macro
// The following macro uses the experimental CodeItemMacros feature which is not available
// in production Swift compilers. It remains commented out for future use.
//
// Usage (when CodeItemMacros is available):
// ```swift
// #WithEnvironmentItem("MyView", { var store: MyStore; var nav: MyNavigation }) {
//     Text("Hello")
// }
// ```
//
// @freestanding(codeItem, names: arbitrary)
// public macro WithEnvironmentItem(
// 	_ name: StringLiteralType? = nil,
// 	_ declarations: () -> Void
// ) = #externalMacro(module: "QizhMacroKitMacros", type: "WithEnvironmentGenerator")
