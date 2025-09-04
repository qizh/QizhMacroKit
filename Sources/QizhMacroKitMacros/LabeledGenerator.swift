//
//  LabeledGenerator.swift
//  QizhMacroKit
//
//  Created by OpenAI ChatGPT on 13.01.2025.
//

/// Attribute macro that transforms an array literal into an ``OrderedDictionary`` whose keys are derived from the element expressions.
public struct LabeledGenerator: DeclarationMacro {
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

        let modifiers = varDecl.modifiers?.description ?? ""
        let specifier = varDecl.bindingSpecifier.text
        let result = "\(modifiers)\(specifier) \(patternText): \(dictType) = [\n\t\t\(body)\n]"
        return ["\(raw: result)"]
    }
}

