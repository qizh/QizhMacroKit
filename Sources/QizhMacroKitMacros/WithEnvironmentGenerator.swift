//
//  WithEnvironmentGenerator.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko in December 2025.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftCompilerPlugin
import SwiftDiagnostics

public struct WithEnvironmentGenerator: CodeItemMacro {
	public static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
		in context: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {
		let arguments = node.arguments
		let providedName = arguments.first?.expression.as(StringLiteralExprSyntax.self)?.segments
			.compactMap { segment in
				if let content = segment.as(StringSegmentSyntax.self) {
					content.content.text
				} else {
					nil
				}
			}
			.joined()
		
		/// Find the closure with variable declarations and the view expression
		/// Possible formats:
		/// 1. #WithEnvironment("Name", { vars }) { view }  - name and vars in args, view in trailing
		/// 2. #WithEnvironment({ vars }) { view }  - vars in args, view in trailing  
		/// 3. #WithEnvironment("Name") { vars } viewExpr: { view }  - name in arg, vars in trailing, view in additional
		let variableClosureExpr: ExprSyntax?
		let viewExpr: ExprSyntax?
		
		if arguments.count == 2 {
			// Both name and variable closure in arguments
			variableClosureExpr = arguments.last?.expression
			viewExpr = node.trailingClosure.map { ExprSyntax($0) }
		} else if arguments.count == 1 && arguments.first?.expression.as(StringLiteralExprSyntax.self) != nil {
			// Only name provided as argument, variable closure is in trailingClosure,
			// view expression is in additionalTrailingClosures
			variableClosureExpr = node.trailingClosure.map { ExprSyntax($0) }
			viewExpr = node.additionalTrailingClosures.first.map { ExprSyntax($0.closure) }
		} else if arguments.count == 1 {
			// Only variable closure in arguments
			variableClosureExpr = arguments.first?.expression
			viewExpr = node.trailingClosure.map { ExprSyntax($0) }
		} else {
			// No arguments - variable closure should be trailing
			variableClosureExpr = node.trailingClosure.map { ExprSyntax($0) }
			viewExpr = node.additionalTrailingClosures.first.map { ExprSyntax($0.closure) }
		}
		
		guard let variableClosure = variableClosureExpr?.as(ClosureExprSyntax.self) else {
			context.diagnose(
				Diagnostic(
					node: Syntax(node),
					message: QizhMacroGeneratorDiagnostic(
						message: "@WithEnvironment requires a closure with variable declarations",
						id: "withEnvironment.missingEnvironmentVariables",
						severity: .error
					)
				)
			)
			return []
		}

		guard let expression = viewExpression else {
			context.diagnose(
				Diagnostic(
					node: Syntax(node),
					message: QizhMacroGeneratorDiagnostic(
						message: "@WithEnvironment requires a view expression",
						id: "withEnvironment.missingViewExpression",
						severity: .error
					)
				)
			)
			return []
		}

		let variables = Self.parseVariables(in: variableClosure, context: context)
		guard !variables.isEmpty else {
			context.diagnose(
				.error(
					node: Syntax(variableClosure),
					message: "@WithEnvironment requires at least one variable declaration",
					id: "withEnvironment.missingVariables"
				)
			)
			return []
		}

		let structName = Self.makeStructName(from: providedName, seed: expression.description)
		let wrapperStruct = Self.makeWrapperStruct(
			named: structName,
			variables: variables
		)
		let wrapperCall = Self.makeWrapperCall(
			named: structName,
			variables: variables,
			bodyExpression: expression
		)

		return [
			DeclSyntax(stringLiteral: wrapperStruct),
			DeclSyntax(stringLiteral: Self.makeWrapperCall(
				named: structName,
				variables: variables,
				bodyExpression: expression
			))
		]
	}

