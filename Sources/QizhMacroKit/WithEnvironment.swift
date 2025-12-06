//
//  WithEnvironment.swift
//  QizhMacroKit
//
//  Created by ChatGPT on 2024-10-xx.
//

import SwiftUI

/// Wraps a view-building expression with generated environment bindings.
///
/// The macro takes an optional `name` parameter to influence the generated wrapper type name
/// and a closure that declares environment-bound variables. The following closure should
/// return a `some View` expression that will be rendered using the requested environment values.
@freestanding(expression)
public macro WithEnvironment(
_ name: StringLiteralType? = nil,
_ environmentVariables: () -> Void,
_ content: () -> some View
) -> some View = #externalMacro(module: "QizhMacroKitMacros", type: "WithEnvironmentGenerator")
