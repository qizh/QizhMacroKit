//
//  OptionSet.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 22.08.2025.
//

/// Create an option set from a struct that contains a nested `Options` enum.
///
/// Attach this macro to a struct that contains a nested `Options` enum
/// with an integer raw value. The struct will be transformed to conform to
/// `OptionSet` by:
///
/// 1. Introducing a `rawValue` stored property to track which options are set,
///    along with the necessary `RawType` typealias and initializers to satisfy
///    the `OptionSet` protocol.
/// 2. Introducing static properties for each of the cases within the `Options`
///    enum, of the type of the struct.
///
/// ## Basic Example
///
/// ```swift
/// @OptionSet<UInt8>
/// struct ColorApplications {
///     private enum Options: UInt8 {
///         case tint
///         case tintGradient
///         case accent
///     }
/// }
/// // Generated: .tint, .tintGradient, .accent
/// ```
///
/// ## Associated Enum Values
///
/// Cases in the `Options` enum can have associated values of nested enum types.
/// The macro will generate a static property for each case of the associated enum,
/// combining the option case name with the enum case name in camelCase.
///
/// ```swift
/// @OptionSet<UInt8>
/// struct Configuration {
///     private enum Options {
///         case level(Priority)      // Associated enum type
///         case enabled              // Simple case
///     }
///
///     enum Priority {
///         case low
///         case medium
///         case high
///     }
/// }
/// // Generated: .levelLow, .levelMedium, .levelHigh, .enabled
/// ```
///
/// - Note: Associated value types must be nested enums within the same struct.
///   External types or non-enum associated values fall back to simple generation.
///
/// - Precondition:
///   The `Options` enum must have a raw value, where its case elements
///   each indicate a different option in the resulting option set.
@attached(member, names: arbitrary)
@attached(extension, conformances: OptionSet)
public macro OptionSet<RawType>() =
	#externalMacro(module: "QizhMacroKitMacros", type: "OptionSetGenerator")

/// Failed attempt to use the implementation directly from `swift-syntax` examples.
/*
import SwiftSyntaxMacros

@attached(member, names: named(RawValue), named(rawValue), named(`init`), arbitrary)
@attached(extension, conformances: OptionSet)
public macro OptionSet<RawType>() =
	#externalMacro(
		module: "SwiftSyntaxMacros",    /// from the swift-syntax package
		type: "OptionSetMacro"
	)
*/
