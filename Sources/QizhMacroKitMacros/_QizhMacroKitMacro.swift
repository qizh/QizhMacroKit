import SwiftCompilerPlugin
import SwiftSyntaxMacros
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftDiagnostics

@main
struct QizhMacroKitPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		IsCasesGenerator.self,
		IsNotCasesGenerator.self,
		CaseNameGenerator.self,
		CaseValueGenerator.self,
		StringifyGenerator.self,
		DictionarifyGenerator.self,
		OptionSetGenerator.self,
	]
}
