import Testing
import QizhMacroKit
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import SwiftSyntaxMacrosGenericTestSupport
import QizhMacroKitMacros

/// Tests for compile-time and runtime `stringify` and `dictionarify` macros.
@Suite("Stringify macros")
struct StringifyMacroTests {
	/// Macro implementations under test.
	let macros: [String: any Macro.Type] = [
		"stringify": StringifyGenerator.self,
		"dictionarify": DictionarifyGenerator.self,
	]

	// MARK: - Compile-time tests

	/// Ensures `stringify` yields only the source text.
	@Test("stringify yields only the source")
	func stringifyExprYieldsSource() {
		assertMacroExpansion(
			#"""
			let a = 4
			let s = #stringify(a * (1 + 2))
			"""#,
			expandedSource:
			#"""
			let a = 4
			let s = "a * (1 + 2)"
			"""#,
			macros: macros
		)
	}

	/// Ensures `dictionarify` returns both key and value.
	@Test("dictionarify expands to a key-value pair")
	func dictionarifyExprYieldsPair() {
		assertMacroExpansion(
			#"""
			let pair = #dictionarify(2 * 3)
			"""#,
			expandedSource:
			#"""
			let pair = (key: "2 * 3", value: 2 * 3)
			"""#,
			macros: macros
		)
	}

	/// Produces a diagnostic when `stringify` is called without arguments.
	@Test("diagnostic when called without arguments")
	func stringifyErrorsOnNoArgs() {
		assertMacroExpansion(
			#"#stringify()"#,
			expandedSource: #"#stringify()"#,
			diagnostics: [
				DiagnosticSpec(
					message: "Stringify requires one argument",
					line: 1,
					column: 1,
					severity: .error
				)
			],
			macros: macros
		)
	}

	// MARK: - Runtime tests

	/// Ensures that `stringify` returns the source of the expression.
	@Test("`stringify` returns source text")
	func stringifyReturnsSource() {
		let number = 5
		#expect(#stringify(number + 1) == "number + 1")
	}

	/// Ensures that `dictionarify` produces a key-value pair.
	@Test("`dictionarify` produces a pair")
	func dictionarifyProducesPair() {
		let pair = #dictionarify(2 * 3)
		#expect(pair.key == "2 * 3")
		#expect(pair.value == 6)
	}
}

