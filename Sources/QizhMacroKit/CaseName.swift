//
//  CaseName.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 08.10.2024.
//

@attached(member, names: arbitrary)
public macro CaseName(snakeCase: Bool = false) = #externalMacro(module: "QizhMacroKitMacros", type: "CaseNameGenerator")
