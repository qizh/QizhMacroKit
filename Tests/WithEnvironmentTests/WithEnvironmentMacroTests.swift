#if os(macOS) && canImport(SwiftUI)
import Observation
import SwiftSyntaxMacrosTestSupport
import Testing
@testable import QizhMacroKitMacros

private let withEnvironmentMacros: [String: Macro.Type] = [
	"WithEnvironment": WithEnvironmentGenerator.self
]

@Suite("WithEnvironment macro")
struct WithEnvironmentMacroTests {
	@Test("Expands environment accessors for observable types")
	func expandsEnvironmentBindings() {
		let hash = fnvSuffix(for: "{ Text(\"Hello\") }")
		assertMacroExpansion(
			"""
			#WithEnvironment("Sample", { var store: MacroStore; var navigation: MacroNavigation }) {
				Text("Hello")
			}
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
				_Sample_\(hash)(content: { store, navigation in { Text("Hello") } })
				""",
			macros: withEnvironmentMacros
		)
	}
	
	@Test("Warns about unsupported environment type")
	func warnsOnUnsupportedType() {
		let hash = fnvSuffix(for: "{ Text(\"Unsupported\") }")
		assertMacroExpansion(
			"""
			#WithEnvironment("Unsupported", { var count: Int }) {
				Text("Unsupported")
			}
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
				_Unsupported_\(hash)(content: { count in { Text("Unsupported") } })
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "Int is not Observable or ObservableObject. Remove its declaration.",
					line: 1,
					column: 34,
					severity: .warning
				)
			],
			macros: withEnvironmentMacros
		)
	}
	
	@Test("Errors when missing closure argument")
	func errorsOnMissingClosure() {
		assertMacroExpansion(
			"""
			#WithEnvironment("MissingClosure") {
				Text("Hello")
			}
			""",
			expandedSource:
				"""

				""",
			diagnostics: [
				DiagnosticSpec(
					message: "@WithEnvironment requires a closure with variable declarations",
					line: 1,
					column: 1,
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
	
	@Test("Errors when missing trailing closure")
	func errorsOnMissingTrailingClosure() {
		assertMacroExpansion(
			"""
			#WithEnvironment("MissingBody", { var store: MacroStore })
			""",
			expandedSource:
				"""

				""",
			diagnostics: [
				DiagnosticSpec(
					message: "@WithEnvironment must have a trailing closure with the view expression",
					line: 1,
					column: 1,
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
	
	@Test("Errors when empty variable declarations")
	func errorsOnEmptyVariables() {
		assertMacroExpansion(
			"""
			#WithEnvironment("Empty", { }) {
				Text("Hello")
			}
			""",
			expandedSource:
				"""

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
	
	@Test("Errors on duplicate variable names")
	func errorsOnDuplicateNames() {
		let hash = fnvSuffix(for: "{ Text(\"Hello\") }")
		assertMacroExpansion(
			"""
			#WithEnvironment("Duplicate", { var store: MacroStore; var store: MacroNavigation }) {
				Text("Hello")
			}
			""",
			expandedSource:
				"""
				fileprivate struct _Duplicate_\(hash)<Content: View>: View {
					@EnvironmentObject private var store: MacroStore

					let content: @MainActor @Sendable (MacroStore) -> Content

					var body: some View {
						content(store)
					}
				}
				_Duplicate_\(hash)(content: { store in { Text("Hello") } })
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "Duplicate variable name store",
					line: 1,
					column: 56,
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
	
	@Test("Errors on missing type annotation")
	func errorsOnMissingType() {
		assertMacroExpansion(
			"""
			#WithEnvironment("MissingType", { var store }) {
				Text("Hello")
			}
			""",
			expandedSource:
				"""

				""",
			diagnostics: [
				DiagnosticSpec(
					message: "Environment variable store must declare a type",
					line: 1,
					column: 35,
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
	
	@Test("Errors on duplicate types")
	func errorsOnDuplicateTypes() {
		let hash = fnvSuffix(for: "{ Text(\"Hello\") }")
		assertMacroExpansion(
			"""
			#WithEnvironment("DuplicateType", { var store1: MacroStore; var store2: MacroStore }) {
				Text("Hello")
			}
			""",
			expandedSource:
				"""
				fileprivate struct _DuplicateType_\(hash)<Content: View>: View {
					@EnvironmentObject private var store1: MacroStore

					let content: @MainActor @Sendable (MacroStore) -> Content

					var body: some View {
						content(store1)
					}
				}
				_DuplicateType_\(hash)(content: { store1 in { Text("Hello") } })
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "Duplicate environment variable type MacroStore",
					line: 1,
					column: 61,
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
				var name: String
			}
			Text("Mixed")
			""",
			expandedSource:
				"""
				fileprivate struct _Mixed_\(hash)<Content: View>: View {
					@EnvironmentObject private var store: MacroStore
					
					@Environment(MacroNavigation.self) private var navigation
					
					@available(*, unavailable, message: "Unsupported environment variable type: String")
					private var name: String { fatalError("Unsupported environment variable type: String") }
					
					let content: @MainActor @Sendable (MacroStore, MacroNavigation, String) -> Content
					
					var body: some View {
						content(store, navigation, name)
					}
				}
				_Mixed_\(hash)(content: { store, navigation, name in Text("Mixed") })
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "String is not Observable or ObservableObject. Remove its declaration.",
					line: 5,
					column: 5,
					severity: .warning
				)
			],
			macros: withEnvironmentMacros
		)
	}
	
	@Test("Errors on variables with initializers")
	func errorsOnInitializedVariables() {
		assertMacroExpansion(
			"""
			#WithEnvironment("Initialized", { var store: MacroStore = MacroStore() }) {
				Text("Hello")
			}
			""",
			expandedSource:
				"""

				""",
			diagnostics: [
				DiagnosticSpec(
					message: "Environment variable store cannot be initialized",
					line: 1,
					column: 35,
					severity: .error
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
#else

#warning("These tests are only available when SwiftUI is available")

#endif
