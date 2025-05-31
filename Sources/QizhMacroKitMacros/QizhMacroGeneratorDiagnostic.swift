//
//  QizhMacroGeneratorDiagnostic.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 08.10.2024.
//


/// Custom DiagnosticMessage implementation
public struct QizhMacroGeneratorDiagnostic: DiagnosticMessage {
	public let message: String
	public let diagnosticID: MessageID
	public let severity: DiagnosticSeverity

	public init(
		message: String,
		id messageID: String,
		severity: DiagnosticSeverity
	) {
		self.message = message
		self.diagnosticID = MessageID(domain: "QizhKitMacros", id: messageID)
		self.severity = severity
	}
	
	/// Error Diagnostic
	@inlinable public init(
		_ message: String,
		id messageID: String = "InvalidUsage",
		severity: DiagnosticSeverity = .error
	) {
		self.init(message: message, id: "InvalidUsage", severity: .error)
	}
}

extension Diagnostic {
	public static func error(
		node: some SyntaxProtocol,
		message: String,
		id messageID: String
	) -> Diagnostic {
		Diagnostic(
			node: node,
			message: QizhMacroGeneratorDiagnostic(
				message: message,
				id: messageID,
				severity: .error
			)
		)
	}
	
	public static func warning(
		node: some SyntaxProtocol,
		message: String,
		id messageID: String
	) -> Diagnostic {
		Diagnostic(
			node: node,
			message: QizhMacroGeneratorDiagnostic(
				message: message,
				id: messageID,
				severity: .warning
			)
		)
	}
	
	public static func note(
		node: some SyntaxProtocol,
		message: String,
		id messageID: String
	) -> Diagnostic {
		Diagnostic(
			node: node,
			message: QizhMacroGeneratorDiagnostic(
				message: message,
				id: messageID,
				severity: .note
			)
		)
	}
	
	public static func remark(
		node: some SyntaxProtocol,
		message: String,
		id messageID: String
	) -> Diagnostic {
		Diagnostic(
			node: node,
			message: QizhMacroGeneratorDiagnostic(
				message: message,
				id: messageID,
				severity: .remark
			)
		)
	}
}
