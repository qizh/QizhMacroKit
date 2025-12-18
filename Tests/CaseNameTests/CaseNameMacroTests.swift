#if os(macOS)
import Testing
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import QizhMacroKit
@testable import QizhMacroKitMacros

/// Tests for the `CaseName` macro.
@Suite("CaseName macro")
struct CaseNameMacroTests {
	private let macros: [String: any Macro.Type] = [
		"CaseName": CaseNameGenerator.self
	]
	
	// MARK: - Runtime Tests
	
	/// Ensures the generated `caseName` reflects the case.
	@Test("`caseName` matches the case")
	func caseNameMatchesCase() {
		@CaseName enum Status { case ready, running }
		let state = Status.running
		#expect(state.caseName == "running")
	}
	
	/// Tests caseName with multiple cases.
	@Test("`caseName` works with multiple cases")
	func caseNameMultipleCases() {
		@CaseName enum Direction { case north, south, east, west }
		#expect(Direction.north.caseName == "north")
		#expect(Direction.south.caseName == "south")
		#expect(Direction.east.caseName == "east")
		#expect(Direction.west.caseName == "west")
	}
	
	/// Tests caseName with associated values.
	@Test("`caseName` works with associated values")
	func caseNameWithAssociatedValues() {
		@CaseName enum Result { case success(Int), failure(String) }
		#expect(Result.success(42).caseName == "success")
		#expect(Result.failure("error").caseName == "failure")
	}
	
	/// Tests caseName with backtick-escaped case names.
	@Test("`caseName` handles backtick-escaped keywords")
	func caseNameWithBackticks() {
		@CaseName enum Keywords { case `default`, `case`, normal }
		#expect(Keywords.default.caseName == "default")
		#expect(Keywords.case.caseName == "case")
		#expect(Keywords.normal.caseName == "normal")
	}
	
	// MARK: - Expansion Tests
	
	/// Tests macro expansion generates correct switch statement.
	@Test("Expansion generates correct switch")
	func expansionGeneratesCorrectSwitch() {
		assertMacroExpansion(
			"""
			@CaseName
			enum Status { case ready, running }
			""",
			expandedSource: """
			enum Status { case ready, running
				var caseName: String { switch self {
				case .ready: "ready"
				case .running: "running"}}}
			""",
			macros: macros
		)
	}
	
	/// Tests macro expansion respects public access modifier.
	@Test("Expansion respects public access modifier")
	func expansionRespectsPublicAccess() {
		assertMacroExpansion(
			"""
			@CaseName
			public enum Status { case on, off }
			""",
			expandedSource: """
			public enum Status { case on, off
				public var caseName: String { switch self {
				case .on: "on"
				case .off: "off"}}}
			""",
			macros: macros
		)
	}
	
	/// Tests macro expansion respects private access modifier.
	@Test("Expansion respects private access modifier")
	func expansionRespectsPrivateAccess() {
		assertMacroExpansion(
			"""
			@CaseName
			private enum Status { case on }
			""",
			expandedSource: """
			private enum Status { case on
				private var caseName: String { switch self {
				case .on: "on"}}}
			""",
			macros: macros
		)
	}
	
	// MARK: - Error Cases
	
	/// Tests that applying to a struct produces an error.
	@Test("Fails when applied to struct")
	func failsOnStruct() {
		assertMacroExpansion(
			"""
			@CaseName
			struct NotAnEnum { var x: Int }
			""",
			expandedSource: """
			struct NotAnEnum { var x: Int }
			""",
			diagnostics: [
				DiagnosticSpec(
					message: "@CaseName can only be applied to enums",
					line: 1,
					column: 1,
					severity: .error
				)
			],
			macros: macros
		)
	}
	
	/// Tests that applying to a class produces an error.
	@Test("Fails when applied to class")
	func failsOnClass() {
		assertMacroExpansion(
			"""
			@CaseName
			class NotAnEnum {}
			""",
			expandedSource: """
			class NotAnEnum {}
			""",
			diagnostics: [
				DiagnosticSpec(
					message: "@CaseName can only be applied to enums",
					line: 1,
					column: 1,
					severity: .error
				)
			],
			macros: macros
		)
	}
	
	/// Tests that applying to an empty enum produces an error.
	@Test("Fails when applied to empty enum")
	func failsOnEmptyEnum() {
		assertMacroExpansion(
			"""
			@CaseName
			enum Empty {}
			""",
			expandedSource: """
			enum Empty {}
			""",
			diagnostics: [
				DiagnosticSpec(
					message: "@CaseName can only be applied to enums with cases",
					line: 1,
					column: 1,
					severity: .error
				)
			],
			macros: macros
		)
	}
}
#endif
