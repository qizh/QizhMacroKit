//
//  Labeled.swift
//  QizhMacroKit
//
//  Created by OpenAI ChatGPT on 13.01.2025.
//

/// Converts an array literal into an ``OrderedDictionary`` whose keys are derived from the variable names in the array elements.
///
/// Usage:
/// ```swift
/// let firstName = "John"
/// let lastName = "Doe"
/// let dict = #Labeled([firstName, lastName])
/// // Expands to: ["firstName": firstName, "lastName": lastName]
/// ```
@freestanding(expression)
public macro Labeled<T>(_ array: [T]) -> OrderedDictionary<String, T> = #externalMacro(module: "QizhMacroKitMacros", type: "LabeledGenerator")

@_exported import OrderedCollections

