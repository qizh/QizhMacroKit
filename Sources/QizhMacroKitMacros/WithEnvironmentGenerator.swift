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
import SwiftSyntaxMacros

public struct WithEnvironmentGenerator: DeclarationMacro {
	public static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		let arguments = node.arguments
		
		// Parse the optional name argument
		var providedName: String? = nil
		var variableClosureExpr: ExprSyntax? = nil
		var viewExpression: ExprSyntax? = nil
		
		// Arguments can be:
		// 1. (name, closure, viewExpr)
		// 2. (closure, viewExpr)
		let argArray = Array(arguments)
		
		for arg in argArray {
			if let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self) {
				providedName = stringLiteral.segments.compactMap { segment -> String? in
					if let stringSegment = segment.as(StringSegmentSyntax.self) {
						return stringSegment.content.text
					}
					return nil
				}.joined()
			} else if arg.expression.as(ClosureExprSyntax.self) != nil {
				variableClosureExpr = arg.expression
			} else {
				// Last non-string, non-closure arg is the view expression
				viewExpression = arg.expression
			}
		}
		
		// Also check trailing closure
		if let trailingClosure = node.trailingClosure {
			if variableClosureExpr == nil {
				variableClosureExpr = ExprSyntax(trailingClosure)
			} else {
				viewExpression = ExprSyntax(trailingClosure)
			}
		}
		
		// Check additional trailing closures
		if let additionalClosures = node.additionalTrailingClosures.first {
			viewExpression = ExprSyntax(additionalClosures.closure)
		}
		
		guard let variableClosure = variableClosureExpr?.as(ClosureExprSyntax.self) else {
			context.diagnose(
				Diagnostic(
					node: Syntax(node),
					message: QizhMacroGeneratorDiagnostic(
						message: "#WithEnvironment requires a closure with variable declarations",
						id: .custom("withEnvironment.missingEnvironmentVariables"),
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
						message: "#WithEnvironment requires a view expression",
						id: .custom("withEnvironment.missingViewExpression"),
						severity: .error
					)
				)
			)
			return []
		}

		let variables = Self.parseVariables(in: variableClosure, context: context)
		guard !variables.isEmpty else {
			context.diagnose(
				Diagnostic(
					node: Syntax(variableClosure),
					message: QizhMacroGeneratorDiagnostic(
						message: "#WithEnvironment requires at least one variable declaration",
						id: .custom("withEnvironment.missingVariables"),
						severity: .error
					)
				)
			)
			return []
		}

		let structName = Self.makeStructName(from: providedName, seed: expression.description)
		let wrapperStruct = Self.makeWrapperStruct(
			named: structName,
			variables: variables
		)
		
		// For declaration macro, we can only return declarations
		// The wrapper call needs to be handled differently
		return [
			DeclSyntax(stringLiteral: wrapperStruct)
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
					context.diagnose(
						Diagnostic(
							node: Syntax(pattern),
							message: QizhMacroGeneratorDiagnostic(
								message: "Duplicate variable name \(name)",
								id: .custom("withEnvironment.duplicateName"),
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
								id: .custom("withEnvironment.missingType"),
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
								id: .custom("withEnvironment.duplicateType"),
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
								id: .custom("withEnvironment.initialized"),
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
								id: .custom("withEnvironment.unsupportedType"),
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

	private static func hash(seed: String) -> String {
		var value: UInt64 = 0xcbf29ce484222325
		for scalar in seed.unicodeScalars {
			value ^= UInt64(scalar.value)
			value = value &* 0x100000001b3
		}
		let hex = String(value, radix: 16, uppercase: true)
		return String(hex.suffix(8))
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
		case .environment:
			"@Environment(\(type).self) private var \(name)"
		case .unsupported:
			"@available(*, unavailable, message: \"Unsupported environment variable type: \(type)\")\nprivate var \(name): \(type) { fatalError(\"Unsupported environment variable type: \(type)\") }"
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
