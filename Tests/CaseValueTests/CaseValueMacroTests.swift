#if os(macOS)
import Testing
@testable import QizhMacroKit
@testable import QizhMacroKitMacros

/// Tests for the `CaseValue` macro.
@Suite("CaseValue macro")
struct CaseValueMacroTests {
	/// Ensures associated values are exposed via generated properties.
	@Test("Extracts associated values")
	func extractsAssociatedValues() {
		@CaseValue enum Token { case int(Int); case text(String) }
		let number = Token.int(8)
		#expect(number.int == 8)
		#expect(number.textString == nil)
		let word = Token.text("hi")
		#expect(word.int == nil)
		#expect(word.textString == "hi")
	}
	
	// MARK: Edge Cases
	
	@Suite("Edge cases")
	struct EdgeCases {
		/// Verifies that the `@CaseValue` macro generates property names in lower camel
		/// case, normalizing varying original case styles in enum case and parameter
		/// identifiers.
		///
		/// This test defines an enum with three stylistic variants of the same logical
		/// case:
		/// - `case foo(_ bar: Int)`
		/// - `case FOO(_ BAR: String)`
		/// - `case Foo(_ Bar: String?)`
		///
		/// It then asserts that the synthesized accessors:
		/// - share a consistent lower-camel-case base prefix derived from the case name
		///   (`foo`)
		/// - incorporate the associated value label normalized to lower camel case (`Bar`)
		/// - append unambiguous, type-informed suffixes when needed (e.g. `String`,
		///   `String1`) to avoid naming collisions across overloads/optionality
		///
		/// ## Expectations
		/// - `foo(bar: Int)` produces `fooBar` (`Int?`),
		///   while string-based accessors are `nil`.
		/// - `FOO(BAR: String)` produces `fooBarString` (`String?`),
		///   while others are `nil`.
		/// - `Foo(Bar: String?)` produces `fooBarString1` (`String??`),
		///   while others are `nil`.
		/// - Optional associated values propagate to optional accessor results,
		///   ensuring `nil` when the case or its payload does not match.
		///
		/// Overall, the test ensures case/label normalization to lower camel case and
		/// deterministic, collision-free naming for multiple associated-value variants.
		@Test("Property names are in camel case")
		func propertyNameIsInCamelCase() {
			@CaseValue enum Em {
				case foo(_ bar: Int)
				case FOO(_ BAR: String)
				case Foo(_ Bar: String?)
			}
			
			let i: Int = 42
			let s: String = "forty two"
			let v1 = Em.foo(i)
			let v2 = Em.FOO(s)
			let v3 = Em.Foo(s)
			let v4 = Em.Foo(nil)
			
			#expect(v1.fooBar == i)
			#expect(v1.fooBarString == nil)
			#expect(v1.fooBarString1 == nil)
			
			#expect(v2.fooBar == nil)
			#expect(v2.fooBarString == s)
			#expect(v2.fooBarString1 == nil)
			
			#expect(v3.fooBar == nil)
			#expect(v3.fooBarString == nil)
			#expect(v3.fooBarString1 == s)
			
			#expect(v4.fooBar == nil)
			#expect(v4.fooBarString == nil)
			#expect(v4.fooBarString1 == nil)
		}
	}
}

#endif
