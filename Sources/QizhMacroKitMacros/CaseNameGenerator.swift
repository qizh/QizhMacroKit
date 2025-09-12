//
//  CaseNameGenerator.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 08.10.2024.
//

public struct CaseNameGenerator: MemberMacro {
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
				message: QizhMacroGeneratorDiagnostic(
					message: "@CaseName can only be applied to enums",
					id: .invalidUsage,
					severity: .error
				)
			)
			context.diagnose(error)
			return []
		}
		
		let members = enumDecl.memberBlock.members
		guard members.count > 0 else {
			let error = Diagnostic(
				node: Syntax(node),
				message: QizhMacroGeneratorDiagnostic(
					message: "@CaseName can only be applied to enums with cases",
					id: .invalidUsage,
					severity: .error
				)
			)
			context.diagnose(error)
			return []
		}
		
		let allModifiers = enumDecl.modifiers.map(\.name.text)
		let accessControlSet: Set<String> = ["open", "public", "package", "internal", "fileprivate", "private"]
		let accessModifiers = allModifiers.filter { accessControlSet.contains($0) }
		let modifiersString: String = accessModifiers.isEmpty
			? ""
			: accessModifiers.joined(separator: " ") + " "
		
		var resultString: String = "\(modifiersString)var caseName: String { switch self {"
		
		for member in members {
			guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
				continue
			}
			
			for element in enumCaseDecl.elements {
				let caseName = element.name.text.withBackticksTrimmed
				resultString += "\ncase .\(caseName): \"\(caseName)\""
			}
		}
		
		resultString += "}}"
		
		return ["\(raw: resultString)"]
	}
}

