//
//  Stringify.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 22.08.2025.
//

/// Create an option set from a struct that contains a nested `Options` enum.
///
/// Attach this macro to a struct that contains a nested `Options` enum
/// with an integer raw value. The struct will be transformed to conform to
/// `OptionSet` by
/// - 1. Introducing a `rawValue` stored property to track which options are set,
///   along with the necessary `RawType` typealias and initializers to satisfy
///   the `OptionSet` protocol.
/// - 2. Introducing static properties for each of the cases within the `Options`
///   enum, of the type of the struct.
/// ## Example
/// ```swift
/// @OptionSet<UInt8>
/// struct ColorApplications {
/// 	private enum Options: UInt8 {
/// 		case tint
/// 		case tintGradient
/// 		case accent
/// 	}
/// }
/// ```
/// - Precondition:
///   The `Options` enum must have a raw value, where its case elements
///   each indicate a different option in the resulting option set. For example,
///   the struct and its nested `Options` enum could look like this:
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
