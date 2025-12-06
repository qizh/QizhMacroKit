#if os(macOS) && canImport(SwiftUI)
import SwiftSyntaxMacrosTestSupport
import Testing
@testable import QizhMacroKitMacros

// ProvidingEnvironment macro (experimental) - generates struct + call expression
private let providingEnvironmentMacros: [String: Macro.Type] = [
	"ProvidingEnvironment": ProvidingEnvironmentGenerator.self
]

// WithEnv macro (production) - generates only struct
private let withEnvMacros: [String: Macro.Type] = [
	"WithEnv": WithEnvGenerator.self
]

@Suite("Environment macros")
struct EnvironmentMacroTests {
	
	// MARK: - WithEnv (Production) Tests
	
	@Test("WithEnv expands to wrapper struct")
	func withEnvExpandsToStruct() {
		assertMacroExpansion(
			"""
			#WithEnv("Sample", { var store: MacroStore; var navigation: MacroNavigation })
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
			macros: withEnvMacros
		)
	}
	
	@Test("WithEnv with trailing closure")
	func withEnvWithTrailingClosure() {
		assertMacroExpansion(
			"""
			#WithEnv("Sample") {
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
			macros: withEnvMacros
		)
	}
	
	@Test("WithEnv errors on missing closure")
	func withEnvErrorsOnMissingClosure() {
		assertMacroExpansion(
			"""
			#WithEnv("MissingClosure")
			""",
			expandedSource:
				"""

				""",
			diagnostics: [
				DiagnosticSpec(
					message: "#WithEnv requires a closure with variable declarations",
					line: 1,
					column: 1,
					severity: .error
				)
			],
			macros: withEnvMacros
		)
	}
	
	@Test("WithEnv errors on empty variables")
	func withEnvErrorsOnEmptyVariables() {
		assertMacroExpansion(
			"""
			#WithEnv("Empty", { })
			""",
			expandedSource:
				"""

				""",
			diagnostics: [
				DiagnosticSpec(
					message: "#WithEnv requires at least one variable declaration",
					line: 1,
					column: 19,
					severity: .error
				)
			],
			macros: withEnvMacros
		)
	}
	
	// MARK: - ProvidingEnvironment (Experimental) Tests
	
	@Test("ProvidingEnvironment expands with view expression")
	func providingEnvironmentExpandsWithViewExpression() {
		let hash = fnvSuffix(for: "{ Text(\"Hello\") }")
		assertMacroExpansion(
			"""
			#ProvidingEnvironment("Sample", { var store: MacroStore; var navigation: MacroNavigation }) {
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
			macros: providingEnvironmentMacros
		)
	}
	
	@Test("ProvidingEnvironment errors on missing trailing closure")
	func providingEnvironmentErrorsOnMissingTrailingClosure() {
		assertMacroExpansion(
			"""
			#ProvidingEnvironment("MissingBody", { var store: MacroStore })
			""",
			expandedSource:
				"""

				""",
			diagnostics: [
				DiagnosticSpec(
					message: "#ProvidingEnvironment must have a trailing closure with the view expression",
					line: 1,
					column: 1,
					severity: .error
				)
			],
			macros: providingEnvironmentMacros
		)
	}
	
	// MARK: - Shared Error Tests
	
	@Test("Errors on duplicate variable names")
	func errorsOnDuplicateNames() {
		assertMacroExpansion(
			"""
			#WithEnv("Duplicate", { var store: MacroStore; var store: MacroNavigation })
			""",
			expandedSource:
				"""

				""",
			diagnostics: [
				DiagnosticSpec(
					message: "Duplicate variable name store",
					line: 1,
					column: 48,
					severity: .error
				)
			],
			macros: withEnvMacros
		)
	}
	
	@Test("Errors on missing type annotation")
	func errorsOnMissingType() {
		assertMacroExpansion(
			"""
			#WithEnv("MissingType", { var store })
			""",
			expandedSource:
				"""

				""",
			diagnostics: [
				DiagnosticSpec(
					message: "Environment variable store must declare a type",
					line: 1,
					column: 27,
					severity: .error
				)
			],
			macros: withEnvMacros
		)
	}
	
	@Test("Errors on variables with initializers")
	func errorsOnInitializedVariables() {
		assertMacroExpansion(
			"""
			#WithEnv("Initialized", { var store: MacroStore = MacroStore() })
			""",
			expandedSource:
				"""

				""",
			diagnostics: [
				DiagnosticSpec(
					message: "Environment variable store cannot be initialized",
					line: 1,
					column: 27,
					severity: .error
				)
			],
			macros: withEnvMacros
		)
	}
	
	@Test("Warns about unsupported environment type")
	func warnsOnUnsupportedType() {
		assertMacroExpansion(
			"""
			#WithEnv("Unsupported", { var count: Int })
			""",
			expandedSource:
				"""
				fileprivate struct _Unsupported<Content: View>: View {
					@available(*, unavailable, message: "Unsupported type: Int")
					private var count: Int { fatalError() }
				
					let content: @MainActor @Sendable () -> Content
				
					var body: some View {
						content()
					}
				}
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "Int is not Observable or ObservableObject. Remove its declaration.",
					line: 1,
					column: 27,
					severity: .warning
				)
			],
			macros: withEnvMacros
		)
	}
}

private func fnvSuffix(for seed: String) -> String {
	seed.fnv1aHashSuffix
}
#else
#warning("These tests are available only when SwiftUI is available")
#endif
