//
//  ApplyEnvironment.swift
//  QizhMacroKit
//
//  Created by ChatGPT on 2024-10-xx.
//

/// Wraps a view-building expression with generated environment bindings.
///
/// The macro takes an optional `name` parameter to influence the generated wrapper type name
/// and a closure that declares environment-bound variables. The following closure should
/// return a `some View` expression that will be rendered using the requested environment values.
@freestanding(expression)
public macro ApplyEnvironment<Content>(
	_ name: StringLiteralType = "ApplyEnvironment",
	_ variables: () -> Void,
	_ content: () -> Content
) -> Content = #externalMacro(module: "QizhMacroKitMacros", type: "ApplyEnvironmentGenerator")

/// Wraps a view-building expression with generated environment bindings.
///
/// The macro takes a closure that declares environment-bound variables. The following closure should
/// return a `some View` expression that will be rendered using the requested environment values.
@freestanding(expression)
public macro ApplyEnvironment<Content>(
	_ environmentVariables: () -> Void,
	_ content: () -> Content
) -> Content = #externalMacro(module: "QizhMacroKitMacros", type: "ApplyEnvironmentGenerator")
