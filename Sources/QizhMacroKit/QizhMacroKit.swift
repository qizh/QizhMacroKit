@attached(member, names: arbitrary)
public macro IsCase() = #externalMacro(module: "QizhMacroKitMacros", type: "IsCasesGenerator")

@attached(member, names: arbitrary)
public macro CaseName() = #externalMacro(module: "QizhMacroKitMacros", type: "CaseNameGenerator")
