public struct CaseNameGenerator: MemberMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		
		/// Ensure the declaration is an enum
		guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
			let error = Diagnostic(
				node: Syntax(node),
				message: QizhMacroGeneratorDiagnostic("@CaseName can only be applied to enums")
			)
			context.diagnose(error)
			return []
		}
		
		let members = enumDecl.memberBlock.members
		guard members.count > 0 else {
			let error = Diagnostic(
				node: Syntax(node),
				message: QizhMacroGeneratorDiagnostic("@CaseName can only be applied to enums with cases")
			)
			context.diagnose(error)
			return []
		}
		
		let modifiers = enumDecl.modifiers.map(\.name.text).joined(separator: " ")
		
		var result: [DeclSyntax] = ["""
			\(raw: modifiers) var caseName: String {
				switch self {
			"""]
		
		for member in members {
			guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
				result.append("")
				continue
			}
			
			for element in enumCaseDecl.elements {
				let caseName = element.name.text
				result.append("""
					case .\(raw: caseName): "\(raw: caseName)" 
				""")
			}
		}
		
		result.append("""
			}
		}
		""")
		
		return result
	}
}
