//
//  OptionSet.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 08.12.2025.
//

import Foundation
import QizhMacroKit

/// Demonstrates the `@OptionSet` macro with business color application flags.
///
/// This option set defines mutually combinable color application modes
/// that can be used together (e.g., `[.tint, .accent]`).
///
/// - Note: Uses `UInt8` as the raw type for compact storage.
@OptionSet<UInt8>
internal struct BusinessColorApplications: Sendable {
	private enum Options: UInt8, Sendable {
		case tint
		case tintGradient
		case accent
	}
}
