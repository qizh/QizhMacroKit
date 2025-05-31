//
//  String+camelSnakeConvert.swift
//  QizhKit
//
//  Created by Serhii Shevchenko on 30.12.2024.
//  Copyright © 2024 Serhii Shevchenko. All rights reserved.
//

import Foundation
import RegexBuilder

fileprivate actor Regexes {
	fileprivate static let beforeLargeCharacterRef = Reference(Substring.self)
	fileprivate static let largeCharacterRef = Reference(Character.self)

	/// Matches a lowercase letter or digit followed by an uppercase letter.
	///
	/// Captures the preceding lowercase letter or digit (as `beforeLargeCharacterRef`)
	/// and the uppercase letter (as `largeCharacterRef`).
	/// Useful for identifying camelCase boundaries when converting between case styles.
	fileprivate static let captureLargeCharactersAfterSmall: Regex = Regex {
		Capture(as: beforeLargeCharacterRef) {
			CharacterClass(
				("a"..."z"),
				("0"..."9")
			)
		}
		TryCapture(as: largeCharacterRef) {
			("A"..."Z")
		} transform: { substring in
			substring.first
		}
	}
	
	/// Matches individual “words” based on Unicode word boundaries.
	///
	/// A word can be:
	///  1. An uppercase letter followed by one or more lowercase letters
	///  	(e.g., “Word”).
	///  2. One or more uppercase letters not followed by a lowercase letter
	///  	(e.g., acronyms like “HTML”).
	///  3. One or more letters of any type (for languages without case distinctions).
	///
	/// Useful for splitting identifiers into their component words
	/// when converting between `camelCase`, `snake_case`, etc.
	fileprivate static let words: Regex = Regex {
		ChoiceOf {
			Regex {
				Optionally { #/\p{Lu}/# }
				OneOrMore { #/\p{Ll}/# }
			}
			Regex {
				OneOrMore { #/\p{Lu}/# }
				NegativeLookahead { #/\p{Ll}/# }
			}
			OneOrMore { #/\p{L}/# }
		}
	}
}

extension String {
	/// Returns a camelCase representation of this string.
	///
	/// Splits the string into words (using Unicode word boundaries),
	/// lowercases the first word,
	/// capitalizes the first letter of each subsequent word,
	/// and concatenates them without separators.
	internal var toCamelCase: String {
		self.matches(of: Regexes.words)
			.enumerated()
			.map { index, part in
				if index == 0 {
					part.localizedLowercase
				} else {
					part.localizedCapitalized
				}
			}
			.joined()
	}
	
	/// Returns a `PascalCase` representation of this string.
	///
	/// Splits the string into words (using Unicode word boundaries) and capitalizes the first letter of each word,
	/// then concatenates them without separators.
	internal var toPascalCase: String {
		self.matches(of: Regexes.words)
			.map(\.localizedCapitalized)
			.joined()
	}
	
	/// Splits the string into words (using Unicode word boundaries),
	/// lowercases each word according to the current locale,
	/// and joins them with the given separator.
	///
	/// - Parameter separator: The string to insert between each lowercased word.
	/// - Returns: A string composed of the original words lowercased and joined by `separator`.
	internal func toLocalizedLowercasedWords(joinedBy separator: String) -> String {
		self.matches(of: Regexes.words)
			.map(\.localizedLowercase)
			.joined(separator: separator)
	}
	
	/// Returns a `snake_case` representation of this string.
	///
	/// Splits the string into words (using Unicode word boundaries),
	/// lowercases each word, and joins them using underscores.
	internal var toSnakeCase: String {
		self.toLocalizedLowercasedWords(joinedBy: "_")
	}
	
	/// Returns a `kebab-case` representation of this string.
	///
	/// Splits the string into words (using Unicode word boundaries),
	/// lowercases each word, and joins them using hyphens.
	internal var toKebabCase: String {
		self.toLocalizedLowercasedWords(joinedBy: "-")
	}
	
	/// Returns a `dot.case` representation of this string.
	///
	/// Splits the string into words (using Unicode word boundaries),
	/// lowercases each word, and joins them using periods.
	internal var toDotCase: String {
		self.toLocalizedLowercasedWords(joinedBy: ".")
	}
}
