//
//  LabeledGenerator.swift
//  QizhMacroKit
//
//  Created by OpenAI ChatGPT on 13.01.2025.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftCompilerPlugin
import SwiftDiagnostics

/// Attribute macro that transforms an array literal into an ``OrderedDictionary`` whose keys are derived from the element expressions.
public struct LabeledGenerator: DeclarationMacro, PeerMacro {
	
	// MARK: A
	
	public static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard let varDecl = VariableDeclSyntax(node) else { return ["/// ⚠️ Not a variable declaration"] }
		guard let binding = varDecl.bindings.first else {
			return [
				"/// ✅ Is a variable declaration",
				"/// ⚠️ First binding is missing",
			]
		}
		guard let arrayExpr = binding.initializer?.value.as(ArrayExprSyntax.self) else {
			return [
				"/// ✅ Is a variable declaration",
				"/// ✅ First binding found",
				"/// ⚠️ Initializer is missing or not an array literal"
			]
		}
		
		let patternText = binding.pattern.description.trimmingCharacters(in: .whitespacesAndNewlines)

		var entries: [String] = []
		for element in arrayExpr.elements {
			let expr = element.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
			let key: String
			if let declRef = element.expression.as(DeclReferenceExprSyntax.self) {
				key = declRef.baseName.text.withBackticksTrimmed
			} else {
				key = expr
			}
			entries.append("\"\(key)\": \(expr)")
		}
		let body = entries.joined(separator: ",\n\t\t")

		let dictType: String
		if let typeAnn = binding.typeAnnotation?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) {
			if typeAnn.hasPrefix("[") && typeAnn.hasSuffix("]") {
				let elementType = String(typeAnn.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
				dictType = "OrderedDictionary<String, \(elementType)>"
			} else {
				dictType = "OrderedDictionary<String, \(typeAnn)>"
			}
		} else {
			dictType = "OrderedDictionary"
		}

		let modifiers = varDecl.modifiers.description
		let specifier = varDecl.bindingSpecifier.text
		let result = "\(modifiers)\(specifier) _A_\(patternText): \(dictType) = [\n\t\t\(body)\n]"
		return ["\(raw: result)"]
	}
	
	// MARK: B
	
    /// Expands the variable declaration annotated with ``@Labeled`` into an ``OrderedDictionary`` initializer.
    /// - Parameters:
    ///   - node: The macro attribute syntax.
    ///   - declaration: The declaration the macro is attached to.
    ///   - context: Contextual information for the macro expansion.
    /// - Returns: Replacement declarations forming an ``OrderedDictionary``.
    public static func expansion(
        of node: AttributeSyntax,
        providingDeclarationsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let arrayExpr = binding.initializer?.value.as(ArrayExprSyntax.self) else {
            return []
        }

        let patternText = binding.pattern.description.trimmingCharacters(in: .whitespacesAndNewlines)

        var entries: [String] = []
        for element in arrayExpr.elements {
            let expr = element.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
            let key: String
            if let declRef = element.expression.as(DeclReferenceExprSyntax.self) {
                key = declRef.baseName.text.withBackticksTrimmed
            } else {
                key = expr
            }
            entries.append("\"\(key)\": \(expr)")
        }
        let body = entries.joined(separator: ",\n\t\t")

        let dictType: String
        if let typeAnn = binding.typeAnnotation?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) {
            if typeAnn.hasPrefix("[") && typeAnn.hasSuffix("]") {
                let elementType = String(typeAnn.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
                dictType = "OrderedDictionary<String, \(elementType)>"
            } else {
                dictType = "OrderedDictionary<String, \(typeAnn)>"
            }
        } else {
            dictType = "OrderedDictionary"
        }

		let modifiers = varDecl.modifiers.description
        let specifier = varDecl.bindingSpecifier.text
        let result = "\(modifiers)\(specifier) _B_\(patternText): \(dictType) = [\n\t\t\(body)\n]"
        return ["\(raw: result)"]
    }
	
	// MARK: C
	
	/// Expands the variable declaration annotated with ``@Labeled`` into an ``OrderedDictionary`` initializer.
	/// - Parameters:
	///   - node: The macro attribute syntax.
	///   - declaration: The declaration the macro is attached to.
	///   - context: Contextual information for the macro expansion.
	/// - Returns: Replacement declarations forming an ``OrderedDictionary`` as a peer.
	public static func expansion(
		of node: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard let varDecl = declaration.as(VariableDeclSyntax.self),
			  let binding = varDecl.bindings.first,
			  let arrayExpr = binding.initializer?.value.as(ArrayExprSyntax.self) else {
			return []
		}
		
		let patternText = binding.pattern.description.trimmingCharacters(in: .whitespacesAndNewlines)
		
		context.diagnose(
			.note(
				node: Syntax(node),
				message: "Found array to apply @Labeled to: «\(patternText)»",
				id: "FoundArrayForLabeledMacro"
			)
		)

		var entries: [String] = []
		for element in arrayExpr.elements {
			let expr = element.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
			let key: String
			if let declRef = element.expression.as(DeclReferenceExprSyntax.self) {
				key = declRef.baseName.text.withBackticksTrimmed
			} else {
				key = expr
			}
			entries.append("\"\(key)\": \(expr)")
		}
		let body = entries.joined(separator: ",\n\t")

		let dictType: String
		if let typeAnn = binding.typeAnnotation?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) {
			if typeAnn.hasPrefix("[") && typeAnn.hasSuffix("]") {
				let elementType = String(typeAnn.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
				dictType = "OrderedDictionary<String, \(elementType)>"
			} else {
				dictType = "OrderedDictionary<String, \(typeAnn)>"
			}
		} else {
			dictType = "OrderedDictionary"
		}

		let modifiers = varDecl.modifiers.description
		let specifier = varDecl.bindingSpecifier.text
		let result = "\(modifiers)\(specifier) _C_\(patternText): \(dictType) = [\n\t\t\(body)\n]"
		return ["\(raw: result)"]
	}
}

