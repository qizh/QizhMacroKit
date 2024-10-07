//
//  IsCasesGenerator.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 08.10.2024.
//


public struct IsCasesGenerator: MemberMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		
		/// Ensure the declaration is an enum
		guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
			let error = Diagnostic(
				node: Syntax(node),
				message: QizhMacroGeneratorDiagnostic("@IsCase can only be applied to enums")
			)
			context.diagnose(error)
			return []
		}
		
		let members = enumDecl.memberBlock.members
		var computedProperties: [DeclSyntax] = []
		
		let modifiers = enumDecl.modifiers.map(\.name.text).joined(separator: " ")
		
		/// Iterate over each case in the enum
		for member in members {
			guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
				computedProperties.append("")
				continue
			}
			
			for element in enumCaseDecl.elements {
				let caseName = element.name.text
				let propertyName = "is\(caseName.prefix(1).uppercased())\(caseName.dropFirst())"
				
				let property: DeclSyntax = """
				\(raw: modifiers) var \(raw: propertyName): Bool {
					switch self {
					case .\(raw: caseName): true
					default: false
					}
				}
				"""
				computedProperties.append(property)
			}
		}
		return computedProperties
	}
}
