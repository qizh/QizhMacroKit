//
//  StringifyGenerator.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 08.10.2024.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: Helpers

/// Macro implementation for `#stringify`.
///
/// Converts an expression to its source code representation as a `String`.
/// The macro captures the exact source text without evaluating the expression.
///
/// ## Example
///
/// ```swift
/// let x = 42
/// let text = #stringify(x * 2 + 1)
/// print(text) // "x * 2 + 1"
/// ```
///
/// ## Use Cases
///
/// - Debugging and logging with source context
/// - Generating documentation from code
/// - Creating string representations of expressions
/// - Test assertions showing the tested expression
///
/// - SeeAlso: `#dictionarify` for capturing both source and evaluated value
public struct StringifyGenerator: ExpressionMacro {
	public static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
		in context: some MacroExpansionContext
	) throws -> ExprSyntax {
		let argument = try firstArgument(of: node)
		return "\(literal: argument.description)"
	}
}

// MARK: Dictionarify

public struct DictionarifyGenerator: ExpressionMacro {
	public static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
		in context: some MacroExpansionContext
	) throws -> ExprSyntax {
		let argument = try firstArgument(of: node)
		return "(key: \(literal: argument.description), value: \(argument))"
	}
}

// MARK: Utils

/// Shared utility: extract *source* text of the first argument exactly as written.
fileprivate func firstArgument(of node: some FreestandingMacroExpansionSyntax) throws -> ExprSyntax {
	if let expr = node.arguments.first?.expression {
		expr
	} else {
		throw QizhMacroGeneratorDiagnostic(
			message: "Stringify requires one argument",
			id: .missingArgument,
			severity: .error
		)
	}
}
