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
}
#endif
