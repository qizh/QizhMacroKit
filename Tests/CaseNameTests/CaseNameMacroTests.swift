import Testing
import QizhMacroKit

/// Tests for the `CaseName` macro.
@Suite("CaseName macro")
struct CaseNameMacroTests {
	/// Ensures the generated `caseName` reflects the case.
	@Test("`caseName` matches the case")
	func caseNameMatchesCase() {
		@CaseName enum Status { case ready, running }
		let state = Status.running
		#expect(state.caseName == "running")
	}
}

