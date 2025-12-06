#if os(macOS)
import Observation
import SwiftSyntaxMacrosTestSupport
import SwiftUI
import Testing
@testable import QizhMacroKit
@testable import QizhMacroKitMacros

@MainActor
final class MacroStore: ObservableObject {}

@Observable
@MainActor
final class MacroNavigation {}

private let withEnvironmentMacros: [String: Macro.Type] = [
	"WithEnvironment": WithEnvironmentGenerator.self
]

@Suite("WithEnvironment macro")
struct WithEnvironmentMacroTests {
	@Test("Expands environment accessors for observable types")
	func expandsEnvironmentBindings() {
		let hash = fnvSuffix(for: "Text(\"Hello\")")
		assertMacroExpansion(
			"""
			@WithEnvironment("Sample") {
				var store: MacroStore
				var navigation: MacroNavigation
			}
			Text("Hello")
			""",
			expandedSource:
				"""
				fileprivate struct _Sample_\(hash)<Content: View>: View {
					@EnvironmentObject private var store: MacroStore
					
					@Environment(MacroNavigation.self) private var navigation
					
					let content: @MainActor @Sendable (MacroStore, MacroNavigation) -> Content
					
					var body: some View {
						content(store, navigation)
					}
				}
				_Sample_\(hash)(content: { store, navigation in Text("Hello") })
				""",
			macros: withEnvironmentMacros
		)
	}
	
	@Test("Warns about unsupported environment type")
	func warnsOnUnsupportedType() {
		let hash = fnvSuffix(for: "Text(\\\"Unsupported\\\")")
		assertMacroExpansion(
		"""
		@WithEnvironment("Unsupported") {
			var count: Int
		}
		Text("Unsupported")
		""",
		expandedSource:
		"""
		fileprivate struct _Unsupported_\(hash)<Content: View>: View {
			@available(*, unavailable, message: "Unsupported environment variable type: Int")
			private var count: Int { fatalError("Unsupported environment variable type: Int") }
			
			let content: @MainActor @Sendable (Int) -> Content
			
			var body: some View {
				content(count)
			}
		}
		_Unsupported_\(hash)(content: { count in Text("Unsupported") })
		""",
		diagnostics: [
	DiagnosticSpec(
	message: "Int is not Observable or ObservableObject. Remove its declaration.",
	line: 3,
	column: 5,
	severity: .warning
	)
		],
		macros: withEnvironmentMacros
		)
	}
}

private func fnvSuffix(for seed: String) -> String {
	var value: UInt64 = 0xcbf29ce484222325
	for scalar in seed.unicodeScalars {
		value ^= UInt64(scalar.value)
		value = value &* 0x100000001b3
	}
	let hex = String(value, radix: 16, uppercase: true)
	return String(hex.suffix(8))
}
#endif
