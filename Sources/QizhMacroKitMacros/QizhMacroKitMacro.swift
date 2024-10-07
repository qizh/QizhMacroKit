import SwiftCompilerPlugin
import SwiftSyntaxMacros
import SwiftSyntax
import SwiftSyntaxBuilder

import SwiftDiagnostics

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
				message: IsCasesGeneratorDiagnostic("@IsCase can only be applied to enums")
			)
			context.diagnose(error)
			return []
		}
		
		let members = enumDecl.memberBlock.members.reversed()
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

/// Custom DiagnosticMessage implementation
struct IsCasesGeneratorDiagnostic: DiagnosticMessage {
	let message: String
	let diagnosticID: MessageID
	let severity: DiagnosticSeverity

	init(_ message: String, severity: DiagnosticSeverity = .error) {
		self.message = message
		self.diagnosticID = MessageID(domain: "QizhMacroTestsMacros", id: "InvalidUsage")
		self.severity = severity
	}
}

@main
struct QizhMacroKitPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		IsCasesGenerator.self,
	]
}
