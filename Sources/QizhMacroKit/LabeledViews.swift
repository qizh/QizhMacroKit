//
//  LabeledViews.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 07.09.2025.
//

/*
@attached(body)
@attached(peer)
@attached(accessor)
@attached(memberAttribute)
public macro LabeledViews() = #externalMacro(
	module: "QizhMacroKitMacros",
	type: "LabeledViewsMacro"
)
*/

/// Wraps the body of a computed View property into `LabeledViews { ... }` and
/// transforms each top-level expression into `expr.labeledView(label: "expr")`.
///
/// Usage:
///   @LabeledViews
///   var name: some View {
///       firstName
///       lastName
///   }
///
/// Expands to:
///   var name: some View {
///       LabeledViews {
///           firstName.labeledView(label: "firstName")
///            lastName.labeledView(label: "lastName")
///       }
///   }
@attached(body)
@attached(accessor)
public macro LabeledViews() = #externalMacro(
	module: "QizhMacroKitMacros",
	type: "LabeledViewsMacro"
)
