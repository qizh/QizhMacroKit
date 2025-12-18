#if os(macOS)
import Testing
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import QizhMacroKit
@testable import QizhMacroKitMacros

/// Tests for the `IsCase` macro.
@Suite("IsCase macro")
struct IsCaseMacroTests {
	/// Ensures generated `isX` properties exist for each case.
	@Test("Generated properties")
	func generatedProperties() {
		@IsCase enum TestEnum {
			case first
			case second(Int)
			case third(String)
		}

		let value1 = TestEnum.first
		#expect(value1.isFirst)
		#expect(!value1.isSecond)
		#expect(!value1.isThird)

		let value2 = TestEnum.second(42)
		#expect(!value2.isFirst)
		#expect(value2.isSecond)
		#expect(!value2.isThird)

		let value3 = TestEnum.third("Hello")
		#expect(!value3.isFirst)
		#expect(!value3.isSecond)
		#expect(value3.isThird)
	}

	/// Ensures membership helpers work.
	@Test("Case membership functions")
	func caseMembership() {
		@IsCase enum Actions {
			case setup(api: String)
			case update
			case cache
			case export(target: String)
			case `import`(String)
			case sync
			case process
		}

		let nextAction: Actions = .sync
		#expect(nextAction.isAmong([.setup, .update, .sync]))
		#expect(!nextAction.isAmong(.export, .import))
	}

	/// Ensures uppercase Swift keywords are escaped.
	@Test("Escapes uppercase Swift keywords")
	func escapesUppercaseSwiftKeywords() {
		@IsCase enum Keywords {
			case `Self`
			case value
		}

		let keyword: Keywords = .Self
		#expect(keyword.isSelf)
		#expect(!keyword.isValue)
		#expect(keyword.isAmong(.`Self`))
	}

	/// Ensures reserved keywords can be used as case names.
	@Test("Handles reserved keyword case names")
	func handlesReservedKeywords() {
		@IsCase enum Tokens {
			case `class`
			case `struct`
			case `enum`
		}

		let token = Tokens.class
		#expect(token.isClass)
		#expect(!token.isStruct)
		#expect(!token.isEnum)
		#expect(token.isAmong(.class, .struct))
	}

