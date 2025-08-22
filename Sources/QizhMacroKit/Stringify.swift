//
//  Stringify.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 22.08.2025.
//

/// - Returns: Just the source text of the expression as a `String`
@freestanding(expression)
public macro stringify<T>(_ value: T) -> String = #externalMacro(module: "QizhMacroKitMacros", type: "StringifyGenerator")

/// - Returns: `(value: T, string: String)`
@freestanding(expression)
public macro stringifyAndCalculate<T>(_ value: T) -> (value: T, string: String) = #externalMacro(module: "QizhMacroKitMacros", type: "StringifyAndCalculateGenerator")
