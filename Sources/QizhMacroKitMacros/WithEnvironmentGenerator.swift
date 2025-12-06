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

// MARK: - WithEnv Generator (Production)
/// Generator for `#WithEnv` - `@freestanding(declaration)` macro.
/// Produces only the wrapper struct declaration. Works in production Swift compilers.
public struct WithEnvGenerator: DeclarationMacro {
	public static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
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
		
		// Find the closure with variable declarations
		let variableClosureExpr: ExprSyntax?
		if arguments.count == 2 {
			variableClosureExpr = arguments.last?.expression
		} else if arguments.count == 1 && arguments.first?.expression.as(StringLiteralExprSyntax.self) != nil {
			variableClosureExpr = node.trailingClosure.map { ExprSyntax($0) }
		} else if arguments.count == 1 {
			variableClosureExpr = arguments.first?.expression
		} else {
			variableClosureExpr = node.trailingClosure.map { ExprSyntax($0) }
		}
		
		guard let variableClosure = variableClosureExpr?.as(ClosureExprSyntax.self) else {
			context.diagnose(
				Diagnostic(
					node: Syntax(node),
					message: QizhMacroGeneratorDiagnostic(
						message: "#WithEnv requires a closure with variable declarations",
						id: "withEnv.missingEnvironmentVariables",
						severity: .error
					)
				)
			)
			return []
		}

		let variables = EnvironmentMacroHelpers.parseVariables(in: variableClosure, context: context)
		guard !variables.isEmpty else {
			context.diagnose(
				Diagnostic(
					node: Syntax(variableClosure),
					message: QizhMacroGeneratorDiagnostic(
						message: "#WithEnv requires at least one variable declaration",
						id: "withEnv.missingVariables",
						severity: .error
					)
				)
			)
			return []
		}

		let structName = EnvironmentMacroHelpers.makeStructName(from: providedName)
		let wrapperStruct = EnvironmentMacroHelpers.makeWrapperStruct(
			named: structName,
			variables: variables
		)

		return [DeclSyntax(stringLiteral: wrapperStruct)]
	}
}

// MARK: - ProvidingEnvironment Generator (Experimental)
/// Generator for `#ProvidingEnvironment` - `@freestanding(codeItem)` macro.
/// Produces both struct declaration and instantiation.
/// Requires experimental CodeItemMacros feature.
public struct ProvidingEnvironmentGenerator: CodeItemMacro {
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
		let variableClosureExpr: ExprSyntax?
		let viewExpr: ExprSyntax?
		
		if arguments.count == 2 {
			variableClosureExpr = arguments.last?.expression
			viewExpr = node.trailingClosure.map { ExprSyntax($0) }
		} else if arguments.count == 1 && arguments.first?.expression.as(StringLiteralExprSyntax.self) != nil {
			variableClosureExpr = node.trailingClosure.map { ExprSyntax($0) }
			viewExpr = node.additionalTrailingClosures.first.map { ExprSyntax($0.closure) }
		} else if arguments.count == 1 {
			variableClosureExpr = arguments.first?.expression
			viewExpr = node.trailingClosure.map { ExprSyntax($0) }
		} else {
			variableClosureExpr = node.trailingClosure.map { ExprSyntax($0) }
			viewExpr = node.additionalTrailingClosures.first.map { ExprSyntax($0.closure) }
		}
		
		guard let variableClosure = variableClosureExpr?.as(ClosureExprSyntax.self) else {
			context.diagnose(
				Diagnostic(
					node: Syntax(node),
					message: QizhMacroGeneratorDiagnostic(
						message: "#ProvidingEnvironment requires a closure with variable declarations",
						id: "providingEnvironment.missingEnvironmentVariables",
						severity: .error
					)
				)
			)
			return []
		}

		guard let expression = viewExpr else {
			context.diagnose(
				Diagnostic(
					node: Syntax(node),
					message: QizhMacroGeneratorDiagnostic(
						message: "#ProvidingEnvironment must have a trailing closure with the view expression",
						id: "providingEnvironment.missingViewExpression",
						severity: .error
					)
				)
			)
			return []
		}

		let variables = EnvironmentMacroHelpers.parseVariables(in: variableClosure, context: context)
		guard !variables.isEmpty else {
			context.diagnose(
				Diagnostic(
					node: Syntax(variableClosure),
					message: QizhMacroGeneratorDiagnostic(
						message: "#ProvidingEnvironment requires at least one variable declaration",
						id: "providingEnvironment.missingVariables",
						severity: .error
					)
				)
			)
			return []
		}

