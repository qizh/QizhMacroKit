//
//  QizhMacroGeneratorDiagnostic.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 08.10.2024.
//

// MARK: Diagnostic Message

/// Custom DiagnosticMessage implementation
public struct QizhMacroGeneratorDiagnostic: Error, DiagnosticMessage {
	public let message: String
	public let diagnosticID: MessageID
	public let severity: DiagnosticSeverity
	
	fileprivate let fileID: StaticString
	fileprivate let file: StaticString
	fileprivate let line: UInt
	fileprivate let column: UInt
	
	
	public init(
		message: String,
		id messageID: String,
		severity: DiagnosticSeverity,
		fileID: StaticString = #fileID,
		file: StaticString = #filePath,
		line: UInt = #line,
		column: UInt = #column
	) {
		self.message = message
		self.diagnosticID = MessageID(domain: "QizhKitMacros", id: messageID)
		self.severity = severity
		
		self.fileID = fileID
		self.file = file
		self.line = line
		self.column = column
	}
	
	@inlinable public init(
		message: String,
		id messageID: QizhDiagnosticCode,
		severity: DiagnosticSeverity,
		fileID: StaticString = #fileID,
		file: StaticString = #filePath,
		line: UInt = #line,
		column: UInt = #column
	) {
		self.init(
			message: message,
			id: messageID.rawValue,
			severity: severity,
			fileID: fileID,
			file: file,
			line: line,
			column: column
		)
	}
}

extension QizhMacroGeneratorDiagnostic: CustomStringConvertible {
	@inlinable public var description: String {
		message
	}
}

// MARK: Diagnostic Code

public enum QizhDiagnosticCode: Hashable, Sendable {
	case missingArgument
	case invalidUsage
	case custom(_ code: String)
}

extension QizhDiagnosticCode: RawRepresentable, CustomStringConvertible {
	public init(rawValue: String) {
		self = .custom(rawValue)
	}
	
	@inlinable public var rawValue: String {
		switch self {
		case .missingArgument: "missingArgument"
		case .invalidUsage: "invalidUsage"
		case .custom(let code): code
		}
	}
	
	@inlinable public var description: String {
		rawValue
	}
}

extension QizhDiagnosticCode: ExpressibleByStringLiteral {
	@inlinable public init(stringLiteral value: String) {
		self = .custom(value)
	}
}

// MARK: Diagnostic +

extension Diagnostic {
	public static func error(
		node: some SyntaxProtocol,
		message: String,
		id messageID: QizhDiagnosticCode
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
		id messageID: QizhDiagnosticCode
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
		id messageID: QizhDiagnosticCode
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
		id messageID: QizhDiagnosticCode
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