	/// Verifies generated members respect access modifiers.
	@Test("Respects access modifiers")
	func respectsAccessModifiers() {
		assertMacroExpansion(
			#"""
			@IsCase
			public enum PublicStatus { case on }
			"""#,
			expandedSource:
			#"""
			public enum PublicStatus {
				case on
				/// Always return `true` because `self` has just `.on` case.
				public var isOn: Bool {
					true
				}
				/// A parameterless representation of `PublicStatus` cases.
				public enum Cases: Equatable, CaseIterable {
					case on
				}
				/// A parameterless representation of this case.
				public var parametersErasedCase: Cases {
					switch self {
					case .on: .on
					}
				}
				/// Returns `true` if `self` matches any case in `cases`.
				/// - Parameter cases: An array of cases to match against.
				public func isAmong(_ cases: [Cases]) -> Bool {
					cases.contains(self.parametersErasedCase)
				}
				/// Returns `true` if `self` matches any of the provided cases.
				/// - Parameter cases: The cases to match against.
				public func isAmong(_ cases: Cases...) -> Bool {
					isAmong(cases)
				}
			}
			"""#,
			macros: ["IsCase": QizhMacroKitMacros.IsCasesGenerator.self]
		)

		assertMacroExpansion(
			#"""
			@IsCase
			enum InternalStatus { case on }
			"""#,
			expandedSource:
			#"""
			enum InternalStatus {
				case on
				/// Always return `true` because `self` has just `.on` case.
				var isOn: Bool {
					true
				}
				/// A parameterless representation of `InternalStatus` cases.
				enum Cases: Equatable, CaseIterable {
					case on
				}
				/// A parameterless representation of this case.
				var parametersErasedCase: Cases {
					switch self {
					case .on: .on
					}
				}
				/// Returns `true` if `self` matches any case in `cases`.
				/// - Parameter cases: An array of cases to match against.
				func isAmong(_ cases: [Cases]) -> Bool {
					cases.contains(self.parametersErasedCase)
				}
				/// Returns `true` if `self` matches any of the provided cases.
				/// - Parameter cases: The cases to match against.
				func isAmong(_ cases: Cases...) -> Bool {
					isAmong(cases)
				}
			}
			"""#,
			macros: ["IsCase": QizhMacroKitMacros.IsCasesGenerator.self]
		)

		assertMacroExpansion(
			#"""
			@IsCase
			fileprivate enum FileprivateStatus { case on }
			"""#,
			expandedSource:
			#"""
			fileprivate enum FileprivateStatus {
				case on
				/// Always return `true` because `self` has just `.on` case.
				fileprivate var isOn: Bool {
					true
				}
				/// A parameterless representation of `FileprivateStatus` cases.
				fileprivate enum Cases: Equatable, CaseIterable {
					case on
				}
				/// A parameterless representation of this case.
				fileprivate var parametersErasedCase: Cases {
					switch self {
					case .on: .on
					}
				}
				/// Returns `true` if `self` matches any case in `cases`.
				/// - Parameter cases: An array of cases to match against.
				fileprivate func isAmong(_ cases: [Cases]) -> Bool {
					cases.contains(self.parametersErasedCase)
				}
				/// Returns `true` if `self` matches any of the provided cases.
				/// - Parameter cases: The cases to match against.
				fileprivate func isAmong(_ cases: Cases...) -> Bool {
					isAmong(cases)
				}
			}
			"""#,
			macros: ["IsCase": QizhMacroKitMacros.IsCasesGenerator.self]
		)

		assertMacroExpansion(
			#"""
			@IsCase
			private enum PrivateStatus { case on }
			"""#,
			expandedSource:
			#"""
			private enum PrivateStatus {
				case on
				/// Always return `true` because `self` has just `.on` case.
				private var isOn: Bool {
					true
				}
				/// A parameterless representation of `PrivateStatus` cases.
				private enum Cases: Equatable, CaseIterable {
					case on
				}
				/// A parameterless representation of this case.
				private var parametersErasedCase: Cases {
					switch self {
					case .on: .on
					}
				}
				/// Returns `true` if `self` matches any case in `cases`.
				/// - Parameter cases: An array of cases to match against.
				private func isAmong(_ cases: [Cases]) -> Bool {
					cases.contains(self.parametersErasedCase)
				}
				/// Returns `true` if `self` matches any of the provided cases.
				/// - Parameter cases: The cases to match against.
				private func isAmong(_ cases: Cases...) -> Bool {
					isAmong(cases)
				}
			}
			"""#,
			macros: ["IsCase": QizhMacroKitMacros.IsCasesGenerator.self]
		)
	}
	
	// MARK: - Error Cases
	
	/// Tests that applying to a struct produces an error.
	@Test("Fails when applied to struct")
	func failsOnStruct() {
		assertMacroExpansion(
			#"""
			@IsCase
			struct NotAnEnum { var x: Int }
			"""#,
			expandedSource:
			#"""
			struct NotAnEnum { var x: Int }
			"""#,
			diagnostics: [
				DiagnosticSpec(
					message: "@IsCase can only be applied to enums",
					line: 1,
					column: 1,
					severity: .error
				)
			],
			macros: ["IsCase": QizhMacroKitMacros.IsCasesGenerator.self]
		)
	}
	
	/// Tests that applying to an empty enum produces a warning.
	@Test("Warns when applied to empty enum")
	func warnsOnEmptyEnum() {
		assertMacroExpansion(
			#"""
			@IsCase
			enum Empty {}
			"""#,
			expandedSource:
			#"""
			enum Empty {}
			"""#,
			diagnostics: [
				DiagnosticSpec(
					message: "There are no cases in the enum, so `@IsCase` can NOT be applied. You may want to add a case.",
					line: 1,
					column: 1,
					severity: .warning
				)
			],
			macros: ["IsCase": QizhMacroKitMacros.IsCasesGenerator.self]
		)
	}
	
	/// Tests multiple cases generate switch-based properties.
	@Test("Multiple cases generate switch-based properties")
	func multipleCasesGenerateSwitchProperties() {
		assertMacroExpansion(
			#"""
			@IsCase
			enum Status { case on, off }
			"""#,
			expandedSource:
			#"""
			enum Status {
				case on, off
				/// Returns `true` if `self` is `.on`.
				var isOn: Bool {
					switch self {
					case .on: true
					default: false
					}
				}
				/// Returns `true` if `self` is `.off`.
				var isOff: Bool {
					switch self {
					case .off: true
					default: false
					}
				}
				/// A parameterless representation of `Status` cases.
				enum Cases: Equatable, CaseIterable {
			        case on
			        case off
				}
				/// A parameterless representation of this case.
				var parametersErasedCase: Cases {
					switch self {
			        case .on: .on
			        case .off: .off
					}
				}
				/// Returns `true` if `self` matches any case in `cases`.
				/// - Parameter cases: An array of cases to match against.
				func isAmong(_ cases: [Cases]) -> Bool {
					cases.contains(self.parametersErasedCase)
				}
				/// Returns `true` if `self` matches any of the provided cases.
				/// - Parameter cases: The cases to match against.
				func isAmong(_ cases: Cases...) -> Bool {
					isAmong(cases)
				}
			}
			"""#,
			macros: ["IsCase": QizhMacroKitMacros.IsCasesGenerator.self]
		)
	}
}
#endif
