import Testing
import QizhMacroKit
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import SwiftSyntaxMacrosGenericTestSupport
import QizhMacroKitMacros
import OrderedCollections

/// Tests for the ``Labeled`` macro.
@Suite("Labeled macro")
struct LabeledMacroTests {
	/// Macro implementations under test.
	let macros: [String: any Macro.Type] = [
		"Labeled": LabeledGenerator.self,
	]
	
	/// Ensures the array expands to an ``OrderedDictionary``.
	@Test("expands array to OrderedDictionary")
	func expandsToOrderedDictionary() {
		assertMacroExpansion(
			#"""
			@Labeled
			let names = [
			firstName,
			lastName,
			]
			"""#,
			expandedSource:
			#"""
			let names: OrderedDictionary = [
			"firstName": firstName,
			"lastName": lastName,
			]
			"""#,
			macros: macros
		)
	}
	
	/// Uses the macro at runtime.
	@Test("runtime dictionary")
	func runtimeDictionary() {
		let firstName = "Serhii"
		let lastName = "Shevchenko"
		@Labeled let dict = [
			firstName,
			lastName,
		]
		#expect(dict.keys.first == "firstName")
		#expect(dict["lastName"] == lastName)
	}
}

