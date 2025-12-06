#if os(macOS) && canImport(SwiftUI)
import SwiftSyntaxMacrosTestSupport
import Testing
@testable import QizhMacroKitMacros

// CodeItem macro (experimental) - generates struct + call expression
private let withEnvironmentCodeItemMacros: [String: Macro.Type] = [
	"WithEnvironment": WithEnvironmentGenerator.self
]

// Declaration macro (production) - generates only struct
private let withEnvironmentDeclarationMacros: [String: Macro.Type] = [
	"WithEnvironment": WithEnvironmentDeclarationGenerator.self
]

@Suite("WithEnvironment macro")
struct WithEnvironmentMacroTests {
	
	// MARK: - Declaration Macro Tests (Production)
	
	@Test("Declaration macro expands to wrapper struct")
	func declarationMacroExpandsToStruct() {
		assertMacroExpansion(
			"""
			#WithEnvironment("Sample", { var store: MacroStore; var navigation: MacroNavigation })
			""",
			expandedSource:
				"""
				fileprivate struct _Sample<Content: View>: View {
					@EnvironmentObject private var store: MacroStore
				
					@Environment(MacroNavigation.self) private var navigation
				
					let content: @MainActor @Sendable (MacroStore, MacroNavigation) -> Content
				
					var body: some View {
						content(store, navigation)
					}
				}
				""",
			macros: withEnvironmentDeclarationMacros
		)
	}
	
	@Test("Declaration macro with trailing closure")
	func declarationMacroWithTrailingClosure() {
		assertMacroExpansion(
			"""
			#WithEnvironment("Sample") {
				var store: MacroStore
			}
			""",
			expandedSource:
				"""
				fileprivate struct _Sample<Content: View>: View {
					@EnvironmentObject private var store: MacroStore
				
					let content: @MainActor @Sendable (MacroStore) -> Content
				
					var body: some View {
						content(store)
					}
				}
				""",
			macros: withEnvironmentDeclarationMacros
		)
	}
	
	@Test("Declaration macro errors on missing closure")
	func declarationMacroErrorsOnMissingClosure() {
		assertMacroExpansion(
			"""
			#WithEnvironment("MissingClosure")
			""",
			expandedSource:
				"""

				""",
			diagnostics: [
				DiagnosticSpec(
					message: "#WithEnvironment requires a closure with variable declarations",
					line: 1,
					column: 1,
					severity: .error
				)
			],
			macros: withEnvironmentDeclarationMacros
		)
	}
	
	@Test("Declaration macro errors on empty variables")
	func declarationMacroErrorsOnEmptyVariables() {
		assertMacroExpansion(
			"""
			#WithEnvironment("Empty", { })
			""",
			expandedSource:
				"""

				""",
			diagnostics: [
				DiagnosticSpec(
					message: "#WithEnvironment requires at least one variable declaration",
					line: 1,
					column: 27,
					severity: .error
				)
			],
			macros: withEnvironmentDeclarationMacros
		)
	}
	
	// MARK: - CodeItem Macro Tests (Experimental)
	
	@Test("CodeItem macro expands environment accessors for observable types")
	func codeItemMacroExpandsEnvironmentBindings() {
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
			macros: withEnvironmentCodeItemMacros
		)
	}
	
	@Test("CodeItem macro errors on missing trailing closure")
	func codeItemMacroErrorsOnMissingTrailingClosure() {
		assertMacroExpansion(
			"""
			#WithEnvironment("MissingBody", { var store: MacroStore })
			""",
			expandedSource:
				"""

				""",
			diagnostics: [
				DiagnosticSpec(
					message: "#WithEnvironment must have a trailing closure with the view expression",
					line: 1,
					column: 1,
					severity: .error
				)
			],
			macros: withEnvironmentCodeItemMacros
		)
	}
	
	// MARK: - Shared Error Tests
	
	@Test("Errors on duplicate variable names")
	func errorsOnDuplicateNames() {
		assertMacroExpansion(
			"""
			#WithEnvironment("Duplicate", { var store: MacroStore; var store: MacroNavigation })
			""",
			expandedSource:
				"""

				""",
			diagnostics: [
				DiagnosticSpec(
					message: "Duplicate variable name store",
					line: 1,
					column: 56,
					severity: .error
				)
			],
			macros: withEnvironmentDeclarationMacros
		)
	}
	
	@Test("Errors on missing type annotation")
	func errorsOnMissingType() {
		assertMacroExpansion(
			"""
			#WithEnvironment("MissingType", { var store })
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
			macros: withEnvironmentDeclarationMacros
		)
	}
	
	@Test("Errors on variables with initializers")
	func errorsOnInitializedVariables() {
		assertMacroExpansion(
			"""
			#WithEnvironment("Initialized", { var store: MacroStore = MacroStore() })
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
			macros: withEnvironmentDeclarationMacros
		)
	}
	
	@Test("Warns about unsupported environment type")
	func warnsOnUnsupportedType() {
		assertMacroExpansion(
			"""
			#WithEnvironment("Unsupported", { var count: Int })
			""",
			expandedSource:
				"""
				fileprivate struct _Unsupported<Content: View>: View {
					@available(*, unavailable, message: "Unsupported type: Int")
					private var count: Int { fatalError() }
				
					let content: @MainActor @Sendable (Int) -> Content
				
					var body: some View {
						content(count)
					}
				}
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "Int is not Observable or ObservableObject. Remove its declaration.",
					line: 1,
					column: 35,
					severity: .warning
				)
			],
			macros: withEnvironmentDeclarationMacros
		)
	}
}

private func fnvSuffix(for seed: String) -> String {
	seed.fnv1aHashSuffix
}
#else
#warning("These tests are available only when SwiftUI is available")
#endif
