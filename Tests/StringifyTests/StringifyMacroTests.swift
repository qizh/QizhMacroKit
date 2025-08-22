//
//  StringifyMacroTests.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 22.08.2025.
//

import Testing

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import SwiftSyntaxMacrosGenericTestSupport

#if canImport(StringifyGenerator) && canImport(StringifyAndCalculateGenerator)
import StringifyGenerator
import StringifyAndCalculateGenerator
#endif


@Suite("Stringify Macro Tests")
struct TestStringifyMacros {
	#if canImport(StringifyGenerator) && canImport(StringifyAndCalculateGenerator)
	let macrosUnderTest: [String: any Macro.Type] = [
		"stringify": StringifyGenerator.self,
		"stringifyAndCalculate": StringifyAndCalculateGenerator.self,
	]
	#else
	let macrosUnderTest: [String: any Macro.Type] = [:]
	#endif
	
	// MARK: - Tests

	@Test("stringify yields only the source")
	func stringifyExpr_yieldsSource() {
		assertMacroExpansion(
			#"""
			let a = 4
			let s = #stringify(a * (1 + 2))
			"""#,
			expandedSource:
			#"""
			let a = 4
			let s = "a * (1 + 2)"
			"""#,
			macros: macrosUnderTest
		)
	}

	@Test("stringify returns (value, string)")
	func stringify_valueAndSourceTuple() {
		assertMacroExpansion(
			#"""
			let a = 4
			let result = #stringifyAndCalculate(a * (1 + 2))
			"""#,
			expandedSource:
			#"""
			let a = 4
			let result = (value: a * (1 + 2), string: "a * (1 + 2)")
			"""#,
			macros: macrosUnderTest
		)
	}

	@Test("diagnostic when called without arguments")
	func stringify_errorsOnNoArgs() {
		assertMacroExpansion(
			#"#stringify()"#,
			expandedSource: #"#stringify()"#,
			diagnostics: [
				DiagnosticSpec(
					id: .init(domain: "QizhKitMacros", id: "missingArgument"),
					message: "stringify requires one argument",
					line: 1,
					column: 1,
					severity: .error
				)
			],
			macros: macrosUnderTest
			// onFailure: record
		)
	}
    
	@Test("First test if `string` and `value` are accessible")
	func stringify_checkAccessibleMembers() {
		assertMacroExpansion(
			#"""
			let connectionID: Int? = 123
			let id = #stringifyAndCalculate(connectionID).value
			return #stringify(id)
			"""#,
			expandedSource:
			#"""
			let connectionID: Int? = 123
			let id = (value: connectionID, string: "connectionID").value
			return "id"
			"""#,
			macros: macrosUnderTest
		)
	}
	
	@Test("Another test if `string` and `value` are accessible")
	func stringify_checkAccessibleMembers2() {
		assertMacroExpansion(
			#"""
			let connectionID: Int? = 123
			let id = #stringifyAndCalculate(connectionID).value
			_ = #stringify(id)
			"""#,
			expandedSource:
			#"""
			let connectionID: Int? = 123
			let id = (value: connectionID, string: "connectionID").value
			return "id"
			"""#,
			macros: macrosUnderTest
		)
	}
}

