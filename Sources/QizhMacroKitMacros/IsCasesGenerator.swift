//
//  IsCasesGenerator.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 08.10.2024.
//

public struct IsCasesGenerator: MemberMacro {
        public static func expansion(
                of node: AttributeSyntax,
                providingMembersOf declaration: some DeclGroupSyntax,
                conformingTo protocols: [TypeSyntax],
                in context: some MacroExpansionContext
        ) throws -> [DeclSyntax] {

                /// Ensure the declaration is an enum
                guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
                        let error = Diagnostic(
                                node: Syntax(node),
                                message: QizhMacroGeneratorDiagnostic(
                                        message: "@IsCase can only be applied to enums",
                                        id: .invalidUsage,
                                        severity: .error
                                )
                        )
                        context.diagnose(error)
                        return []
                }

                let members = enumDecl.memberBlock.members
                var additions: [DeclSyntax] = []
                var caseNames: [String] = []

                let modifiers = enumDecl.modifiers
                        .map(\.name.text)

                let modifiersString: String = modifiers.isEmpty ? "" : modifiers.joined(separator: " ") + " "

                /// Iterate over each case in the enum
                for member in members {
                        guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
                                continue
                        }

                        for element in enumCaseDecl.elements {
                                let caseName = element.name.text.withBackticksTrimmed
                                caseNames.append(caseName)
                                let escapedCaseName = caseName.escapedSwiftIdentifier
                                let propertyName = "is\(caseName.prefix(1).uppercased())\(caseName.dropFirst())"

                                let property: DeclSyntax = """
                                /// Returns `true` if `self` is `.\(raw: escapedCaseName)`.
                                \(raw: modifiersString)var \(raw: propertyName): Bool {
                                        switch self {
                                        case .\(raw: escapedCaseName): true
                                        default: false
                                        }
                                }
                                """
                                additions.append(property)
                        }
                }

                // Generate Cases enum
                let casesLines = caseNames
                        .map { "        case \($0.escapedSwiftIdentifier)" }
                        .joined(separator: "\n")
                let casesDecl: DeclSyntax = """
                /// A parameterless representation of `\(raw: enumDecl.name.text)` cases.
                \(raw: modifiersString)enum Cases: Equatable {
                \(raw: casesLines)
                }
                """

                // Property converting self to Cases
                let mappingLines = caseNames
                        .map { name in
                                let escaped = name.escapedSwiftIdentifier
                                return "        case .\(escaped): .\(escaped)"
                        }
                        .joined(separator: "\n")
                let caseValueProperty: DeclSyntax = """
                /// A parameterless representation of this case.
                private var caseValue: Cases {
                        switch self {
                \(raw: mappingLines)
                        }
                }
                """

                // Methods for checking membership
                let arrayMethod: DeclSyntax = """
                /// Returns `true` if `self` matches any case in `cases`.
                /// - Parameter cases: An array of cases to match against.
                \(raw: modifiersString)func isAmong(_ cases: [Cases]) -> Bool {
                        cases.contains(self.caseValue)
                }
                """

                let variadicMethod: DeclSyntax = """
                /// Returns `true` if `self` matches any of the provided cases.
                /// - Parameter cases: The cases to match against.
                \(raw: modifiersString)func isAmong(_ cases: Cases...) -> Bool {
                        isAmong(cases)
                }
                """

                additions.append(casesDecl)
                additions.append(caseValueProperty)
                additions.append(arrayMethod)
                additions.append(variadicMethod)
                return additions
        }
}
