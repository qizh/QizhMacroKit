//
//  CaseValueGenerator.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 31.05.2025.
//

public struct CaseValueGenerator: MemberMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		/// Ensure the declaration is an enum
		guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
			context.diagnose(
				.error(
					node: Syntax(node),
					message: "@CaseValue can only be applied to enums",
					id: "InvalidDeclarationApplication"
				)
			)
			return []
		}
		
		let members = enumDecl.memberBlock.members
		var computedProperties: [DeclSyntax] = []
		
		let allModifiers = enumDecl.modifiers.map(\.name.text)
		let accessControlSet: Set<String> = ["open", "public", "package", "internal", "fileprivate", "private"]
		let accessModifiers = allModifiers.filter { accessControlSet.contains($0) }
		let modifiersString: String = accessModifiers.isEmpty
			? ""
			: accessModifiers.joined(separator: " ") + " "
		
		for member in members {
			guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
				continue
			}
			
			for element in enumCaseDecl.elements {
				let caseNameText = element.name.text.withBackticksTrimmed
				
				guard let parameters = element.parameterClause?.parameters else { continue }
				
				let totalParameters = parameters.count
				
				for (index, parameter) in parameters.enumerated() {
					let originalType = parameter.type
					
					/// Generate parameter name
					
					let parameterName: TokenSyntax
					if let value = parameter.secondName {
						parameterName = value
					} else if let value = parameter.firstName {
						parameterName = value
					} else {
						
						/// No parameter name, using parameter type
						
						let valueCandidate = originalType.description
						let totalSameTypeParameters = parameters
							.map(\.type.description)
							.count { $0 == valueCandidate }
						
						if totalSameTypeParameters <= 1 {
							parameterName = "\(raw: valueCandidate)"
							
							/*
							context.diagnose(
								.note(
									node: Syntax(node),
									message: "Single «\(valueCandidate)» parameter in «\(caseNameText)» case → using «\(parameterName)»",
									id: "SingleParameterType"
								)
							)
							*/
						} else {
							parameterName = "\(raw: valueCandidate)\(raw: index)"
							
							context.diagnose(
								.note(
									node: Syntax(node),
									message: "Found \(totalSameTypeParameters) copies of «\(valueCandidate)» in «\(caseNameText)» case → adding index → using «\(parameterName)»",
									id: "MultipleSameParameterTypes"
								)
							)
						}
					}
					
					/// Make output parameter `Optional`
					
					var parameterTypeName: String = originalType.description
						.trimmingCharacters(in: .whitespacesAndNewlines)
					
					if originalType.as(FunctionTypeSyntax.self) != nil {
						context.diagnose(
							.note(
								node: Syntax(node),
								message: "Found parameter of function type «\(originalType)»: \(parameterTypeName)",
								id: "FunctionParameterType"
							)
						)
						
						parameterTypeName = "(\(parameterTypeName))"
					}
					
					let isParameterOptional =
						originalType.as(OptionalTypeSyntax.self) != nil
					|| 	originalType.as(IdentifierTypeSyntax.self)?.name.text == "Optional"
					
					if !isParameterOptional {
						parameterTypeName = "\(parameterTypeName)?"
					}
					
					/// Use case name only when parameter name is the same
					
					let propertyName: String
					if caseNameText.localizedLowercase == parameterName.text.localizedLowercase {
						propertyName = caseNameText
						
						context.diagnose(
							.note(
								node: Syntax(node),
								message: "Parameter name «\(parameterName.text)» is the same as «\(caseNameText)» case name → leaving case name only",
								id: "SameParameterNameAsCaseName"
							)
						)
					} else {
						propertyName = "\(caseNameText)\(parameterName.text)".toCamelCase
						
						/*
						context.diagnose(
							.note(
								node: Syntax(node),
								message: "Parameter name «\(parameterName.text)» is different from «\(caseNameText)» case name → combining them as «\(propertyName)»",
								id: "DifferentParameterNameAndCaseName"
							)
						)
						*/
					}
					
					/// Output generation
					
					let parametersList = parametersString(for: index, of: totalParameters)
					
					let addedProperty: DeclSyntax = """
						\(raw: modifiersString)var \(raw: propertyName): \(raw: parameterTypeName) {
							switch self {
							case .\(raw: caseNameText)(\(raw: parametersList)): \(raw: Self.defaultValueName)
							default: nil
							}
						}
						"""
					
					computedProperties.append(addedProperty)
				}
			}
		}
		
		return computedProperties
	}
	
	fileprivate static let defaultValueName: String = "value"
	
	fileprivate static func parametersString(
		for index: Int,
		of total: Int,
		name: String = Self.defaultValueName
	) -> String {
		var parts: [String] = .init(repeating: "_", count: total)
		parts[index] = "let \(name)"
		return parts.joined(separator: ", ")
	}
}
