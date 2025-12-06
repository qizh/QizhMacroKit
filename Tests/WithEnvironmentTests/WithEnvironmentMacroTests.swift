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
		let hash = fnvSuffix(for: "Text(\"Unsupported\")")
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
	
	@Test("Expands environment accessors for mixed types")
	func expandsEnvironmentBindingsForMixedTypes() {
		let hash = fnvSuffix(for: "Text(\"Mixed\")")
		assertMacroExpansion(
			"""
			@WithEnvironment("Mixed") {
				var store: MacroStore
				var navigation: MacroNavigation
				var count: Int
			}
			Text("Mixed")
			""",
			expandedSource:
				"""
				fileprivate struct _Mixed_\(hash)<Content: View>: View {
					@EnvironmentObject private var store: MacroStore
					
					@Environment(MacroNavigation.self) private var navigation
					
					@available(*, unavailable, message: "Unsupported environment variable type: Int")
					private var count: Int { fatalError("Unsupported environment variable type: Int") }
					
					let content: @MainActor @Sendable (MacroStore, MacroNavigation, Int) -> Content
					
					var body: some View {
						content(store, navigation, count)
					}
				}
				_Mixed_\(hash)(content: { store, navigation, count in Text("Mixed") })
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "Int is not Observable or ObservableObject. Remove its declaration.",
					line: 5,
					column: 5,
					severity: .warning
				)
			],
			macros: withEnvironmentMacros
		)
	}
	
	@Test("Expands environment accessors for escaped keyword variable names")
	func expandsEnvironmentBindingsForEscapedKeywords() {
		let hash = fnvSuffix(for: "Text(\"Escaped\")")
		assertMacroExpansion(
			"""
			@WithEnvironment("Escaped") {
				var `class`: MacroStore
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
#endif
