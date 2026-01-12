//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum OptionSetMacroDiagnostic {
	case requiresStruct
	case requiresStringLiteral(_ name: String)
	case requiresOptionsEnum(_ name: String)
	case requiresOptionsEnumRawType
	case associatedEnumNotFound(_ typeName: String, caseName: String)
	case associatedEnumMissingCases(_ typeName: String)
}

extension OptionSetMacroDiagnostic: DiagnosticMessage {
	func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
		Diagnostic(node: Syntax(node), message: self)
	}

	var message: String {
		switch self {
		case .requiresStruct:
			"'OptionSet' macro can only be applied to a struct"
		case .requiresStringLiteral(let name):
			"'OptionSet' macro argument '\(name)' must be a string literal"
		case .requiresOptionsEnum(let name):
			"'OptionSet' macro requires nested options enum '\(name)'"
		case .requiresOptionsEnumRawType:
			"'OptionSet' macro requires a raw type"
		case .associatedEnumNotFound(let typeName, let caseName):
			"Associated type '\(typeName)' for case '\(caseName)' must be a nested enum with cases"
		case .associatedEnumMissingCases(let typeName):
			"Associated enum '\(typeName)' has no cases to generate options from"
		}
	}

	var severity: DiagnosticSeverity { .error }

	/// Required by `DiagnosticMessage` protocol.
	/// Coverage note: Called indirectly via `diagnose(at:)`, not directly testable.
	var diagnosticID: MessageID {
		MessageID(domain: "Swift", id: "OptionSet.\(self)")
	}
}

/// The label used for the OptionSet macro argument
/// that provides the name of the nested options enum.
private let optionsEnumNameArgumentLabel = "optionsName"

/// The default name used for the nested "Options" enum.
/// This should eventually be overridable.
private let defaultOptionsEnumName = "Options"

extension LabeledExprListSyntax {
	/// Retrieve the first element with the given label.
	func first(labeled name: String) -> Element? {
		first { element in
			if let label = element.label {
				label.text == name
			} else {
				false
			}
		}
	}
}

/// ✨ Line 69: Nice. ✨

/// `@OptionSet` macro generator
public struct OptionSetGenerator {
	/// Decodes the arguments to the macro expansion.
	/// - Returns: the important arguments used by the various roles of this
	///   macro inhabits, or nil if an error occurred.
	static func decodeExpansion(
		of attribute: AttributeSyntax,
		attachedTo decl: some DeclGroupSyntax,
		in context: some MacroExpansionContext,
		emitDiagnostics: Bool
	) -> (StructDeclSyntax, EnumDeclSyntax, GenericArgumentSyntax.Argument)? {
		/// Determine the name of the options enum.
		let optionsEnumName: String
		if case let .argumentList(arguments) = attribute.arguments,
		   let optionEnumNameArg = arguments.first(labeled: optionsEnumNameArgumentLabel) {
			/// We have an options name; make sure it is a string literal.
			guard let stringLiteral = optionEnumNameArg.expression.as(StringLiteralExprSyntax.self),
				  stringLiteral.segments.count == 1,
				  case let .stringSegment(optionsEnumNameString)? = stringLiteral.segments.first
			else {
				if emitDiagnostics {
					context.diagnose(
						OptionSetMacroDiagnostic.requiresStringLiteral(optionsEnumNameArgumentLabel)
							.diagnose(at: optionEnumNameArg.expression)
					)
				}
				return nil
			}

			optionsEnumName = optionsEnumNameString.content.text
		} else {
			optionsEnumName = defaultOptionsEnumName
		}

		/// Only apply to structs.
		guard let structDecl = decl.as(StructDeclSyntax.self) else {
			if emitDiagnostics {
				context.diagnose(OptionSetMacroDiagnostic.requiresStruct.diagnose(at: decl))
			}
			return nil
		}

		/// Find the option enum within the struct.
		guard let optionsEnum = decl.memberBlock.members.compactMap({ member in
			if let enumDecl = member.decl.as(EnumDeclSyntax.self),
			   enumDecl.name.text == optionsEnumName {
				enumDecl
			} else {
				nil
			}
		}).first else {
			if emitDiagnostics {
				context.diagnose(
					OptionSetMacroDiagnostic.requiresOptionsEnum(optionsEnumName).diagnose(at: decl)
				)
			}
			return nil
		}

		/// Retrieve the raw type from the attribute.
		guard let genericArgs = attribute.attributeName.as(IdentifierTypeSyntax.self)?
													   .genericArgumentClause,
			  let rawType = genericArgs.arguments.first?.argument
		else {
			if emitDiagnostics {
				context.diagnose(
					OptionSetMacroDiagnostic.requiresOptionsEnumRawType.diagnose(at: attribute)
				)
			}
			return nil
		}
		
		return (structDecl, optionsEnum, rawType)
	}
}

extension OptionSetGenerator: ExtensionMacro {
	public static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [ExtensionDeclSyntax] {
		/// Decode the expansion arguments.
		guard let (structDecl, _, _) = decodeExpansion(
			of: node,
			attachedTo: declaration,
			in: context,
			emitDiagnostics: false
		) else {
			return []
		}
		
		/// If there is an explicit conformance to OptionSet already, don't add one.
		if let inheritedTypes = structDecl.inheritanceClause?.inheritedTypes,
		   inheritedTypes.contains(where: { inherited in
			   inherited.type.trimmedDescription == "OptionSet"
		   }) {
			return []
		}
		
		return [try ExtensionDeclSyntax("extension \(type): OptionSet {}")]
	}
}

