//
//  WithEnvironmentGenerator.swift
//  QizhMacroKit
//
//  Created by ChatGPT on 2024-10-xx.
//

import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import RegexBuilder

public struct WithEnvironmentGenerator: ExpressionMacro {
	private struct EnvironmentVariable {
		let name: TokenSyntax
		let type: TypeSyntax
		let kind: VariableKind
	}
	
	private enum VariableKind {
		case observableObject
		case observable
		case unknown
		
		var annotation: String {
			switch self {
			case .observableObject: "@EnvironmentObject"
			case .observable: "@Environment"
			case .unknown: "@Environment"
			}
		}
	}
	
	public static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
		in context: some MacroExpansionContext
	) throws -> ExprSyntax {
		let argumentsArray = Array(node.arguments)
		let hasTrailingClosure = node.trailingClosure != nil
		let minimumArgumentCount = hasTrailingClosure ? 1 : 2
		guard argumentsArray.count >= minimumArgumentCount else {
			context.diagnose(
				.error(
					node: Syntax(node),
					message: "#WithEnvironment expects at least a variables declaration closure and a content closure.",
					id: "withEnvironment.missingArguments"
				)
			)
			return "()" as ExprSyntax
		}
		
		let providedName: String? =
			if let first = argumentsArray.first,
			   let literal = first.expression.as(StringLiteralExprSyntax.self),
			   let firstSegment = literal.segments.first?.as(StringSegmentSyntax.self) {
				firstSegment.content.text
			} else {
				nil
			}
		
		let envArgumentIndex = providedName == nil ? 0 : 1
		guard envArgumentIndex < argumentsArray.count,
			  let envClosure = argumentsArray[envArgumentIndex].expression.as(ClosureExprSyntax.self)
		else {
			context.diagnose(
				.error(
					node: Syntax(node),
					message: "Environment declaration closure must be a valid closure expression.",
					id: "withEnvironment.invalidEnvironmentClosure"
				)
			)
			return "()" as ExprSyntax
		}
		
		let contentArgumentIndex = envArgumentIndex + 1
		let contentClosure: ClosureExprSyntax
		if let trailing = node.trailingClosure {
			contentClosure = trailing
		} else if contentArgumentIndex < argumentsArray.count,
				  let closure = argumentsArray[contentArgumentIndex]
								.expression
								.as(ClosureExprSyntax.self) {
			contentClosure = closure
		} else {
			context.diagnose(
				.error(
					node: Syntax(node),
					message: "Content argument must be a closure returning some View.",
					id: "withEnvironment.invalidContentClosure"
				)
			)
			return "()" as ExprSyntax
		}
		
		let variables = parseEnvironmentVariables(from: envClosure, in: context)
		guard !variables.isEmpty else {
			context.diagnose(
				.error(
					node: Syntax(envClosure),
					message: "Provide at least one environment variable declaration.",
					id: "withEnvironment.emptyVariables"
				)
			)
			return "()" as ExprSyntax
		}
		
		let captureNames = collectCaptures(
			from: Syntax(contentClosure.statements)
		)
		.filter { name in
			!variables.contains { v in
				v.name.text == name.text
			}
		}
		
		let structName = makeStructName(
			prefix: providedName,
			seed: envClosure.description + contentClosure.description
		)
		
		return buildExpansion(
			structName: structName,
			captures: captureNames,
			content: contentClosure,
			variables: variables
		)
	}
	
	private static func parseEnvironmentVariables(
		from closure: ClosureExprSyntax,
		in context: some MacroExpansionContext
	) -> [EnvironmentVariable] {
		var result: [EnvironmentVariable] = []
		var names: Set<String> = []
		var types: Set<String> = []
		
		for statement in closure.statements {
			guard let varDecl = statement.item.as(VariableDeclSyntax.self) else { continue }
			for binding in varDecl.bindings {
				if let initializer = binding.initializer {
					context.diagnose(
						.error(
							node: Syntax(initializer),
							message: "Environment variables must not be initialized.",
							id: "withEnvironment.noInitializer"
						)
					)
					continue
				}
				
				guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
					  let type = binding.typeAnnotation?.type
				else {
					context.diagnose(
						.error(
							node: Syntax(binding),
							message: "Environment variable declarations must include a name and a type.",
							id: "withEnvironment.invalidVariable"
						)
					)
					continue
				}
				
				let nameText = pattern.identifier.text
				if !names.insert(nameText).inserted {
					context.diagnose(
						.error(
							node: Syntax(pattern.identifier),
							message: "Duplicate environment variable name \(nameText).",
							id: "withEnvironment.duplicateName"
						)
					)
					continue
				}
				
				let typeText = type.trimmedDescription
				if !types.insert(typeText).inserted {
					context.diagnose(
						.error(
							node: Syntax(type),
							message: "Duplicate environment variable type \(typeText).",
							id: "withEnvironment.duplicateType"
						)
					)
					continue
				}
				
				let classification = classify(type: type)
				if classification == .unknown {
					context.diagnose(
						.warning(
							node: Syntax(type),
							message: "Type \(typeText) does not conform to ObservableObject or Observable.",
							id: "withEnvironment.unsupportedType"
						)
					)
				}
				
				result.append(
					EnvironmentVariable(
						name: pattern.identifier,
						type: type,
						kind: classification
					)
				)
			}
		}
		
		return result
	}
	
	/// Match exactly `ObservableObject` or `Observable`
	/// (optionally with generic parameters)
	private static func classify(type: TypeSyntax) -> VariableKind {
		if let _ = type.trimmedDescription.wholeMatch(of: /^ObservableObject(\s*<.*>)?$/) {
			.observableObject
		} else if let _ = type.trimmedDescription.wholeMatch(of: /^Observable(\s*<.*>)?$/) {
			.observable
		} else {
			.unknown
		}
	}
	
	private static func collectCaptures(from syntax: some SyntaxProtocol) -> [TokenSyntax] {
		let collector = CaptureCollector(viewMode: .sourceAccurate)
		collector.walk(syntax)
		let unique = Set(collector.identifiers.map(\.text))
		return unique
			.map { TokenSyntax.identifier($0) }
			.sorted { $0.text < $1.text }
	}
	
	private static func makeStructName(prefix: String?, seed: String) -> String {
		let suffix = deterministicSuffix(for: seed)
		let sanitized = prefix?.replacing(/[^A-Za-z0-9]/, with: "_") ?? "WithEnvironment"
		return "_\(sanitized)_\(suffix)"
	}
	
	private static func deterministicSuffix(for seed: String) -> String {
		var hash: UInt64 = 0xcbf29ce484222325
		for byte in seed.utf8 {
			hash ^= UInt64(byte)
			hash &*= 0x100000001b3
		}
		let hex = String(hash, radix: 16, uppercase: true)
		if hex.count >= 8 {
			return String(hex.prefix(8))
		} else {
			return hex.padding(toLength: 8, withPad: "0", startingAt: 0)
		}
	}
	
	private static func buildExpansion(
		structName: String,
		captures: [TokenSyntax],
		content: ClosureExprSyntax,
		variables: [EnvironmentVariable]
	) -> ExprSyntax {
		let genericParameters = captures.enumerated().map { index, _ in "Capture\(index)" }
		
		let captureProperties = zip(captures, genericParameters).map { name, generic in
			"\t\tlet \(name.text): \(generic)"
		}
		
		let captureInitParams = zip(captures, genericParameters).map { name, generic in
			"\(name.text): \(generic)"
		}
		
		let captureInitAssignments = captures.map { name in
			"\t\t\tself.\(name.text) = \(name.text)"
		}
		
		let environmentProperties: [String] = variables.map { variable in
			switch variable.kind {
			case .observableObject:
				"\t\t\(variable.kind.annotation) private var \(variable.name.text): \(variable.type.trimmedDescription)"
			case .observable, .unknown:
				"\t\t\(variable.kind.annotation)(\(variable.type.trimmedDescription).self) private var \(variable.name.text)"
			}
		}
		
		let initSection: String
		if captureInitParams.isEmpty {
			initSection = ""
		} else {
			initSection =
				"\t\tinit(\(captureInitParams.joined(separator: ", "))) {\n"
			+ 	captureInitAssignments.joined(separator: "\n")
			+ 	"\n\t\t}"
		}
		
		let bodyContent = content.statements.description
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.split(separator: "\n")
			.map { "\t\t\t\($0)" }
			.joined(separator: "\n")
		
		let structHeader: String
		if genericParameters.isEmpty {
			structHeader = "struct \(structName): View"
		} else {
			let generics = genericParameters.joined(separator: ", ")
			structHeader = "struct \(structName)<" + generics + ">: View"
		}
		
		let typeDefinition = [
			"\t\(structHeader) {",
			(captureProperties + environmentProperties).joined(separator: "\n"),
			initSection,
			"\t\tvar body: some View {",
			bodyContent.isEmpty ? "\t\t\tEmptyView()" : bodyContent,
			"\t\t}",
			"\t}"
		]
		.filter { !$0.isEmpty }
		.joined(separator: "\n")
		
		let callArguments = captures
			.map { "\($0.text): \($0.text)" }
			.joined(separator: ", ")
		
		let initializerCall =
			if callArguments.isEmpty {
				"\(structName)()"
			} else {
				"\(structName)(\(callArguments))"
			}
		
		let expressionSource = """
			{
			\(typeDefinition)
				return \(initializerCall)
			}()
			"""
		
		return ExprSyntax(stringLiteral: expressionSource)
	}
}

private final class CaptureCollector: SyntaxVisitor {
	var identifiers: [TokenSyntax] = []
	private var localVariables: Set<String> = []
	
	override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		/// Collect all local variable names declared in the closure/content
		for binding in node.bindings {
			if let pattern = binding.pattern.as(IdentifierPatternSyntax.self) {
				localVariables.insert(pattern.identifier.text)
			}
		}
		return .visitChildren
	}
	
	override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
		/// Filter out:
		/// - Local variables
		/// - Type names (handled by IdentifierTypeSyntax)
		/// - Enum cases or static members (if part of a MemberAccessExprSyntax)
		let name = node.baseName.text
		
		/// Skip if local variable
		if localVariables.contains(name) {
			return .skipChildren
		}
		
		/// Skip if part of a member access (likely enum case or static member)
		if let parent = node.parent, parent.is(MemberAccessExprSyntax.self) {
			return .skipChildren
		}
		identifiers.append(node.baseName)
		return .skipChildren
	}
	
	override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
		/// Skip type names
		.skipChildren
	}
}

private extension TypeSyntax {
	var trimmedDescription: String {
		description.trimmingCharacters(in: .whitespacesAndNewlines)
	}
}
