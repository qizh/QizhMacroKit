//
//  IsCasesGenerator.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 08.10.2024.
//

import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

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
        // Collect all enum case elements across all case declarations
        let caseDecls = members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
        let allCaseElements: [EnumCaseElementSyntax] = caseDecls.flatMap { Array($0.elements) }
		var additions: [DeclSyntax] = []
		var caseNames: [String] = []
		
		let allModifiers = enumDecl.modifiers.map(\.name.text)
		let accessControlSet: Set<String> = ["open", "public", "package", "internal", "fileprivate", "private"]
		let accessModifiers = allModifiers.filter { accessControlSet.contains($0) }
		let modifiersString: String = accessModifiers.isEmpty
			? ""
			: accessModifiers.joined(separator: " ") + " "
		
		if allCaseElements.isEmpty {
			context.diagnose(
				Diagnostic.warning(
					node: Syntax(node),
					message: "There are no cases in the enum, so `@IsCase` can NOT be applied. You may want to add a case.",
					id: .noEnumCases
				)
			)
			return []
		} else if allCaseElements.count == 1 {
			// Exactly one case element across the entire enum
			let element = allCaseElements[0]
			let caseName = element.name.text.withBackticksTrimmed
			caseNames.append(caseName)
			let escapedCaseName = caseName.escapedSwiftIdentifier
			let propertyName = "is\(caseName.prefix(1).uppercased())\(caseName.dropFirst())"
			
			let property: DeclSyntax = """
				/// Always return `true` because `self` has just `.\(raw: escapedCaseName)` case.
				\(raw: modifiersString)var \(raw: propertyName): Bool {
					true
				}
				"""
			additions.append(property)
		} else {
			// Iterate over each collected case element
			for element in allCaseElements {
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
			\(raw: modifiersString)enum Cases: Equatable, CaseIterable {
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
			\(raw: modifiersString)var parametersErasedCase: Cases {
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
				cases.contains(self.parametersErasedCase)
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

