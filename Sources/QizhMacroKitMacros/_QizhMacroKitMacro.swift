@_exported import SwiftCompilerPlugin
@_exported import SwiftSyntaxMacros
@_exported import SwiftSyntax
@_exported import SwiftSyntaxBuilder
@_exported import SwiftDiagnostics

@main
struct QizhMacroKitPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		IsCasesGenerator.self,
		IsNotCasesGenerator.self,
		CaseNameGenerator.self,
	]
}
