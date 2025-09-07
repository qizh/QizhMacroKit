//
//  File.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 07.09.2025.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftDiagnostics
import SwiftCompilerPlugin
import SwiftSyntaxMacros

// public struct LabeledViewsMacro: BodyMacro, PeerMacro, AccessorMacro {
public struct LabeledViewsMacro: BodyMacro, AccessorMacro {
	/*
	public static func expansion(
		of node: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		/// This macro does not need to synthesize any peer declarations.
		/// All functionality is implemented via body rewriting.
		
		context.diagnose(
			.note(
				node: Syntax(node),
				message: "This macro does not need to synthesize any peer declarations. All functionality is implemented via body rewriting.",
				id: "MissingSubscriptGetterBody"
			)
		)
		
		return []
	}
	
	public static func expansion(
		of node: AttributeSyntax,
		providingAccessorsOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [AccessorDeclSyntax] {
		/// No additional accessors are synthesized. The body macro handles
		/// rewriting existing getter bodies where applicable.
		
		context.diagnose(
			.note(
				node: Syntax(node),
				message: "No additional accessors are synthesized. The body macro handles rewriting existing getter bodies where applicable.",
				id: "MissingSubscriptGetterBody"
			)
		)
		
		return []
	}
	*/
	
	/// Optional: keep macro output formatting mostly intact.
	public static var formatMode: FormatMode { .auto }
	
	public static func expansion(
		of node: AttributeSyntax,
		providingAccessorsOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [AccessorDeclSyntax] {
		context.diagnose(
			.note(
				node: declaration,
				message: """
					Rewriting accessor
					┣ declaration: \(declaration)
					┃ ┣ kind: \(declaration.kind)
					┃ ┣ type: \(declaration.syntaxNodeType)
					┃ ┣ description: \(declaration.description)
					┃ ┗ debug description: \(declaration.debugDescription)
					┗→ ...
					""",
				id: "RewiringDeclaration"
			)
		)
		
		// We only care about variable declarations. Stored properties are ignored.
		guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
			return []
		}
		
		// Find the first binding that has an accessor block (i.e., computed property).
		guard let binding = varDecl.bindings.first(where: { $0.accessorBlock != nil }) else {
			// No accessor block means this is likely a stored property; nothing to do.
			return []
		}
		
		guard let accessorBlock = binding.accessorBlock else {
			return []
		}
		
		// Some toolchains may expose the shorthand getter as a bare CodeBlockItemListSyntax
		// without wrapping it in the `.getter` enum case. Handle that first.
		if let shorthandItems = accessorBlock.accessors.as(CodeBlockItemListSyntax.self) {
			let syntheticBody = CodeBlockSyntax(
				leftBrace: .leftBraceToken(),
				statements: shorthandItems,
				rightBrace: .rightBraceToken()
			)
			let rewrittenItems = rewrite(body: syntheticBody, context: context)
			let rewrittenBody = CodeBlockSyntax(
				leftBrace: .leftBraceToken(),
				statements: CodeBlockItemListSyntax(rewrittenItems),
				rightBrace: .rightBraceToken()
			)
			let getAccessor = AccessorDeclSyntax(
				accessorSpecifier: .keyword(.get),
				body: rewrittenBody
			)
			return [getAccessor]
		}
		
		switch accessorBlock.accessors {
		case .getter(let getterStatements):
			// The getter is represented as raw statements. Wrap them using our rewrite helper.
			let syntheticBody = CodeBlockSyntax(
				leftBrace: .leftBraceToken(),
				statements: getterStatements,
				rightBrace: .rightBraceToken()
			)
			let rewrittenItems = rewrite(body: syntheticBody, context: context)
			let rewrittenBody = CodeBlockSyntax(
				leftBrace: .leftBraceToken(),
				statements: CodeBlockItemListSyntax(rewrittenItems),
				rightBrace: .rightBraceToken()
			)
			// Use initializer that accepts a body: CodeBlockSyntax
			let getAccessor = AccessorDeclSyntax(
				accessorSpecifier: .keyword(.get),
				body: rewrittenBody
			)
			return [getAccessor]
			
		case .accessors(let list):
			// Replace the get accessor body, preserve all other accessors.
			var newAccessors: [AccessorDeclSyntax] = []
			var foundGetter = false
			
			for accessor in list {
				if accessor.accessorSpecifier.tokenKind == .keyword(.get) {
					if let body = accessor.body {
						let rewrittenItems = rewrite(body: body, context: context)
						let rewrittenBody = CodeBlockSyntax(
							leftBrace: .leftBraceToken(),
							statements: CodeBlockItemListSyntax(rewrittenItems),
							rightBrace: .rightBraceToken()
						)
						
						var newGetter = accessor
						newGetter.body = rewrittenBody
						newAccessors.append(newGetter)
						foundGetter = true
					} else {
						// Getter without body → diagnose and synthesize an empty body.
						context.diagnose(
							.error(
								node: Syntax(node),
								message: "Getter must have a body for @LabeledViews to rewrite.",
								id: "MissingGetterBody"
							)
						)
						var newGetter = accessor
						newGetter.body = CodeBlockSyntax(
							leftBrace: .leftBraceToken(),
							statements: CodeBlockItemListSyntax([]),
							rightBrace: .rightBraceToken()
						)
						newAccessors.append(newGetter)
						foundGetter = true
					}
				} else {
					// Keep other accessors (set, willSet, didSet) unchanged.
					newAccessors.append(accessor)
				}
			}
			
			if !foundGetter {
				context.diagnose(
					.error(
						node: Syntax(node),
						message: "Computed property must have a getter for @LabeledViews to rewrite.",
						id: "MissingGetterAccessor"
					)
				)
				return []
			}
			
			return newAccessors
		}
	}
	
