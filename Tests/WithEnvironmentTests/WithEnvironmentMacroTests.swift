#if os(macOS) && canImport(SwiftUI)
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
				@EnvironmentObject var store: MacroStore
				@Environment var navigation: MacroNavigation
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
	
	@Test("Defaults to @Environment for variables without explicit attribute")
	func defaultsToEnvironment() {
		let hash = fnvSuffix(for: "Text(\"Default\")")
		assertMacroExpansion(
			"""
			@WithEnvironment("Default") {
				var navigation: MacroNavigation
			}
			Text("Default")
			""",
			expandedSource: 
				"""
				fileprivate struct _Default_\(hash)<Content: View>: View {
					@Environment(MacroNavigation.self) private var navigation
					
					let content: @MainActor @Sendable (MacroNavigation) -> Content
					
					var body: some View {
						content(navigation)
					}
				}
				_Default_\(hash)(content: { navigation in Text("Default") })
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "MacroNavigation requires @EnvironmentObject or @Environment attribute. Defaulting to @Environment.",
					line: 3,
					column: 5,
					severity: .warning
				)
			],
			macros: withEnvironmentMacros
		)
	}
	
	@Test("Errors on duplicate variable names")
	func errorsOnDuplicateVariableNames() {
		assertMacroExpansion(
			"""
			@WithEnvironment("Duplicate") {
				var store: MacroStore
				var store: MacroNavigation
			}
			Text("Duplicate")
			""",
			expandedSource:
				"""
				Text("Duplicate")
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "Duplicate variable name store",
					line: 4,
					column: 6,
					severity: .error
				)
			],
			macros: withEnvironmentMacros
		)
	}
	
	@Test("Errors on duplicate variable types")
	func errorsOnDuplicateVariableTypes() {
		assertMacroExpansion(
			"""
			@WithEnvironment("DuplicateType") {
				var store1: MacroStore
				var store2: MacroStore
			}
			Text("DuplicateType")
			""",
			expandedSource:
				"""
				Text("DuplicateType")
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "Duplicate environment variable type MacroStore",
					line: 4,
					column: 6,
					severity: .error
				)
			],
			macros: withEnvironmentMacros
		)
	}
	
	@Test("Errors on variables with initializers")
	func errorsOnVariablesWithInitializers() {
		assertMacroExpansion(
			"""
			@WithEnvironment("Initialized") {
				var store: MacroStore = MacroStore()
			}
			Text("Initialized")
			""",
			expandedSource:
				"""
				Text("Initialized")
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "Environment variable store cannot be initialized",
					line: 3,
					column: 6,
					severity: .error
				)
			],
			macros: withEnvironmentMacros
		)
	}
	
	@Test("Errors on missing type annotations")
	func errorsOnMissingTypeAnnotations() {
		assertMacroExpansion(
			"""
			@WithEnvironment("MissingType") {
				var store
			}
			Text("MissingType")
			""",
			expandedSource:
				"""
				Text("MissingType")
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "Environment variable store must declare a type",
					line: 3,
					column: 6,
					severity: .error
				)
			],
			macros: withEnvironmentMacros
		)
	}
	
	@Test("Errors on empty variable closure")
	func errorsOnEmptyVariableClosure() {
		assertMacroExpansion(
			"""
			@WithEnvironment("Empty") {
			}
			Text("Empty")
			""",
			expandedSource:
				"""
				Text("Empty")
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "@WithEnvironment requires at least one variable declaration",
					line: 1,
					column: 27,
					severity: .error
				)
			],
			macros: withEnvironmentMacros
		)
	}
	
	@Test("Expands environment accessors for mixed types with explicit attributes")
	func expandsEnvironmentBindingsForMixedTypes() {
		let hash = fnvSuffix(for: "Text(\"Mixed\")")
		assertMacroExpansion(
			"""
			@WithEnvironment("Mixed") {
				@EnvironmentObject var store: MacroStore
				@Environment var navigation: MacroNavigation
			}
			Text("Mixed")
			""",
			expandedSource:
				"""
				fileprivate struct _Mixed_\(hash)<Content: View>: View {
					@EnvironmentObject private var store: MacroStore
					
					@Environment(MacroNavigation.self) private var navigation
					
					let content: @MainActor @Sendable (MacroStore, MacroNavigation) -> Content
					
					var body: some View {
						content(store, navigation)
					}
				}
				_Mixed_\(hash)(content: { store, navigation in Text("Mixed") })
				""",
			macros: withEnvironmentMacros
		)
	}
	
	@Test("Expands environment accessors for escaped keyword variable names")
	func expandsEnvironmentBindingsForEscapedKeywords() {
		let hash = fnvSuffix(for: "Text(\"Escaped\")")
		assertMacroExpansion(
			"""
			@WithEnvironment("Escaped") {
				@EnvironmentObject var `class`: MacroStore
			}
			Text("Escaped")
			""",
			expandedSource:
				"""
				fileprivate struct _Escaped_\(hash)<Content: View>: View {
					@EnvironmentObject private var `class`: MacroStore
					
					let content: @MainActor @Sendable (MacroStore) -> Content
					
					var body: some View {
						content(`class`)
					}
				}
				_Escaped_\(hash)(content: { `class` in Text("Escaped") })
				""",
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
#else

#warning("These tests are only available when SwiftUI is available")

#endif