		let structName = EnvironmentMacroHelpers.makeStructName(from: providedName, seed: expression.description)
		let wrapperStruct = EnvironmentMacroHelpers.makeWrapperStruct(
			named: structName,
			variables: variables
		)
		let wrapperCall = EnvironmentMacroHelpers.makeWrapperCall(
			named: structName,
			variables: variables,
			bodyExpression: expression
		)

		return [
			CodeBlockItemSyntax(item: .decl(DeclSyntax(stringLiteral: wrapperStruct))),
			CodeBlockItemSyntax(item: .expr(ExprSyntax(stringLiteral: wrapperCall)))
		]
	}
}

// MARK: - Shared Helpers
private enum EnvironmentMacroHelpers {
	static func parseVariables(
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
					context.diagnose(
						Diagnostic(
							node: Syntax(pattern),
							message: QizhMacroGeneratorDiagnostic(
								message: "Duplicate variable name \(name)",
								id: "environment.duplicateName",
								severity: .error
							)
						)
					)
					continue
				}

				guard let type = binding.typeAnnotation?.type else {
					context.diagnose(
						Diagnostic(
							node: Syntax(binding),
							message: QizhMacroGeneratorDiagnostic(
								message: "Environment variable \(name) must declare a type",
								id: "environment.missingType",
								severity: .error
							)
						)
					)
					continue
				}

				let typeText = type.description.trimmingCharacters(in: .whitespacesAndNewlines)
				if seenTypes.contains(typeText) {
					context.diagnose(
						Diagnostic(
							node: Syntax(binding),
							message: QizhMacroGeneratorDiagnostic(
								message: "Duplicate environment variable type \(typeText)",
								id: "environment.duplicateType",
								severity: .error
							)
						)
					)
					continue
				}

				if binding.initializer != nil {
					context.diagnose(
						Diagnostic(
							node: Syntax(binding),
							message: QizhMacroGeneratorDiagnostic(
								message: "Environment variable \(name) cannot be initialized",
								id: "environment.initialized",
								severity: .error
							)
						)
					)
					continue
				}

				let classification = EnvironmentClassification(typeText: typeText)
				if classification == .unsupported {
					context.diagnose(
						Diagnostic(
							node: Syntax(binding),
							message: QizhMacroGeneratorDiagnostic(
								message: "\(typeText) is not Observable or ObservableObject. Remove its declaration.",
								id: "environment.unsupportedType",
								severity: .warning
							)
						)
					)
				}

				variables.append(EnvironmentVariable(name: name, type: typeText, classification: classification))
				seenNames.insert(name)
				seenTypes.insert(typeText)
			}
		}

		return variables
	}

	static func makeStructName(from explicit: String?, seed: String? = nil) -> String {
		let prefix: String
		if let explicit, !explicit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			prefix = explicit.trimmingCharacters(in: .whitespacesAndNewlines)
		} else {
			prefix = "WithEnv"
		}

		if let seed {
			let suffix = seed.fnv1aHashSuffix
			return "_\(prefix)_\(suffix)"
		} else {
			return "_\(prefix)"
		}
	}

	static func makeWrapperStruct(
		named name: String,
		variables: [EnvironmentVariable]
	) -> String {
		let environmentLines = variables.map { $0.propertyDeclaration }.joined(separator: "\n\n")
		// Filter out unsupported variables from content signature
		let supportedVariables = variables.filter { $0.classification != .unsupported }
		let parameters = supportedVariables.map(\.type).joined(separator: ", ")
		let arguments = supportedVariables.map(\.accessExpression).joined(separator: ", ")
		let contentSignature = parameters.isEmpty ? "@MainActor @Sendable () -> Content" : "@MainActor @Sendable (\(parameters)) -> Content"
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

	static func makeWrapperCall(
		named name: String,
		variables: [EnvironmentVariable],
		bodyExpression: ExprSyntax
	) -> String {
		// Filter out unsupported variables from the call
		let supportedVariables = variables.filter { $0.classification != .unsupported }
		let parameterList = supportedVariables.map(\.name).joined(separator: ", ")
		return "\(name)(content: { \(parameterList) in \(bodyExpression) })"
	}
}

// MARK: - Supporting Types
private struct EnvironmentVariable {
	let name: String
	let type: String
	let classification: EnvironmentClassification

	var propertyDeclaration: String {
		switch classification {
		case .environmentObject:
			"@EnvironmentObject private var \(name): \(type)"
		case .environment:
			"@Environment(\(type).self) private var \(name)"
		case .unsupported:
			"@available(*, unavailable, message: \"Unsupported type: \(type)\")\nprivate var \(name): \(type) { fatalError() }"
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
