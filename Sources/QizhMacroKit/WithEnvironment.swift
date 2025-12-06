//
//  WithEnvironment.swift
//  QizhMacroKit
//
//  Created by Qizh in December 2025.
//

/// Generates a helper wrapper view that injects environment values into the attached view expression.
///
/// The macro accepts an optional name and a closure with plain variable declarations. Each declaration
/// describes an environment dependency that will be fetched inside the generated wrapper view and passed
/// into the wrapped expression.
@freestanding(declaration, names: arbitrary)
public macro WithEnvironment(
	_ name: StringLiteralType? = nil,
	_ environmentVariables: () -> Void
) = #externalMacro(module: "QizhMacroKitMacros", type: "WithEnvironmentGenerator")
