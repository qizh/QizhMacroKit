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
			let error = Diagnostic(
				node: Syntax(node),
				message: QizhMacroGeneratorDiagnostic("@CaseValue can only be applied to enums")
			)
			context.diagnose(error)
			return []
		}
		
		/*
		let members = enumDecl.memberBlock.members
		guard members.count > 0 else {
			let error = Diagnostic(
				node: Syntax(node),
				message: QizhMacroGeneratorDiagnostic("@CaseValue can only be applied to enums with cases")
			)
			context.diagnose(error)
			return []
		}
		*/
		
		let members = enumDecl.memberBlock.members
		var computedProperties: [DeclSyntax] = []
		
		let modifiers = enumDecl.modifiers.map(\.name.text)
		let modifiersString: String = modifiers.isEmpty
			? ""
			: modifiers.joined(separator: " ") + " "
		
		for member in members {
			guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
				continue
			}
			
			for element in enumCaseDecl.elements {
				let caseNameText = element.name.text
				
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
						let valueCandidate = originalType.description
						let totalSameTypeParameters = parameters
							.map(\.type.description)
							.count { $0 == valueCandidate }
						
						// print("\(caseNameText): Found \(totalSameTypeParameters) copies of \(valueCandidate) in \(parameters.map(\.type.description))")
						
						if totalSameTypeParameters <= 1 {
							parameterName = "\(raw: valueCandidate)"
							
							let info = Diagnostic(
								node: Syntax(node),
								message: QizhMacroGeneratorDiagnostic(
									"Found \(totalSameTypeParameters) copies of \(valueCandidate) in \(caseNameText) case, using \(parameterName)",
									severity: .note
								),
							)
							context.diagnose(info)
						} else {
							parameterName = "\(raw: valueCandidate)\(raw: index)"
							
							let info = Diagnostic(
								node: Syntax(node),
								message: QizhMacroGeneratorDiagnostic(
									"Found \(totalSameTypeParameters) copies of \(valueCandidate) in \(caseNameText) case, using \(parameterName)",
									severity: .note
								),
							)
							context.diagnose(info)
						}
					}
					
					/// Make output parameter `Optional`
					
					let isParameterOptional =
						originalType.as(OptionalTypeSyntax.self) != nil
					|| 	originalType.as(IdentifierTypeSyntax.self)?.name.text == "Optional"
					
					let parameterTypeName: String
					if isParameterOptional {
						parameterTypeName = originalType.description
							.trimmingCharacters(in: .whitespacesAndNewlines)
					} else {
						parameterTypeName = originalType.description
							.trimmingCharacters(in: .whitespacesAndNewlines)
							+ "?"
					}
					
					/// Use case name only when parameter name is the same
					
					let propertyName: String
					if caseNameText.localizedLowercase == parameterName.text.localizedLowercase {
						propertyName = caseNameText
						
						let info = Diagnostic(
							node: Syntax(node),
							message: QizhMacroGeneratorDiagnostic(
								"Parameter name «\(parameterName.text)» is the same as «\(caseNameText)» case name → leaving case name only",
								severity: .note
							),
						)
						context.diagnose(info)
					} else {
						propertyName = "\(caseNameText)\(parameterName.text.capitalized)"
						
						let info = Diagnostic(
							node: Syntax(node),
							message: QizhMacroGeneratorDiagnostic(
								"Parameter name «\(parameterName.text)» is different from «\(caseNameText)» case name → combining them as «\(propertyName)»",
								severity: .note
							),
						)
						context.diagnose(info)
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
