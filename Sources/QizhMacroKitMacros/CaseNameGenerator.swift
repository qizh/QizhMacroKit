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
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		
		// Ensure the declaration is an enum
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
		
		// Parse the attribute argument for snakeCase (default is false)
		var snakeCase = false
		if let argumentList = node.arguments?.as(LabeledExprListSyntax.self) {
			for element in argumentList {
				if let label = element.label {
					if label.text == "snakeCase" {
						if let boolExpr = element.expression.as(BooleanLiteralExprSyntax.self) {
							snakeCase = boolExpr.literal.text == "true"
						} else {
							let error = Diagnostic(
								node: Syntax(element.expression),
								message: QizhMacroGeneratorDiagnostic("Expected boolean literal for 'snakeCase' parameter")
							)
							context.diagnose(error)
						}
					} else {
						// Unexpected parameter label found
						let error = Diagnostic(
							node: Syntax(element),
							message: QizhMacroGeneratorDiagnostic("Unexpected parameter: '\(label.text)'")
						)
						context.diagnose(error)
					}
				} else {
					// No label provided: also an error in this context
					let error = Diagnostic(
						node: Syntax(element),
						message: QizhMacroGeneratorDiagnostic("Expected a label for the parameter")
					)
					context.diagnose(error)
				}
			}
		}
		
		// Helper function to convert CamelCase to snake_case
		func toSnakeCase(_ input: String) -> String {
			var result = ""
			for char in input {
				if char.isUppercase {
					if !result.isEmpty { result.append("_") }
					result.append(char.lowercased())
				} else {
					result.append(char)
				}
			}
			return result
		}
		
		let modifiers = enumDecl.modifiers.map(\.name.text)
		let modifiersString: String = modifiers.isEmpty ? "" : modifiers.joined(separator: " ") + " "
		
		var result: [DeclSyntax] = ["""
			\(raw: modifiersString)var caseName: String {
				switch self {
			"""]
		
		for member in members {
			guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
				continue
			}
			
			for element in enumCaseDecl.elements {
				let caseName = element.name.text
				let computedName = snakeCase ? toSnakeCase(caseName) : caseName
				result.append("""
					case .\(raw: caseName): "\(raw: computedName)"
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