	public static func expansion(
		of node: AttributeSyntax,
		providingBodyFor closure: ClosureExprSyntax,
		in context: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {
		// ClosureExprSyntax conforms to WithStatementsSyntax (see SyntaxTraits.swift),
		// so we can synthesize a CodeBlockSyntax from its statements and reuse rewrite.
		let syntheticBody = CodeBlockSyntax(
			leftBrace: .leftBraceToken(),
			statements: closure.statements,
			rightBrace: .rightBraceToken()
		)
		return rewrite(body: syntheticBody, context: context)
	}
	
	public static func expansion(
		of node: AttributeSyntax,
		providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
		in context: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {
		context.diagnose(
			.note(
				node: declaration,
				message: """
					Rewriting 
					┣ declaration: \(declaration)
					┃ ┣ kind: \(declaration.kind)
					┃ ┣ type: \(declaration.syntaxNodeType)
					┃ ┣ description: \(declaration.description)
					┃ ┗ bebug description: \(declaration.debugDescription)
					┣ body: \(declaration.body)
					┃ ┣ kind: \(declaration.body?.kind)
					┃ ┣ type: \(declaration.body?.syntaxNodeType)
					┃ ┣ description: \(declaration.body?.description)
					┃ ┗ bebug description: \(declaration.body?.debugDescription)
					┗→ ...
					""",
				id: "RewiringDeclaration"
			)
		)
		
		// Support accessor bodies (getter), functions, inits, deinit, and subscripts.
		if let accessor = declaration.as(AccessorDeclSyntax.self),
		   let body = accessor.body {
			return rewrite(body: body, context: context)
		} else if let funcDecl = declaration.as(FunctionDeclSyntax.self),
				  let body = funcDecl.body {
			return rewrite(body: body, context: context)
		} else if let initDecl = declaration.as(InitializerDeclSyntax.self),
				  let body = initDecl.body {
			return rewrite(body: body, context: context)
		} else if let deinitDecl = declaration.as(DeinitializerDeclSyntax.self),
				  let body = deinitDecl.body {
			return rewrite(body: body, context: context)
		} else if let subscriptDecl = declaration.as(SubscriptDeclSyntax.self) {
			// Subscripts don’t have a direct body; they have an accessor block.
			if let block = subscriptDecl.accessorBlock {
				switch block.accessors {
				case .getter(let getterStatements):
					let syntheticBody = CodeBlockSyntax(
						leftBrace: .leftBraceToken(),
						statements: getterStatements,
						rightBrace: .rightBraceToken()
					)
					return rewrite(body: syntheticBody, context: context)
				case .accessors(let list):
					if let getter = list.first(where: { $0.accessorSpecifier.tokenKind == .keyword(.get) }),
					   let getterBody = getter.body {
						return rewrite(body: getterBody, context: context)
					}
				}
			}
			context.diagnose(
				.error(
					node: Syntax(node),
					message: "Subscript must have a getter body for @LabeledViews to rewrite.",
					id: "MissingSubscriptGetterBody"
				)
			)
			return []
		} else {
			context.diagnose(
				.error(
					node: Syntax(node),
					message: "Expected a declaration with a body (getter/func/init/deinit/subscript).",
					id: "InvalidBodyTypeDeclaration"
				)
			)
			return []
		}
	}

	private static func rewrite(
		body: CodeBlockSyntax,
		context: some MacroExpansionContext
	) -> [CodeBlockItemSyntax] {
		var items: [CodeBlockItemSyntax] = []
		for item in body.statements {
			if let expr = item.item.as(ExprSyntax.self) {
				let label = expr.description.trimmingCharacters(in: .whitespacesAndNewlines)
				let rewritten: ExprSyntax = "(\(expr)).labeledView(label: \(literal: label))"
				items.append(.init(item: .expr(rewritten)))
			} else {
				items.append(item)
			}
		}

		// Build: LabeledViews { <items...> }
		let innerList = CodeBlockItemListSyntax(items)
		let closure = ClosureExprSyntax {
			innerList
		}
		let callee = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("LabeledViews")))
		let call = FunctionCallExprSyntax(
			calledExpression: callee,
			leftParen: nil,
			rightParen: nil,
			trailingClosure: closure
		) {
			LabeledExprListSyntax([])
		}
		let wrapped: CodeBlockItemSyntax = .init(item: .expr(ExprSyntax(call)))
		return [wrapped]
	}
}

