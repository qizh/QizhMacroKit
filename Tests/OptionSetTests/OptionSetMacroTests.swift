//
//  OptionSetMacroTests.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 08.12.2025.
//

#if os(macOS)
import Testing
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

@testable import QizhMacroKit
@testable import QizhMacroKitMacros

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@Suite("OptionSet Macro Tests")
struct OptionSetMacroTests {
	private let macros = ["OptionSet": OptionSetGenerator.self]
	
	@Test("Expansion on Simple Struct with Enum and Static")
	func testExpansionOnStructWithNestedEnumAndStatics() {
		assertMacroExpansion(
			"""
			@MyOptionSet<UInt8>
			struct ShippingOptions {
				private enum Options: Int {
					case nextDay
					case secondDay
					case priority
					case standard
				}

				static let express: ShippingOptions = [.nextDay, .secondDay]
				static let all: ShippingOptions = [.express, .priority, .standard]
			}
			""",
			expandedSource: """
				struct ShippingOptions {
					private enum Options: Int {
						case nextDay
						case secondDay
						case priority
						case standard
					}

					static let express: ShippingOptions = [.nextDay, .secondDay]
					static let all: ShippingOptions = [.express, .priority, .standard]

					typealias RawValue = UInt8

					var rawValue: RawValue

					init() {
						self.rawValue = 0
					}

					init(rawValue: RawValue) {
						self.rawValue = rawValue
					}

					static let nextDay: Self =
						Self(rawValue: 1 << Options.nextDay.rawValue)

					static let secondDay: Self =
						Self(rawValue: 1 << Options.secondDay.rawValue)

					static let priority: Self =
						Self(rawValue: 1 << Options.priority.rawValue)

					static let standard: Self =
						Self(rawValue: 1 << Options.standard.rawValue)
				}

				extension ShippingOptions: OptionSet {
				}
				""",
			macros: macros,
			indentationWidth: .spaces(2)
		)
	}

	@Test("Expansion on Public Struct with Explicit OptionSet Conformance")
	func testExpansionOnPublicStructWithExplicitOptionSetConformance() {
		assertMacroExpansion(
			"""
			@MyOptionSet<UInt8>
			public struct ShippingOptions: OptionSet {
				private enum Options: Int {
					case nextDay
					case standard
				}
			}
			""",
			expandedSource: """
				public struct ShippingOptions: OptionSet {
					private enum Options: Int {
						case nextDay
						case standard
					}

					public typealias RawValue = UInt8

					public var rawValue: RawValue

					public init() {
						self.rawValue = 0
					}

					public init(rawValue: RawValue) {
						self.rawValue = rawValue
					}

					public  static let nextDay: Self =
						Self(rawValue: 1 << Options.nextDay.rawValue)

					public  static let standard: Self =
						Self(rawValue: 1 << Options.standard.rawValue)
				}
				""",
			macros: macros,
			indentationWidth: .spaces(2)
		)
	}
	
	@Test("Expansion fails on EnumType")
	func testExpansionFailsOnEnumType() {
		assertMacroExpansion(
			"""
			@MyOptionSet<UInt8>
			enum Animal {
				case dog
			}
			""",
			expandedSource: """
				enum Animal {
					case dog
				}
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "'OptionSet' macro can only be applied to a struct",
					line: 1,
					column: 1
				)
			],
			macros: macros,
			indentationWidth: .spaces(2)
		)
	}
	
	@Test("Expansion fails on Struct without nested Options enum")
	func testExpansionFailsWithoutNestedOptionsEnum() {
		assertMacroExpansion(
			"""
			@MyOptionSet<UInt8>
			struct ShippingOptions {
				static let express: ShippingOptions = [.nextDay, .secondDay]
				static let all: ShippingOptions = [.express, .priority, .standard]
			}
			""",
			expandedSource: """
				struct ShippingOptions {
					static let express: ShippingOptions = [.nextDay, .secondDay]
					static let all: ShippingOptions = [.express, .priority, .standard]
				}
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "'OptionSet' macro requires nested options enum 'Options'",
					line: 1,
					column: 1
				)
			],
			macros: macros,
			indentationWidth: .spaces(2)
		)
	}
	
	@Test("Expansion fails on Struct without specified RawType")
	func testExpansionFailsWithoutSpecifiedRawType() {
		assertMacroExpansion(
			"""
			@MyOptionSet
			struct ShippingOptions {
				private enum Options: Int {
					case nextDay
				}
			}
			""",
			expandedSource: """
				struct ShippingOptions {
					private enum Options: Int {
						case nextDay
					}
				}
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "'OptionSet' macro requires a raw type",
					line: 1,
					column: 1
				)
			],
			macros: macros,
			indentationWidth: .spaces(2)
		)
	}
}
#endif
