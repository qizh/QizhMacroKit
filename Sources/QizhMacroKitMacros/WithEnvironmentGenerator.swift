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
		
		// Find the closure with variable declarations (can be in arguments or additional trailing closures)
		let variableClosureExpr: ExprSyntax?
		if arguments.count == 2 {
			variableClosureExpr = arguments.last?.expression
		} else if arguments.count == 1 && arguments.first?.expression.as(StringLiteralExprSyntax.self) != nil {
			// Name provided, closure might be in additional trailing closures
			if let closure = node.additionalTrailingClosures.first?.closure {
				variableClosureExpr = ExprSyntax(closure)
			} else {
				variableClosureExpr = nil
			}
		} else {
			variableClosureExpr = arguments.first?.expression
		}
		
		guard let variableClosure = variableClosureExpr?.as(ClosureExprSyntax.self) else {
			context.diagnose(.error(
				node: Syntax(node),
				message: "@WithEnvironment requires a closure with variable declarations",
				id: "withEnvironment.missingEnvironmentVariables"
			))
			return []
		}

		guard let trailingClosure = node.trailingClosure else {
			context.diagnose(.error(
				node: Syntax(node),
				message: "@WithEnvironment must have a trailing closure with the view expression",
				id: "withEnvironment.invalidAttachment"
			))
			return []
		}

		let variables = Self.parseVariables(in: variableClosure, context: context)
		guard !variables.isEmpty else {
			context.diagnose(.error(
				node: Syntax(variableClosure),
				message: "@WithEnvironment requires at least one variable declaration",
				id: "withEnvironment.missingVariables"
			))
			return []
		}
		
		// Get the content from the trailing closure
		let expression = ExprSyntax(trailingClosure)

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

				let name = pattern.identifier.text
				if seenNames.contains(name) {
					context.diagnose(.error(
						node: Syntax(pattern),
						message: "Duplicate variable name \(name)",
						id: "withEnvironment.duplicateName"
					))
					continue
				}

				guard let type = binding.typeAnnotation?.type else {
					context.diagnose(.error(
						node: Syntax(binding),
						message: "Environment variable \(name) must declare a type",
						id: "withEnvironment.missingType"
					))
					continue
				}

				let typeText = type.description.trimmingCharacters(in: .whitespacesAndNewlines)
				if seenTypes.contains(typeText) {
					context.diagnose(.error(
						node: Syntax(binding),
						message: "Duplicate environment variable type \(typeText)",
						id: "withEnvironment.duplicateType"
					))
					continue
				}

				if binding.initializer != nil {
					context.diagnose(.error(
						node: Syntax(binding),
						message: "Environment variable \(name) cannot be initialized",
						id: "withEnvironment.initialized"
					))
					continue
				}

				let classification = EnvironmentClassification(typeText: typeText)
				if classification == .unsupported {
					context.diagnose(.warning(
						node: Syntax(binding),
						message: "\(typeText) is not Observable or ObservableObject. Remove its declaration.",
						id: "withEnvironment.unsupportedType"
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
\t\(environmentLines)

\tlet content: \(contentSignature)

\tvar body: some View {
\t\t\(contentCall)
\t}
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
