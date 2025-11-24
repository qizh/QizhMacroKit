#if os(macOS)
import Testing
@testable import QizhMacroKit
@testable import QizhMacroKitMacros

/// Tests for the `IsNotCase` macro.
@Suite("IsNotCase macro")
struct IsNotCaseMacroTests {
	/// Ensures generated properties negate case checks.
	@Test("Generated properties are negated")
	func generatedPropertiesAreNegated() {
		@IsNotCase enum Direction { case left, right }
		let dir = Direction.left
		#expect(!dir.isNotLeft)
		#expect(dir.isNotRight)
	}
}
#endif
