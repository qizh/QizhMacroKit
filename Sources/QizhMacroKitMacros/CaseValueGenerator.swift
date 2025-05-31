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
					let parameterName = parameter.secondName ?? parameter.firstName ?? ""
					
					let parameterNameText = parameterName.text
					let parameterTypeName = parameter.type.description
					
					let propertyName = "\(caseNameText) \(parameterNameText)".toCamelCase
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