	private static func parseVariables(
		in closure: ClosureExprSyntax,
		context: some MacroExpansionContext
	) -> [EnvironmentVariable] {
		var seenNames = Set<String>()
		var seenTypes = Set<String>()
		var variables: [EnvironmentVariable] = []

		for statement in closure.statements {
			guard let variableDecl = statement.item.as(VariableDeclSyntax.self) else {
				continue
			}

			for binding in variableDecl.bindings {
				guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
					continue
				}

				let name = pattern.identifier.text.withBackticksTrimmed
				if seenNames.contains(name) {
					context.diagnose(.error(
						node: Syntax(pattern),
						message: "Duplicate variable name \(name)",
						id: .custom("withEnvironment.duplicateName")
					))
					continue
				}

				guard let type = binding.typeAnnotation?.type else {
					context.diagnose(.error(
						node: Syntax(binding),
						message: "Environment variable \(name) must declare a type",
						id: .custom("withEnvironment.missingType")
					))
					continue
				}

				let typeText = type.description.trimmingCharacters(in: .whitespacesAndNewlines)
				if seenTypes.contains(typeText) {
					context.diagnose(.error(
						node: Syntax(binding),
						message: "Duplicate environment variable type \(typeText)",
						id: .custom("withEnvironment.duplicateType")
					))
					continue
				}

				if binding.initializer != nil {
					context.diagnose(.error(
						node: Syntax(binding),
						message: "Environment variable \(name) cannot be initialized",
						id: .custom("withEnvironment.initialized")
					))
					continue
				}

				let classification = EnvironmentClassification(typeText: typeText)
				if classification == .unsupported {
					context.diagnose(.warning(
						node: Syntax(binding),
						message: "\(typeText) is not Observable or ObservableObject. Remove its declaration.",
						id: .custom("withEnvironment.unsupportedType")
					))
				}

				variables.append(EnvironmentVariable(name: name, type: typeText, classification: classification))
				seenNames.insert(name)
				seenTypes.insert(typeText)
			}
		}

		return variables
	}

	private static func makeStructName(from explicit: String?, seed: String) -> String {
		let prefix: String
		if let explicit, !explicit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			prefix = explicit.trimmingCharacters(in: .whitespacesAndNewlines)
		} else {
			prefix = "WithEnvironment"
		}

		let suffix = Self.hash(seed: seed)
		return "_\(prefix)_\(suffix)"
	}
	
	/// Computes a hash of the seed string using the FNV-1a 64-bit hash algorithm.
	/// - Parameter seed: The string to hash.
	/// - Returns: An 8-character uppercase hexadecimal string derived from the hash.
	/// - Note: FNV-1a (Fowler-Noll-Vo) is a non-cryptographic hash function known for its
	///   speed and good distribution properties. The constants used are:
	///   - `0xcbf29ce484222325`: The FNV-1a 64-bit offset basis (initial hash value)
	///   - `0x100000001b3`: The FNV-1a 64-bit prime (multiplication factor)
	private static func hash(seed: String) -> String {
		seed.fnv1aHashSuffix
	}

	private static func makeWrapperStruct(
		named name: String,
		variables: [EnvironmentVariable]
	) -> String {
		let environmentLines = variables.map { $0.propertyDeclaration }.joined(separator: "\n\n")
		let parameters = variables.map(\.type).joined(separator: ", ")
		let arguments = variables.map(\.accessExpression).joined(separator: ", ")
		let contentSignature = "@MainActor @Sendable (\(parameters)) -> Content"
		let contentCall = "content(\(arguments))"

		return """
			fileprivate struct \(name)<Content: View>: View {
				\(environmentLines)
				
				let content: \(contentSignature)
				
				var body: some View {
					\(contentCall)
				}
			}
			"""
	}

	private static func makeWrapperCall(
		named name: String,
		variables: [EnvironmentVariable],
		bodyExpression: ExprSyntax
	) -> String {
		let parameterList = variables.map(\.name).joined(separator: ", ")
		return "\(name)(content: { \(parameterList) in \(bodyExpression) })"
	}
}

private struct EnvironmentVariable {
	let name: String
	let type: String
	let classification: EnvironmentClassification

	var propertyDeclaration: String {
		switch classification {
		case .environmentObject:
			"@EnvironmentObject private var \(name): \(type)"
		case .environment, .defaultEnvironment:
			"@Environment(\(type).self) private var \(name)"
		}
	}

	var accessExpression: String { name }
}

private enum EnvironmentClassification {
	case environmentObject
	case environment
	case unsupported

	init(typeText: String) {
		if typeText.contains("ObservableObject") {
			self = .environmentObject
		} else if typeText.contains("Observable") {
			self = .environment
		} else {
			self = .unsupported
		}
	}
}
