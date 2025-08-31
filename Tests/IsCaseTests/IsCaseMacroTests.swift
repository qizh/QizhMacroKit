import Testing
import QizhMacroKit
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import QizhMacroKitMacros

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
				/// Returns `true` if `self` is `.on`.
				public var isOn: Bool {
					switch self {
					case .on: true
					default: false
					}
				}
				/// A parameterless representation of `PublicStatus` cases.
				public enum Cases: Equatable {
					case on
				}
				/// A parameterless representation of this case.
				private var caseValue: Cases {
					switch self {
					case .on: .on
					}
				}
				/// Returns `true` if `self` matches any case in `cases`.
				/// - Parameter cases: An array of cases to match against.
				public func isAmong(_ cases: [Cases]) -> Bool {
					cases.contains(self.caseValue)
				}
				/// Returns `true` if `self` matches any of the provided cases.
				/// - Parameter cases: The cases to match against.
				public func isAmong(_ cases: Cases...) -> Bool {
					isAmong(cases)
				}
			}
			"""#,
			macros: ["IsCase": IsCasesGenerator.self]
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
				/// Returns `true` if `self` is `.on`.
				var isOn: Bool {
					switch self {
					case .on: true
					default: false
					}
				}
				/// A parameterless representation of `InternalStatus` cases.
				enum Cases: Equatable {
					case on
				}
				/// A parameterless representation of this case.
				private var caseValue: Cases {
					switch self {
					case .on: .on
					}
				}
				/// Returns `true` if `self` matches any case in `cases`.
				/// - Parameter cases: An array of cases to match against.
				func isAmong(_ cases: [Cases]) -> Bool {
					cases.contains(self.caseValue)
				}
				/// Returns `true` if `self` matches any of the provided cases.
				/// - Parameter cases: The cases to match against.
				func isAmong(_ cases: Cases...) -> Bool {
					isAmong(cases)
				}
			}
			"""#,
			macros: ["IsCase": IsCasesGenerator.self]
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
				/// Returns `true` if `self` is `.on`.
				fileprivate var isOn: Bool {
					switch self {
					case .on: true
					default: false
					}
				}
				/// A parameterless representation of `FileprivateStatus` cases.
				fileprivate enum Cases: Equatable {
					case on
				}
				/// A parameterless representation of this case.
				private var caseValue: Cases {
					switch self {
					case .on: .on
					}
				}
				/// Returns `true` if `self` matches any case in `cases`.
				/// - Parameter cases: An array of cases to match against.
				fileprivate func isAmong(_ cases: [Cases]) -> Bool {
					cases.contains(self.caseValue)
				}
				/// Returns `true` if `self` matches any of the provided cases.
				/// - Parameter cases: The cases to match against.
				fileprivate func isAmong(_ cases: Cases...) -> Bool {
					isAmong(cases)
				}
			}
			"""#,
			macros: ["IsCase": IsCasesGenerator.self]
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
				/// Returns `true` if `self` is `.on`.
				private var isOn: Bool {
					switch self {
					case .on: true
					default: false
					}
				}
				/// A parameterless representation of `PrivateStatus` cases.
				private enum Cases: Equatable {
					case on
				}
				/// A parameterless representation of this case.
				private var caseValue: Cases {
					switch self {
					case .on: .on
					}
				}
				/// Returns `true` if `self` matches any case in `cases`.
				/// - Parameter cases: An array of cases to match against.
				private func isAmong(_ cases: [Cases]) -> Bool {
					cases.contains(self.caseValue)
				}
				/// Returns `true` if `self` matches any of the provided cases.
				/// - Parameter cases: The cases to match against.
				private func isAmong(_ cases: Cases...) -> Bool {
					isAmong(cases)
				}
			}
			"""#,
			macros: ["IsCase": IsCasesGenerator.self]
		)
	}
}

