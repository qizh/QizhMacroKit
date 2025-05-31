//
//  CaseValue.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 31.05.2025.
//

@attached(member, names: arbitrary)
public macro CaseValue() = #externalMacro(module: "QizhMacroKitMacros", type: "CaseValueGenerator")
