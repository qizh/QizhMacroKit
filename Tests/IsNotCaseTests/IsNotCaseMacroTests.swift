#if os(macOS)
import Testing
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import QizhMacroKit
@testable import QizhMacroKitMacros

/// Tests for the `IsNotCase` macro.
@Suite("IsNotCase macro")
struct IsNotCaseMacroTests {
	private let macros: [String: any Macro.Type] = [
		"IsNotCase": IsNotCasesGenerator.self
	]
	
	// MARK: - Runtime Tests
	
	/// Ensures generated properties negate case checks.
	@Test("Generated properties are negated")
	func generatedPropertiesAreNegated() {
		@IsNotCase enum Direction { case left, right }
		let dir = Direction.left
		#expect(!dir.isNotLeft)
		#expect(dir.isNotRight)
	}
	
	/// Tests with multiple cases.
	@Test("Works with multiple cases")
	func worksWithMultipleCases() {
		@IsNotCase enum Status { case pending, active, completed, cancelled }
		let status = Status.active
		#expect(status.isNotPending)
		#expect(!status.isNotActive)
		#expect(status.isNotCompleted)
		#expect(status.isNotCancelled)
	}
	
	/// Tests with associated values.
	@Test("Works with associated values")
	func worksWithAssociatedValues() {
		@IsNotCase enum Result { case success(Int), failure(String) }
		let result = Result.success(42)
		#expect(!result.isNotSuccess)
		#expect(result.isNotFailure)
	}
	
	/// Tests with backtick-escaped keywords.
	@Test("Handles backtick-escaped keywords")
	func handlesBacktickKeywords() {
		@IsNotCase enum Keywords { case `default`, `class`, normal }
		let kw = Keywords.default
		#expect(!kw.isNotDefault)
		#expect(kw.isNotClass)
		#expect(kw.isNotNormal)
	}
	
	// MARK: - Expansion Tests
	
	/// Tests macro expansion generates correct switch statement.
	@Test("Expansion generates correct switch")
	func expansionGeneratesCorrectSwitch() {
		assertMacroExpansion(
			"""
			@IsNotCase
			enum Direction { case left, right }
			""",
			expandedSource: """
			enum Direction { case left, right
				var isNotLeft: Bool {
					switch self {
					case .left: false
					default: true
					}
				}
				var isNotRight: Bool {
					switch self {
					case .right: false
					default: true
					}
				}}
			""",
			macros: macros
		)
	}
	
	/// Tests macro expansion respects public access modifier.
	@Test("Expansion respects public access modifier")
	func expansionRespectsPublicAccess() {
		assertMacroExpansion(
			"""
			@IsNotCase
			public enum Status { case on }
			""",
			expandedSource: """
			public enum Status { case on
				public var isNotOn: Bool {
					switch self {
					case .on: false
					default: true
					}
				}}
			""",
			macros: macros
		)
	}
	
	/// Tests macro expansion respects private access modifier.
	@Test("Expansion respects private access modifier")
	func expansionRespectsPrivateAccess() {
		assertMacroExpansion(
			"""
			@IsNotCase
			private enum Status { case on }
			""",
			expandedSource: """
			private enum Status { case on
				private var isNotOn: Bool {
					switch self {
					case .on: false
					default: true
					}
				}}
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
			@IsNotCase
			struct NotAnEnum { var x: Int }
			""",
			expandedSource: """
			struct NotAnEnum { var x: Int }
			""",
			diagnostics: [
				DiagnosticSpec(
					message: "@IsNotCase can only be applied to enums",
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
			@IsNotCase
			class NotAnEnum {}
			""",
			expandedSource: """
			class NotAnEnum {}
			""",
			diagnostics: [
				DiagnosticSpec(
					message: "@IsNotCase can only be applied to enums",
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
