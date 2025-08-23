//
//  StringifyGenerator.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 08.10.2024.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftCompilerPlugin
import SwiftDiagnostics

// MARK: Stringify

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
