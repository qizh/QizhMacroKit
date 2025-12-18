#if os(macOS)
import Testing
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import QizhMacroKit
@testable import QizhMacroKitMacros

/// Tests for the `CaseValue` macro.
@Suite("CaseValue macro")
struct CaseValueMacroTests {
	private let macros: [String: any Macro.Type] = [
		"CaseValue": CaseValueGenerator.self
	]
	
	// MARK: - Runtime Tests
	
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
	
	/// Tests multiple parameters in a single case.
	@Test("Extracts multiple parameters")
	func extractsMultipleParameters() {
		@CaseValue enum Point { case xy(x: Int, y: Int) }
		let p = Point.xy(x: 10, y: 20)
		#expect(p.xyX == 10)
		#expect(p.xyY == 20)
	}
	
	/// Tests optional associated values.
	@Test("Handles optional associated values")
	func handlesOptionalValues() {
		@CaseValue enum Container { case value(Int?), empty }
		let withValue = Container.value(42)
		let withNil = Container.value(nil)
		let empty = Container.empty
		#expect(withValue.valueInt == 42)
		#expect(withNil.valueInt == nil)
		#expect(empty.valueInt == nil)
	}
	
	/// Tests function type parameters.
	@Test("Handles function type parameters")
	func handlesFunctionTypes() {
		@CaseValue enum Handler { case action(handler: () -> Void) }
		var called = false
		let h = Handler.action { called = true }
		if let action = h.actionHandler {
			action()
		}
		#expect(called)
	}
	
	/// Tests cases without associated values are skipped.
	@Test("Skips cases without associated values")
	func skipsCasesWithoutValues() {
		@CaseValue enum Mixed { case withValue(value: Int), withoutValue }
		let v = Mixed.withValue(value: 5)
		#expect(v.withValueValue == 5)
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
		
		/// Tests parameters with same type get indexed suffixes.
		@Test("Multiple same-type unnamed parameters get indexed")
		func multipleSameTypeUnnamedParameters() {
			@CaseValue enum Pair { case values(Int, Int) }
			let p = Pair.values(1, 2)
			#expect(p.valuesInt0 == 1)
			#expect(p.valuesInt1 == 2)
		}
	}
	
	// MARK: - Expansion Tests
	
	@Suite("Expansion tests")
	struct ExpansionTests {
		private let macros: [String: any Macro.Type] = [
			"CaseValue": CaseValueGenerator.self
		]
		
		/// Tests that applying to a struct produces an error.
		@Test("Fails when applied to struct")
		func failsOnStruct() {
			assertMacroExpansion(
				"""
				@CaseValue
				struct NotAnEnum { var x: Int }
				""",
				expandedSource: """
				struct NotAnEnum { var x: Int }
				""",
				diagnostics: [
					DiagnosticSpec(
						message: "@CaseValue can only be applied to enums",
						line: 1,
						column: 1,
						severity: .error
					)
				],
				macros: macros
			)
		}
		
		/// Tests expansion respects access modifiers.
		@Test("Expansion respects public access modifier")
		func expansionRespectsPublicAccess() {
			assertMacroExpansion(
				"""
				@CaseValue
				public enum Token { case value(Int) }
				""",
				expandedSource: """
				public enum Token { case value(Int)
					/// `Int?` value of `Int` parameter in `.value` case.
					public var value: Int? {
						switch self {
						case .value(let value): value
						default: nil
						}
					}}
				""",
				macros: macros
			)
		}
	}
}

#endif
