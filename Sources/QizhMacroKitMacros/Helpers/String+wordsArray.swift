//
//  String+wordsArray.swift
//  QizhKit
//
//  Created by Serhii Shevchenko on 30.12.2024.
//  Copyright © 2024 Serhii Shevchenko. All rights reserved.
//

import Foundation
import RegexBuilder

fileprivate struct Regexes {
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
	fileprivate static var words: Regex<Substring> {
		Regex {
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
				OneOrMore { #/\d/# }
			}
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
	
	/// Matches words in any language and any case, lowercases them,
	/// and joines with provided separator
	/// - Parameter separator: String to join the words with
	/// - Returns: Lowercased words joined with the separator
	internal func toLocalizedLowercasedWords(joinedBy separator: String) -> String {
		self.toWordsArray()
			.joined(separator: separator)
	}
	
	/// Splits the string into an array of lowercase words
	/// detected by a Unicode-aware word regex.
	/// Handles words in any language and case,
	/// breaking on transitions between character classes.
	///
	/// - Example:
	/// 	```swift
	///     "someCamelCase123".toWordsArray() // ["some", "camel", "case", "123"]
	///     ```
	///
	/// - Returns: An array of localized lowercased words extracted from the string.
	internal func toWordsArray() -> [String] {
		self.matches(of: Regexes.words)
			.map(\.localizedLowercase)
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
