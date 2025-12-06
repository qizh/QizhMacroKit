#if os(macOS) && canImport(SwiftUI) && swift(>=6.2)
import Testing
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import QizhMacroKit
@testable import QizhMacroKitMacros

private func deterministicSuffix(for seed: String) -> String {
	var hash: UInt64 = 0xcbf29ce484222325
	for byte in seed.utf8 {
		hash ^= UInt64(byte)
		hash &*= 0x100000001b3
	}
	let hex = String(hash, radix: 16, uppercase: true)
	if hex.count >= 8 {
		return String(hex.prefix(8))
	} else {
		return hex.padding(toLength: 8, withPad: "0", startingAt: 0)
	}
}

/// Tests for the `WithEnvironment` macro covering validation and expansion.
@Suite("WithEnvironment macro 1")
struct WithEnvironmentMacroTests {
	/// Macro implementations under test.
	let macros: [String: any Macro.Type] = [
		"WithEnvironment": WithEnvironmentGenerator.self,
	]
	
	@Test("Expands view content with environment variables")
	func expandsViewContent() {
		let source = #"""
			let title = "Hello"
			#WithEnvironment({
				var store: DemoStoreObservableObject
				var nav: DemoNavigationObservable
			}) {
				VStack {
					Text(title)
					Text(nav.path)
				}
			}
			"""#
		
		let seed = "{\n        var store: DemoStoreObservableObject\n        var nav: DemoNavigationObservable\n}" + "{\n    VStack {\n        Text(title)\n        Text(nav.path)\n    }\n}"
		
		let suffix = deterministicSuffix(for: seed)
		let expected = """
			let title = "Hello"
			{
				struct _WithEnvironment_\(suffix)<Capture0>: View {
					let title: Capture0
					@EnvironmentObject private var store: DemoStoreObservableObject
					@Environment(DemoNavigationObservable.self) private var nav
					var body: some View {
						VStack {
							Text(title)
							Text(nav.path)
						}
					}
				}
				
				return _WithEnvironment_\(suffix)(title: title)
			}()
			"""
		
		assertMacroExpansion(
			source,
			expandedSource: expected,
			macros: macros,
			indentationWidth: .tab
		)
	}
	
	@Test("Reports duplicate variable names")
	func duplicateNames() {
		assertMacroExpansion(
			#"""
			#WithEnvironment({
				var store: DemoStoreObservableObject
				var store: DemoStoreObservableObject
			}) {
				EmptyView()
			}
			"""#,
			expandedSource: #"""
			#WithEnvironment({
				var store: DemoStoreObservableObject
				var store: DemoStoreObservableObject
			}) {
				EmptyView()
			}
			"""#,
			diagnostics: [
				.init(
					message: "Duplicate environment variable name store.",
					line: 3,
					column: 33,
					severity: .error
				)
			],
			macros: macros,
			indentationWidth: .tab
		)
	}
}

/// Tests for the `WithEnvironment` macro covering validation and expansion.
@Suite("WithEnvironment macro 2")
struct WithEnvironmentMacroTests2 {
	/// Macro implementations under test.
	let macros: [String: any Macro.Type] = [
		"WithEnvironment": WithEnvironmentGenerator.self,
	]
	
	@Test("Expands view content with environment variables")
	func expandsViewContent() {
		let source = #"""
			let title = "Hello"
			#WithEnvironment({
				var store: DemoStoreObservableObject
				var nav: DemoNavigationObservable
			}) {
				VStack {
					Text(title)
					Text(nav.path)
				}
			}
			"""#
		let seed = """
		{
			var store: DemoStoreObservableObject
			var nav: DemoNavigationObservable
		} {
			VStack {
				Text(title)
				Text(nav.path)
			}
		}
		"""
		let suffix = deterministicSuffix(for: seed)
		let expected = "let title = \"Hello\"\n" +
			"""
			{
				struct _WithEnvironment_\(suffix)<Capture0>: View {
					let title: Capture0
					@EnvironmentObject private var store: DemoStoreObservableObject
					@Environment(DemoNavigationObservable.self) private var nav
					var body: some View {
						VStack {
							Text(title)
							Text(nav.path)
						}
					}
				}
				
				return _WithEnvironment_\(suffix)(title: title)
			}()
			"""
		
		assertMacroExpansion(
			source,
			expandedSource: expected,
			macros: macros,
			indentationWidth: .tab
		)
	}
	
	@Test("Expands view content with environment variables 2")
	func expandsViewContent2() {
		let source = #"""
			let title = "Hello"
			#WithEnvironment({
				var store: DemoStoreObservableObject
				var nav: DemoNavigationObservable
			}) {
				VStack {
					Text(title)
					Text(nav.path)
				}
			}
			"""#
		let seed = "{\n        var store: DemoStoreObservableObject\n        var nav: DemoNavigationObservable\n}" + "{\n    VStack {\n        Text(title)\n        Text(nav.path)\n    }\n}"
		let suffix = deterministicSuffix(for: seed)
		let expected = """
			let title = "Hello"
			{
				struct _WithEnvironment_\(suffix)<Capture0>: View {
					let title: Capture0
					@EnvironmentObject private var store: DemoStoreObservableObject
					@Environment(DemoNavigationObservable.self) private var nav
					var body: some View {
						VStack {
							Text(title)
							Text(nav.path)
						}
					}
				}

				return _WithEnvironment_\(suffix)(title: title)
			}()
			"""
		
		assertMacroExpansion(
			source,
			expandedSource: expected,
			macros: macros,
			indentationWidth: .tab
		)
	}

	@Test("Reports initializer usage")
	func initializerUsage() {
		assertMacroExpansion(
		#"""
		#WithEnvironment({
			var store: DemoStoreObservableObject = .init()
		}) {
			EmptyView()
		}
		"""#,
		expandedSource: #"""
		#WithEnvironment({
			var store: DemoStoreObservableObject = .init()
		}) {
			EmptyView()
		}
		"""#,
		diagnostics: [
			.init(
				message: "Environment variables must not be initialized.",
				line: 3,
				column: 33,
				severity: .error
			)
		],
		macros: macros,
		indentationWidth: .tab
		)
	}
	
	@Test("Warns on unsupported type")
	func unsupportedTypeWarning() {
		let seed = "{\n        var settings: SomeCustomType\n}" + "{\n    EmptyView()\n}"
		let suffix = deterministicSuffix(for: seed)
		assertMacroExpansion(
			#"""
			#WithEnvironment({
				var settings: SomeCustomType
			}) {
				EmptyView()
			}
			"""#,
			expandedSource: """
			{
				struct _WithEnvironment_\(suffix): View {
					@Environment(SomeCustomType.self) private var settings
					var body: some View {
						EmptyView()
					}
				}
				
				return _WithEnvironment_\(suffix)()
			}()
			""",
			diagnostics: [
				.init(
					message: "Type SomeCustomType does not conform to ObservableObject or Observable.",
					line: 2,
					column: 23,
					severity: .warning
				)
			],
			macros: macros,
			indentationWidth: .tab
		)
	}
	
	@Test("Reports initializer usage 1")
	func initializerUsage1() {
		assertMacroExpansion(
			#"""
			#WithEnvironment({
				var store: DemoStoreObservableObject = .init()
			}) {
				EmptyView()
			}
			"""#,
			expandedSource: #"""
			#WithEnvironment({
				var store: DemoStoreObservableObject
				var store: DemoStoreObservableObject
			}) {
				EmptyView()
			}
			"""#,
			diagnostics: [
				.init(
					message: "Duplicate environment variable name store.",
					line: 3,
					column: 33,
					severity: .error
				)
			],
			macros: macros,
			indentationWidth: .tab
		)
	}
	
	@Test("Reports initializer usage 2")
	func initializerUsage2() {
		assertMacroExpansion(
			#"""
			#WithEnvironment({
				var store: DemoStoreObservableObject = .init()
			}) {
				EmptyView()
			}
			"""#,
			expandedSource: #"""
			#WithEnvironment({
				var store: DemoStoreObservableObject = .init()
			}) {
				EmptyView()
			}
			"""#,
			diagnostics: [
				.init(
					message: "Environment variables must not be initialized.",
					line: 3,
					column: 33,
					severity: .error
				)
			],
			macros: macros,
			indentationWidth: .tab
		)
	}
	
	@Test("Reports initializer usage 3")
	func initializerUsage3() {
		assertMacroExpansion(
			#"""
			#WithEnvironment({
				var store: DemoStoreObservableObject = .init()
			}) {
				EmptyView()
			}
			"""#,
			expandedSource: #"""
			#WithEnvironment({
				var store: DemoStoreObservableObject = .init()
			}) {
				EmptyView()
			}
			"""#,
			diagnostics: [
				.init(
					message: "Environment variables must not be initialized.",
					line: 3,
					column: 33,
					severity: .error
				)
			],
			macros: macros,
			indentationWidth: .tab
		)
	}
	
	@Test("Reports missing arguments")
	func missingArguments() {
		assertMacroExpansion(
			#"""
			#WithEnvironment()
			"""#,
			expandedSource: #"""
			()
			"""#,
			diagnostics: [
				.init(
					message: "#WithEnvironment expects at least a variables declaration closure and a content closure.",
					line: 1,
					column: 1,
					severity: .error
				)
			],
			macros: macros,
			indentationWidth: .tab
		)
	}
	
	@Test("Expands with custom struct name")
	func expandsWithCustomName() {
		let source = #"""
			#WithEnvironment("MyEnvView", {
				var store: DemoStoreObservableObject
			}) {
				Text("Hello")
			}
			"""#
		let seed = "{\n        var store: DemoStoreObservableObject\n}" + "{\n    Text(\"Hello\")\n}"
		let suffix = deterministicSuffix(for: seed)
		let expected = """
			{
				struct _MyEnvView_\(suffix): View {
					@EnvironmentObject private var store: DemoStoreObservableObject
					var body: some View {
						Text("Hello")
					}
				}
				
				return _MyEnvView_\(suffix)()
			}()
			"""
		
		assertMacroExpansion(
			source,
			expandedSource: expected,
			macros: macros,
			indentationWidth: .tab
		)
	}
}
#endif
