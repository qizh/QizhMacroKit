//
//  IsNotCasesGenerator.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 06.02.2025.
//

public struct IsNotCasesGenerator: MemberMacro {
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
				message: QizhMacroGeneratorDiagnostic("@IsNotCase can only be applied to enums")
			)
			context.diagnose(error)
			return []
		}
		
		let members = enumDecl.memberBlock.members
		var computedProperties: [DeclSyntax] = []
		
		let modifiers = enumDecl.modifiers
			.map(\.name.text)
		
		let modifiersString: String = modifiers.isEmpty ? "" : modifiers.joined(separator: " ") + " "
		
		/// Iterate over each case in the enum
		for member in members {
			guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
				continue
			}
			
			for element in enumCaseDecl.elements {
				let caseName = element.name.text.withBackticksTrimmed
				let propertyName = "isNot\(caseName.prefix(1).uppercased())\(caseName.dropFirst())"
				
				let property: DeclSyntax = """
				\(raw: modifiersString)var \(raw: propertyName): Bool {
					switch self {
					case .\(raw: caseName): false
					default: true
					}
				}
				"""
				computedProperties.append(property)
			}
		}
		return computedProperties
	}
}
