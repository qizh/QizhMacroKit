//
//  String+swiftKeywordEscaping.swift
//  QizhMacroKit
//
//  Created by AI Assistant on 2024.
//

import Foundation

private let swiftKeywords: Set<String> = [
        "associatedtype", "class", "deinit", "enum", "extension", "func",
        "import", "init", "inout", "internal", "let", "operator", "private",
        "protocol", "public", "static", "struct", "subscript", "typealias",
        "var", "break", "case", "catch", "continue", "default", "defer",
        "do", "else", "fallthrough", "for", "guard", "if", "in", "repeat",
        "return", "throw", "throws", "rethrows", "where", "while", "as",
        "is", "try", "super", "self", "any", "switch", "macro",
        "actor", "await", "async", "final", "open", "some"
]

extension String {
        /// Returns the string wrapped in backticks if it is a Swift reserved keyword.
        internal var escapedSwiftIdentifier: String {
                swiftKeywords.contains(self.lowercased()) ? "`\(self)`" : self
        }
}
