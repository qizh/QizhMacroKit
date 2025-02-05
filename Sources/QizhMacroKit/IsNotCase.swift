//
//  IsNotCase.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 06.02.2025.
//

@attached(member, names: arbitrary)
public macro IsNotCase() = #externalMacro(module: "QizhMacroKitMacros", type: "IsNotCasesGenerator")