extension OptionSetGenerator: MemberMacro {
	public static func expansion(
		of attribute: AttributeSyntax,
		providingMembersOf decl: some DeclGroupSyntax,
		conformingTo: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		/// Decode the expansion arguments.
		guard let (structDecl, optionsEnum, rawType) = decodeExpansion(
			of: attribute,
			attachedTo: decl,
			in: context,
			emitDiagnostics: true
		) else {
			return []
		}

		/// Find all of the case elements.
		let caseElements: [EnumCaseElementSyntax] = optionsEnum.memberBlock.members
			.flatMap { member in
				guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
					return [EnumCaseElementSyntax]()
				}

				return Array(caseDecl.elements)
			}

		/// Dig out the access control keyword we need.
		let access = decl.modifiers.first(where: \.isNeededAccessLevelModifier)
		
		/// Collect all nested enums in the struct for associated value resolution.
		let nestedEnums = collectNestedEnums(from: structDecl)

		/// Generate static properties for each case element.
		var staticVars: [DeclSyntax] = []
		var bitIndex = 0
		
		for element in caseElements {
			let generatedProperties = generateStaticProperties(
				for: element,
				in: optionsEnum,
				nestedEnums: nestedEnums,
				access: access,
				bitIndex: &bitIndex,
				context: context
			)
			staticVars.append(contentsOf: generatedProperties)
		}

		return [
			"\(access)typealias RawValue = \(rawType)",
			"\(access)var rawValue: RawValue",
			"\(access)init() { self.rawValue = 0 }",
			"\(access)init(rawValue: RawValue) { self.rawValue = rawValue }",
		] + staticVars
	}
	
	// MARK: - Associated Enum Value Support
	
	/// Collects all nested enum declarations from a struct.
	///
	/// Used to resolve associated value types that reference nested enums.
	/// Only enums with case declarations are included.
	///
	/// - Parameter structDecl: The struct declaration to search.
	/// - Returns: Dictionary mapping enum names to their case elements.
	private static func collectNestedEnums(
		from structDecl: StructDeclSyntax
	) -> [String: [EnumCaseElementSyntax]] {
		var result: [String: [EnumCaseElementSyntax]] = [:]
		
		for member in structDecl.memberBlock.members {
			guard let enumDecl = member.decl.as(EnumDeclSyntax.self) else {
				continue
			}
			
			let cases = enumDecl.memberBlock.members.flatMap { member in
				guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
					return [EnumCaseElementSyntax]()
				}
				return Array(caseDecl.elements)
			}
			
			if !cases.isEmpty {
				result[enumDecl.name.text] = cases
			}
		}
		
		return result
	}
	
	/// Generates static properties for an Options enum case element.
	///
	/// For simple cases (no associated values), generates a single static property.
	/// For cases with associated enum values, generates a static property for each
	/// case of the associated enum type.
	///
	/// - Parameters:
	///   - element: The enum case element to process.
	///   - optionsEnum: The Options enum declaration.
	///   - nestedEnums: Dictionary of nested enums and their cases.
	///   - access: The access modifier to apply.
	///   - bitIndex: Current bit index, incremented for each generated property.
	///   - context: Macro expansion context for diagnostics.
	/// - Returns: Array of generated static property declarations.
	private static func generateStaticProperties(
		for element: EnumCaseElementSyntax,
		in optionsEnum: EnumDeclSyntax,
		nestedEnums: [String: [EnumCaseElementSyntax]],
		access: DeclModifierSyntax?,
		bitIndex: inout Int,
		context: some MacroExpansionContext
	) -> [DeclSyntax] {
		/// Check if this case has associated values.
		guard let parameterClause = element.parameterClause,
			  let firstParam = parameterClause.parameters.first else {
			/// Simple case without associated values - use original behavior.
			let decl: DeclSyntax = """
				\(access) static let \(element.name): Self =
					Self(rawValue: 1 << \(optionsEnum.name).\(element.name).rawValue)
				"""
			bitIndex += 1
			return [decl]
		}
		
		/// Extract the type name from the parameter.
		let typeName = firstParam.type.trimmedDescription
		
		/// Look up the type in nested enums.
		guard let enumCases = nestedEnums[typeName] else {
			/// Not a nested enum - fall back to simple case generation.
			/// This handles external types or non-enum associated values.
			let decl: DeclSyntax = """
				\(access) static let \(element.name): Self =
					Self(rawValue: 1 << \(raw: bitIndex))
				"""
			bitIndex += 1
			return [decl]
		}
		
		/// Generate a static property for each case of the associated enum.
		var properties: [DeclSyntax] = []
		let baseName = element.name.text
		
		for enumCase in enumCases {
			let caseName = enumCase.name.text
			/// Combine names: "level" + "High" -> "levelHigh"
			let combinedName = baseName + caseName.capitalizingFirstLetter()
			
			let decl: DeclSyntax = """
				\(access) static let \(raw: combinedName): Self =
					Self(rawValue: 1 << \(raw: bitIndex))
				"""
			properties.append(decl)
			bitIndex += 1
		}
		
		return properties
	}
}

extension DeclModifierSyntax {
	/// Determines if this modifier is an access level keyword that should be preserved
	/// in generated `OptionSet` members.
	///
	/// Supported access levels: `public`, `open`, `package`, `internal`, `fileprivate`.
	/// Private access is excluded as generated static members need broader visibility.
	var isNeededAccessLevelModifier: Bool {
		switch self.name.tokenKind {
		case .keyword(.public),
			 .keyword(.fileprivate),
			 .keyword(.package),
			 .keyword(.internal),
			 .keyword(.open): 		true
		default: 					false
		}
	}
}
