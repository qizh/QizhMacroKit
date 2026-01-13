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
			@OptionSet<UInt8>
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
			@OptionSet<UInt8>
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
			@OptionSet<UInt8>
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
			@OptionSet<UInt8>
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
			@OptionSet
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
	
	@Test("Expansion with custom optionsName argument")
	func testExpansionWithCustomOptionsName() {
		assertMacroExpansion(
			"""
			@OptionSet<UInt8>(optionsName: "Flags")
			struct Permissions {
				private enum Flags: Int {
					case read
					case write
				}
			}
			""",
			expandedSource: """
				struct Permissions {
					private enum Flags: Int {
						case read
						case write
					}

					typealias RawValue = UInt8

					var rawValue: RawValue

					init() {
						self.rawValue = 0
					}

					init(rawValue: RawValue) {
						self.rawValue = rawValue
					}

					static let read: Self =
						Self(rawValue: 1 << Flags.read.rawValue)

					static let write: Self =
						Self(rawValue: 1 << Flags.write.rawValue)
				}

				extension Permissions: OptionSet {
				}
				""",
			macros: macros,
			indentationWidth: .spaces(2)
		)
	}
	
	@Test("Expansion fails with non-string literal optionsName")
	func testExpansionFailsWithNonStringLiteralOptionsName() {
		assertMacroExpansion(
			"""
			@OptionSet<UInt8>(optionsName: someVariable)
			struct Permissions {
				private enum Options: Int {
					case read
				}
			}
			""",
			expandedSource: """
				struct Permissions {
					private enum Options: Int {
						case read
					}
				}
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "'OptionSet' macro argument optionsName must be a string literal",
					line: 1,
					column: 31
				)
			],
			macros: macros,
			indentationWidth: .spaces(2)
		)
	}
	
	@Test("Expansion fails when custom optionsName enum is missing")
	func testExpansionFailsWhenCustomOptionsEnumMissing() {
		assertMacroExpansion(
			"""
			@OptionSet<UInt8>(optionsName: "CustomOptions")
			struct Permissions {
				private enum Options: Int {
					case read
				}
			}
			""",
			expandedSource: """
				struct Permissions {
					private enum Options: Int {
						case read
					}
				}
				""",
			diagnostics: [
				DiagnosticSpec(
					message: "'OptionSet' macro requires nested options enum 'CustomOptions'",
					line: 1,
					column: 1
				)
			],
			macros: macros,
			indentationWidth: .spaces(2)
		)
	}
	
	/// Tests that non-case members in Options enum are skipped.
	@Test("Skips non-case members in Options enum")
	func testSkipsNonCaseMembersInOptionsEnum() {
		assertMacroExpansion(
			"""
			@OptionSet<UInt8>
			struct Flags {
				private enum Options: Int {
					case enabled
					var description: String { "" }
					case disabled
				}
			}
			""",
			expandedSource: """
				struct Flags {
					private enum Options: Int {
						case enabled
						var description: String { "" }
						case disabled
					}

					typealias RawValue = UInt8

					var rawValue: RawValue

					init() {
						self.rawValue = 0
					}

					init(rawValue: RawValue) {
						self.rawValue = rawValue
					}

					static let enabled: Self =
						Self(rawValue: 1 << Options.enabled.rawValue)

					static let disabled: Self =
						Self(rawValue: 1 << Options.disabled.rawValue)
				}

				extension Flags: OptionSet {
				}
				""",
			macros: macros,
			indentationWidth: .spaces(2)
		)
	}
	
	// MARK: - Associated Enum Value Tests
	
	/// Tests that cases with associated nested enum values generate combined properties.
	@Test("Generates properties for associated nested enum values")
	func testAssociatedNestedEnumValues() {
		assertMacroExpansion(
			"""
			@OptionSet<UInt8>
			struct Configuration {
				private enum Options {
					case level(Priority)
				}
				
				enum Priority {
					case low
					case medium
					case high
				}
			}
			""",
			expandedSource: """
				struct Configuration {
					private enum Options {
						case level(Priority)
					}
					
					enum Priority {
						case low
						case medium
						case high
					}

					typealias RawValue = UInt8

					var rawValue: RawValue

					init() {
						self.rawValue = 0
					}

					init(rawValue: RawValue) {
						self.rawValue = rawValue
					}

					static let levelLow: Self =
						Self(rawValue: 1 << 0)

					static let levelMedium: Self =
						Self(rawValue: 1 << 1)

					static let levelHigh: Self =
						Self(rawValue: 1 << 2)
				}

				extension Configuration: OptionSet {
				}
				""",
			macros: macros,
			indentationWidth: .spaces(2)
		)
	}
	
	/// Tests mixing simple cases with associated enum value cases.
	@Test("Mixes simple cases with associated enum values")
	func testMixedSimpleAndAssociatedCases() {
		assertMacroExpansion(
			"""
			@OptionSet<UInt8>
			struct Settings {
				private enum Options: Int {
					case enabled
					case theme(Theme)
					case debug
				}
				
				enum Theme {
					case light
					case dark
				}
			}
			""",
			expandedSource: """
				struct Settings {
					private enum Options: Int {
						case enabled
						case theme(Theme)
						case debug
					}
					
					enum Theme {
						case light
						case dark
					}

					typealias RawValue = UInt8

					var rawValue: RawValue

					init() {
						self.rawValue = 0
					}

					init(rawValue: RawValue) {
						self.rawValue = rawValue
					}

					static let enabled: Self =
						Self(rawValue: 1 << 0)

					static let themeLight: Self =
						Self(rawValue: 1 << 1)

					static let themeDark: Self =
						Self(rawValue: 1 << 2)

					static let debug: Self =
						Self(rawValue: 1 << 3)
				}

				extension Settings: OptionSet {
				}
				""",
			macros: macros,
			indentationWidth: .spaces(2)
		)
	}
	
	/// Tests that multiple associated enum value cases work correctly.
	@Test("Multiple associated enum value cases")
	func testMultipleAssociatedEnumCases() {
		assertMacroExpansion(
			"""
			@OptionSet<UInt16>
			struct DisplayOptions {
				private enum Options {
					case size(Size)
					case color(Color)
				}
				
				enum Size {
					case small
					case large
				}
				
				enum Color {
					case red
					case blue
					case green
				}
			}
			""",
			expandedSource: """
				struct DisplayOptions {
					private enum Options {
						case size(Size)
						case color(Color)
					}
					
					enum Size {
						case small
						case large
					}
					
					enum Color {
						case red
						case blue
						case green
					}

					typealias RawValue = UInt16

					var rawValue: RawValue

					init() {
						self.rawValue = 0
					}

					init(rawValue: RawValue) {
						self.rawValue = rawValue
					}

					static let sizeSmall: Self =
						Self(rawValue: 1 << 0)

					static let sizeLarge: Self =
						Self(rawValue: 1 << 1)

					static let colorRed: Self =
						Self(rawValue: 1 << 2)

					static let colorBlue: Self =
						Self(rawValue: 1 << 3)

					static let colorGreen: Self =
						Self(rawValue: 1 << 4)
				}

				extension DisplayOptions: OptionSet {
				}
				""",
			macros: macros,
			indentationWidth: .spaces(2)
		)
	}
	
	/// Tests that unknown associated value types fall back to simple generation.
	@Test("Falls back to simple generation for unknown associated types")
	func testUnknownAssociatedTypeFallback() {
		assertMacroExpansion(
			"""
			@OptionSet<UInt8>
			struct Config {
				private enum Options {
					case value(ExternalType)
					case flag
				}
			}
			""",
			expandedSource: """
				struct Config {
					private enum Options {
						case value(ExternalType)
						case flag
					}

					typealias RawValue = UInt8

					var rawValue: RawValue

					init() {
						self.rawValue = 0
					}

					init(rawValue: RawValue) {
						self.rawValue = rawValue
					}

					static let value: Self =
						Self(rawValue: 1 << 0)

					static let flag: Self =
						Self(rawValue: 1 << 1)
				}

				extension Config: OptionSet {
				}
				""",
			macros: macros,
			indentationWidth: .spaces(2)
		)
	}
	
	/// Tests associated enum values with public access modifier.
	@Test("Associated enum values with public access modifier")
	func testAssociatedEnumWithPublicAccess() {
		assertMacroExpansion(
			"""
			@OptionSet<UInt8>
			public struct PublicConfig {
				private enum Options {
					case mode(Mode)
				}
				
				enum Mode {
					case auto
					case manual
				}
			}
			""",
			expandedSource: """
				public struct PublicConfig {
					private enum Options {
						case mode(Mode)
					}
					
					enum Mode {
						case auto
						case manual
					}

					public typealias RawValue = UInt8

					public var rawValue: RawValue

					public init() {
						self.rawValue = 0
					}

					public init(rawValue: RawValue) {
						self.rawValue = rawValue
					}

					public  static let modeAuto: Self =
						Self(rawValue: 1 << 0)

					public  static let modeManual: Self =
						Self(rawValue: 1 << 1)
				}

				extension PublicConfig: OptionSet {
				}
				""",
			macros: macros,
			indentationWidth: .spaces(2)
		)
	}
	
	/// Tests associated enum with labeled parameter.
	@Test("Associated enum with labeled parameter")
	func testAssociatedEnumWithLabeledParameter() {
		assertMacroExpansion(
			"""
			@OptionSet<UInt8>
			struct Labeled {
				private enum Options {
					case priority(_ value: Level)
				}
				
				enum Level {
					case low
					case high
				}
			}
			""",
			expandedSource: """
				struct Labeled {
					private enum Options {
						case priority(_ value: Level)
					}
					
					enum Level {
						case low
						case high
					}

					typealias RawValue = UInt8

					var rawValue: RawValue

					init() {
						self.rawValue = 0
					}

					init(rawValue: RawValue) {
						self.rawValue = rawValue
					}

					static let priorityLow: Self =
						Self(rawValue: 1 << 0)

					static let priorityHigh: Self =
						Self(rawValue: 1 << 1)
				}

				extension Labeled: OptionSet {
				}
				""",
			macros: macros,
			indentationWidth: .spaces(2)
		)
	}
	
	/// Tests that property name collisions are resolved with numeric suffixes.
	@Test("Resolves property name collisions with numeric suffixes")
	func testPropertyNameCollisionResolution() {
		assertMacroExpansion(
			"""
			@OptionSet<UInt8>
			struct CollisionTest {
				private enum Options {
					case item(ItemType)
					case itemA
				}
				
				enum ItemType {
					case a
					case b
				}
			}
			""",
			expandedSource: """
				struct CollisionTest {
					private enum Options {
						case item(ItemType)
						case itemA
					}
					
					enum ItemType {
						case a
						case b
					}

					typealias RawValue = UInt8

					var rawValue: RawValue

					init() {
						self.rawValue = 0
					}

					init(rawValue: RawValue) {
						self.rawValue = rawValue
					}

					static let itemA: Self =
						Self(rawValue: 1 << 0)

					static let itemB: Self =
						Self(rawValue: 1 << 1)

					static let itemA1: Self =
						Self(rawValue: 1 << 2)
				}

				extension CollisionTest: OptionSet {
				}
				""",
			macros: macros,
			indentationWidth: .spaces(2)
		)
	}
	
	/// Tests that various BinaryInteger types work as RawValue.
	@Test("Supports various BinaryInteger types")
	func testBinaryIntegerSupport() {
		assertMacroExpansion(
			"""
			@OptionSet<UInt>
			struct LargeOptions {
				private enum Options: Int {
					case flag1
					case flag2
				}
			}
			""",
			expandedSource: """
				struct LargeOptions {
					private enum Options: Int {
						case flag1
						case flag2
					}

					typealias RawValue = UInt

					var rawValue: RawValue

					init() {
						self.rawValue = 0
					}

					init(rawValue: RawValue) {
						self.rawValue = rawValue
					}

					static let flag1: Self =
						Self(rawValue: 1 << Options.flag1.rawValue)

					static let flag2: Self =
						Self(rawValue: 1 << Options.flag2.rawValue)
				}

				extension LargeOptions: OptionSet {
				}
				""",
			macros: macros,
			indentationWidth: .spaces(2)
		)
	}
}
#endif
