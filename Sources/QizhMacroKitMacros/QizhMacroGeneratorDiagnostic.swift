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

	public init(_ message: String, severity: DiagnosticSeverity = .error) {
		self.message = message
		self.diagnosticID = MessageID(domain: "QizhKitMacros", id: "InvalidUsage")
		self.severity = severity
	}
}
