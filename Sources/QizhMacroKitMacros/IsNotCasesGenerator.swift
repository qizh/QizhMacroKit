//
//  IsNotCasesGenerator.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 06.02.2025.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

/// Macro implementation for `@IsNotCase`.
///
/// Generates negated boolean computed properties for each enum case.
/// These properties return `true` when the value does NOT match the case.
///
/// ## Generated Properties
///
/// For each case, generates:
/// - `isNot<CaseName>: Bool` - Returns `true` if the value does NOT match this case
///
/// ## Example
///
/// ```swift
/// @IsNotCase
/// enum Permission {
///     case granted
///     case denied
///     case notDetermined
/// }
///
/// let permission = Permission.notDetermined
/// if permission.isNotGranted {
///     requestPermission()
/// }
/// ```
///
/// ## Implementation Details
///
/// - Validates the declaration is an enum
/// - Generates properties with proper access control
/// - Handles cases with and without associated values
/// - Property names follow `isNot<CaseName>` convention
///
/// - SeeAlso: `@IsCase` for positive case checking
public struct IsNotCasesGenerator: MemberMacro {
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
					message: "@IsNotCase can only be applied to enums",
					id: .invalidUsage,
					severity: .error
				)
			)
			context.diagnose(error)
			return []
		}
		
		let members = enumDecl.memberBlock.members
		var computedProperties: [DeclSyntax] = []
		
		let allModifiers = enumDecl.modifiers.map(\.name.text)
		let accessControlSet: Set<String> = ["open", "public", "package", "internal", "fileprivate", "private"]
		let accessModifiers = allModifiers.filter { accessControlSet.contains($0) }
		let modifiersString: String = accessModifiers.isEmpty
			? ""
			: accessModifiers.joined(separator: " ") + " "
		
		/// Iterate over each case in the enum
		for member in members {
			guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
				continue
			}
			
			for element in enumCaseDecl.elements {
				let caseName = element.name.text.withBackticksTrimmed
				let propertyName = "isNot\(caseName.prefix(1).uppercased())\(caseName.dropFirst())"
				
				let property: DeclSyntax = """
				\(raw: modifiersString)var \(raw: propertyName): Bool {
					switch self {
					case .\(raw: caseName): false
					default: true
					}
				}
				"""
				computedProperties.append(property)
			}
		}
		return computedProperties
	}
}
