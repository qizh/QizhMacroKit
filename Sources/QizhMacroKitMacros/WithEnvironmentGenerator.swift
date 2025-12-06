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
import SwiftUI
import Observation

public struct WithEnvironmentGenerator: CodeItemMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingCodeItemAt codeItem: some CodeItemSyntax,
		in context: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {
		let arguments = node.arguments?.as(LabeledExprListSyntax.self)
		let providedName = arguments?.first?.expression.as(StringLiteralExprSyntax.self)?.segments
			.compactMap { segment in
				if case .stringSegment(let content)? = segment.as(StringSegmentSyntax.self) {
					content.content.text
				} else {
					nil
				}
			}
			.joined()
		let variableClosureExpr = arguments?.count == 2 ? arguments?.last?.expression : arguments?.first?.expression
		guard let variableClosure = variableClosureExpr?.as(ClosureExprSyntax.self) else {
			context.diagnose(.error(
				node: Syntax(node),
				message: "@WithEnvironment requires a closure with variable declarations",
				id: .custom("withEnvironment.missingEnvironmentVariables")
			))
			return [CodeBlockItemSyntax(item: .codeBlockItem(codeItem))]
		}

		guard let expression = codeItem.item.as(ExprSyntax.self) else {
			context.diagnose(.error(
				node: Syntax(codeItem),
				message: "@WithEnvironment must be attached to a SwiftUI view expression",
				id: .custom("withEnvironment.invalidAttachment")
			))
			return [CodeBlockItemSyntax(item: .codeBlockItem(codeItem))]
		}

		let variables = Self.parseVariables(in: variableClosure, context: context)
		guard !variables.isEmpty else {
			context.diagnose(.error(
				node: Syntax(variableClosure),
				message: "@WithEnvironment requires at least one variable declaration",
				id: .custom("withEnvironment.missingVariables")
			))
			return [CodeBlockItemSyntax(item: .codeBlockItem(codeItem))]
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
			CodeBlockItemSyntax(item: .decl(DeclSyntax(stringLiteral: wrapperStruct))),
			CodeBlockItemSyntax(item: .expr(ExprSyntax(stringLiteral: wrapperCall)))
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

        var propertyDeclaration: String {
                """
                private var \(name)Binding = EnvironmentBindingResolver.binding(for: \(type).self)

                private var \(name): \(type) { \(name)Binding.value }
                """.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var accessExpression: String { name }
}

private enum EnvironmentBindingResolver {
        static func binding<T: ObservableObject>(for type: T.Type) -> EnvironmentObjectBinding<T> {
                EnvironmentObjectBinding<T>()
        }

        static func binding<T: Observable>(for type: T.Type) -> EnvironmentValueBinding<T> {
                EnvironmentValueBinding<T>()
        }

        static func binding<T>(for type: T.Type) -> UnsupportedEnvironmentBinding<T> {
                UnsupportedEnvironmentBinding(type: type)
        }
}

private struct EnvironmentObjectBinding<T: ObservableObject> {
        @EnvironmentObject private var stored: T

        var value: T { stored }
}

private struct EnvironmentValueBinding<T: Observable> {
        @Environment(T.self) private var stored: T

        var value: T { stored }
}

private struct UnsupportedEnvironmentBinding<T> {
        let type: T.Type

        @available(*, unavailable, message: "Unsupported environment variable type")
        var value: T {
                fatalError("Unsupported environment variable type: \(type)")
        }
}
