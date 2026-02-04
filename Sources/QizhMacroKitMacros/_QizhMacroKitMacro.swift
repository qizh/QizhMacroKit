import SwiftCompilerPlugin
import SwiftSyntaxMacros
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftDiagnostics

/// The main compiler plugin entry point for QizhMacroKit.
///
/// This plugin registers all available macro implementations with the Swift compiler.
/// The plugin is executed at compile-time to expand macro invocations in consuming projects.
///
/// ## Registered Macros
///
/// - ``IsCasesGenerator``: Implements `@IsCase` macro
/// - ``IsNotCasesGenerator``: Implements `@IsNotCase` macro
/// - ``CaseNameGenerator``: Implements `@CaseName` macro
/// - ``CaseValueGenerator``: Implements `@CaseValue` macro
/// - ``StringifyGenerator``: Implements `#stringify` macro
/// - ``DictionarifyGenerator``: Implements `#dictionarify` macro
/// - ``OptionSetGenerator``: Implements `@OptionSet` macro
///
/// - Note: This struct cannot be tested directly as it is invoked by the Swift compiler.
///   Test coverage for macro implementations is provided through their respective generator tests.
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
