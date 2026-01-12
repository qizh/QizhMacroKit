//
//  OptionSetPreview.swift
//  QizhMacroKitPreviewSupport
//
//  Copyright © 2025 Serhii Shevchenko. All rights reserved.
//

import Foundation
import QizhMacroKit

// MARK: - Preview Support

/// This module provides preview support for `@OptionSet` macro demonstrations.
/// Extracted into a separate target to avoid requiring `ENABLE_DEBUG_DYLIB`
/// on the main executable target, enabling Xcode canvas previews.

#if DEBUG && canImport(Playgrounds) && swift(>=6.2)
import Playgrounds
import SwiftUI

/// A sample `OptionSet` demonstrating business color application flags.
/// Used for Xcode Playground previews to verify macro expansion.
@OptionSet<UInt8>
internal struct BusinessColorApplications: Sendable {
	private enum Options: UInt8, Sendable {
		case tint
		case tintGradient
		case accent
	}
}

/// Creates a tuple of sample `BusinessColorApplications` values for demonstration.
/// - Returns: A tuple containing `.accent`, `.tint`, and `.tintGradient` options.
@inline(__always)
func demoBusinessColorApplications() -> (BusinessColorApplications, BusinessColorApplications, BusinessColorApplications) {
	(.accent, .tint, .tintGradient)
}

#Playground("OptionSet Demo") {
	let (_, tint, _) = demoBusinessColorApplications()
	var config = BusinessColorApplications()
	if !config.contains(tint) {
		config.insert(tint)
	}
	_ = config.contains(tint)
}
#endif

// MARK: - Advanced OptionSet Example

/// Demonstrates an advanced `@OptionSet` usage pattern with associated values.
///
/// This example shows how to create an `OptionSet` with a custom `Options` enum
/// that uses associated values and custom `RawRepresentable` conformance.
///
/// - Note: This is an experimental pattern showcasing macro flexibility.
@OptionSet<UInt8>
struct DocumentationConfiguration: Sendable {
	/// The current detalization level for documentation output.
	public fileprivate(set) var detalizationValue: Detalization = .default
	
	/// Creates a configuration from a detalization level.
	/// - Parameter detalization: The desired detalization level.
	public init(rawValue detalization: Detalization) {
		self = .init(rawValue: detalization.rawValue)
	}
	
	/// Internal options enum with associated value support.
	/// Demonstrates custom `RawRepresentable` conformance for complex option patterns.
	private enum Options: Hashable, Sendable, CaseIterable, RawRepresentable {
		case detalization(_ volume: Detalization)
		
		public static let detalization: Self = .detalization(.default)
		
		var rawValue: UInt {
			switch self {
			case .detalization(.concise): 1
			case .detalization(.regular): 2
			case .detalization(.detailed): 3
			}
		}
		
		static let allCases: [DocumentationConfiguration.Options] =
			Detalization.allCases.map(DocumentationConfiguration.Options.detalization(_:))
		
		
		init?(rawValue: UInt) {
			if let correspondingCase = Self.allCases.first(where: { $0.rawValue == rawValue }) {
				self = correspondingCase
			} else {
				return nil
			}
		}
		
	}
	
	/// Defines the verbosity level for documentation generation.
	enum Detalization: UInt8, Hashable, Sendable, CaseIterable {
		/// Minimal documentation output.
		case concise
		/// Standard documentation output.
		case regular
		/// Comprehensive documentation with all details.
		case detailed
		
		/// The default detalization level (`.regular`).
		public static let `default`: Self = .regular
	}
}

