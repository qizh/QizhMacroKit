//
//  LabeledGenerator.swift
//  QizhMacroKit
//
//  Created by OpenAI ChatGPT on 13.01.2025.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftCompilerPlugin
import SwiftDiagnostics

/// Expression macro that transforms an array literal into an ``OrderedDictionary`` whose keys are derived from the element expressions.
public struct LabeledGenerator: ExpressionMacro {
	public static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
		in context: some MacroExpansionContext
	) throws -> ExprSyntax {
		// Get the first argument (the array literal)
		guard let argument = node.arguments.first?.expression,
			  let arrayExpr = argument.as(ArrayExprSyntax.self) else {
			throw QizhMacroGeneratorDiagnostic(
				message: "#Labeled requires an array literal argument",
				id: .missingArgument,
				severity: .error
			)
		}
		
		// Handle empty array
		guard !arrayExpr.elements.isEmpty else {
			return "[:]"
		}
		
		var entries: [String] = []
		for element in arrayExpr.elements {
			let expr = element.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
			let key: String
			if let declRef = element.expression.as(DeclReferenceExprSyntax.self) {
				key = declRef.baseName.text.withBackticksTrimmed
			} else {
				// For non-identifier expressions, use the expression itself as the key
				key = expr
			}
			entries.append("\"\(key)\": \(expr)")
		}
		
		let body = entries.joined(separator: ", ")
		return "[\(raw: body)]"
	}
}

