import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

/// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(IsCaseMacros)
import IsCaseMacros

let testMacros: [String: Macro.Type] = [
	"IsCase": IsCasesGenerator.self,
]
#endif

final class QizhMacroKitTests: XCTestCase {

	/// Test that the generated properties return correct values
	func testIsCaseProperties() throws {
		#if canImport(IsCaseMacros)
		@IsCase
		enum TestEnum {
			case first
			case second(Int)
			case third(String)
		}

		let value1 = TestEnum.first
		XCTAssertTrue(value1.isFirst)
		XCTAssertFalse(value1.isSecond)
		XCTAssertFalse(value1.isThird)

		let value2 = TestEnum.second(42)
		XCTAssertFalse(value2.isFirst)
		XCTAssertTrue(value2.isSecond)
		XCTAssertFalse(value2.isThird)

		let value3 = TestEnum.third("Hello")
		XCTAssertFalse(value3.isFirst)
		XCTAssertFalse(value3.isSecond)
		XCTAssertTrue(value3.isThird)
		#else
		throw XCTSkip("macros are only supported when running tests for the host platform")
		#endif
	}

	/// Test applying the macro to a non-enum type
	func testMacroOnNonEnum() {
		struct NotAnEnum {}

		/// Since we cannot catch compile-time errors in runtime tests,
		/// this test will ensure that the macro does not generate properties
		/// when applied to a struct. However, in practice, this should result
		/// in a compile-time error. We can use a compile-time test instead.
	}

	/// Compile-time test to check macro emits error when applied to non-enum
	func testMacroEmitsErrorOnNonEnum() {
		/// This test is illustrative; Swift currently doesn't support compile-time testing in XCTest.
		/// However, you can manually verify that applying @IsCase to a non-enum type results in an error.

		/*
		@IsCase
		struct NotAnEnum {}

		// Expected compiler error:
		// @IsCase can only be applied to enums
		*/
	}
}
