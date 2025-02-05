//
//  IsCase.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 08.10.2024.
//

@attached(member, names: arbitrary)
public macro IsCase() = #externalMacro(module: "QizhMacroKitMacros", type: "IsCasesGenerator")
