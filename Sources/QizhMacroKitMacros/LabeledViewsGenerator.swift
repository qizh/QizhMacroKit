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
public struct LabeledViewsMacro: BodyMacro {
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
		providingBodyFor declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {
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
	
	/*
	public static func expansion(
		of node: AttributeSyntax,
		providingBodyFor declaration: some DeclSyntaxProtocol, // ← loosen here
		in context: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {

		/// Support accessor bodies (getter), functions, inits, etc.
		
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
			
			/// Subscripts don’t have a direct body; they have an accessor block.
			
			if let block = subscriptDecl.accessorBlock {
				switch block.accessors {
				case .getter(let getterStatements):
					/// In SwiftSyntax 601.x, `.getter` carries `CodeBlockItemListSyntax`
					/// (statements), not `CodeBlockSyntax`. Wrap the statements
					/// into a `CodeBlockSyntax` before passing to `rewrite`.
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
			// throw MacroError.message("Expected a declaration with a body (getter/func/init/deinit/subscript).")
		}
	}
	*/

	/*
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
		/*
		let wrapped: CodeBlockItemSyntax = .init(item: .expr(ExprSyntax("LabeledViews {\n\(CodeBlockItemListSyntax(items))\n}")))
		return [wrapped]
		*/
		
		/*
		/// Build: LabeledViews { <items...> }
		let innerList = CodeBlockItemListSyntax(items)
		let closure = ClosureExprSyntax(statements: innerList)
		let callee = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("LabeledViews")))
		var call = FunctionCallExprSyntax(callee: callee, argumentList: TupleExprElementListSyntax([]))
		call.trailingClosure = closure
		let wrapped: CodeBlockItemSyntax = .init(item: .expr(ExprSyntax(call)))
		return [wrapped]
		*/
		
		/// Build: LabeledViews { <items...> }
		let innerList = CodeBlockItemListSyntax(items)
		let closure = ClosureExprSyntax {
			innerList
		}
		let callee = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("LabeledViews")))
		// Use the builder-style initializer for arguments (none here) and set trailingClosure.
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
	*/
	
	/*
	public static func expansion(
		of node: AttributeSyntax,
		providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
		in context: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {

		// 1) Grab the original statements in the target body (func/getter/etc.)
		guard let originalBody = declaration.body else {
			// No body to rewrite — return empty and let the compiler complain.
			return []
		}

		let statements = originalBody.statements

		// 2) Transform each top-level expression statement like `firstName`
		//    into `firstName.labeledView(label: "firstName")`.
		//    We preserve the *source text* to use as the label.
		var transformedItems: [CodeBlockItemSyntax] = []

		for item in statements {
			// Try to see if this code block item is an expression.
			if let exprStmt = item.item.as(ExprSyntax.self) {
				let sourceLabel: String = {
					// Use the exact source text for the label, if available.
					if let _ = context.location(of: exprStmt, at: .afterLeadingTrivia, filePathMode: .fileID),
					   let text = context.sourceText(in: exprStmt) {
						// Trim whitespace/newlines
						return text.trimmingCharacters(in: .whitespacesAndNewlines)
					} else {
						// Fallback to a printed form if source text isn't available.
						return exprStmt.description.trimmingCharacters(in: .whitespacesAndNewlines)
					}
				}()
				
				// Build: (<original_expr>).labeledView(label: "<source>")
				let rewritten: ExprSyntax = "(\(exprStmt)).labeledView(label: \(literal: sourceLabel))"

				transformedItems.append(CodeBlockItemSyntax(item: .expr(rewritten)))
			} else {
				// Non-expression lines (e.g., let x = ...) are passed through unchanged.
				transformedItems.append(item)
			}
		}

		// 3) Build a single expression statement that wraps all transformed lines
		//    inside `LabeledViews { ... }`.
		//
		//    We emit:
		//    LabeledViews {
		//       line1
		//       line2
		//       ...
		//    }
		let bodyItems = CodeBlockItemListSyntax(transformedItems)

		let wrapped: CodeBlockItemSyntax = CodeBlockItemSyntax(
			item: .expr(ExprSyntax("LabeledViews {\n\(bodyItems)\n}"))
		)

		// Replace the entire body with a single wrapped statement.
		return [wrapped]
	}
	*/
}

/*
/// Small helper: fetch the exact source text of a node when available.
/// This is not part of the public API; we use the expansion context’s
/// location APIs to read text slices when possible.
extension MacroExpansionContext {
	func sourceText(in node: SyntaxProtocol) -> String? {
		guard !node.root.description.isEmpty else { return nil }
		/// As of swift-syntax 601.x there isn't a direct "slice" API exposed via context;
		/// relying on printing the exact node usually suffices for simple expressions.
		/// If you adopt SourceFileSyntax + Trivia handling you can get more precise slices.
		return node.description
	}
}
*/
