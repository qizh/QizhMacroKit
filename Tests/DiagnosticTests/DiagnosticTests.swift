//
//  DiagnosticTests.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 18.12.2025.
//

#if os(macOS)
import Testing
import SwiftSyntax
import SwiftDiagnostics
@testable import QizhMacroKitMacros

/// Tests for `QizhMacroGeneratorDiagnostic` and related diagnostic types.
@Suite("Diagnostic Types")
struct DiagnosticTests {
	
	// MARK: - QizhMacroGeneratorDiagnostic Tests
	
	@Suite("QizhMacroGeneratorDiagnostic")
	struct QizhMacroGeneratorDiagnosticTests {
		
		@Test("Initializes with string message ID")
		func initWithStringID() {
			let diagnostic = QizhMacroGeneratorDiagnostic(
				message: "Test error message",
				id: "testErrorID",
				severity: .error
			)
			
			#expect(diagnostic.message == "Test error message")
			#expect(diagnostic.severity == .error)
			// MessageID properties are private, verify it exists
			_ = diagnostic.diagnosticID
		}
		
		@Test("Initializes with QizhDiagnosticCode")
		func initWithDiagnosticCode() {
			let diagnostic = QizhMacroGeneratorDiagnostic(
				message: "Missing argument",
				id: .missingArgument,
				severity: .error
			)
			
			#expect(diagnostic.message == "Missing argument")
			// Verify diagnosticID exists
			_ = diagnostic.diagnosticID
		}
		
		@Test("Description returns message")
		func descriptionReturnsMessage() {
			let diagnostic = QizhMacroGeneratorDiagnostic(
				message: "Description test",
				id: .invalidUsage,
				severity: .warning
			)
			
			#expect(diagnostic.description == "Description test")
		}
		
		@Test("Supports all severity levels")
		func supportsAllSeverityLevels() {
			let error = QizhMacroGeneratorDiagnostic(message: "Error", id: "e", severity: .error)
			let warning = QizhMacroGeneratorDiagnostic(message: "Warning", id: "w", severity: .warning)
			let note = QizhMacroGeneratorDiagnostic(message: "Note", id: "n", severity: .note)
			let remark = QizhMacroGeneratorDiagnostic(message: "Remark", id: "r", severity: .remark)
			
			#expect(error.severity == .error)
			#expect(warning.severity == .warning)
			#expect(note.severity == .note)
			#expect(remark.severity == .remark)
		}
	}
	
	// MARK: - QizhDiagnosticCode Tests
	
	@Suite("QizhDiagnosticCode")
	struct QizhDiagnosticCodeTests {
		
		@Test("Predefined codes have correct raw values")
		func predefinedCodesRawValues() {
			#expect(QizhDiagnosticCode.missingArgument.rawValue == "missingArgument")
			#expect(QizhDiagnosticCode.invalidUsage.rawValue == "invalidUsage")
			#expect(QizhDiagnosticCode.noEnumCases.rawValue == "noEnumCases")
		}
		
		@Test("Custom code stores value")
		func customCodeStoresValue() {
			let custom = QizhDiagnosticCode.custom("myCustomCode")
			#expect(custom.rawValue == "myCustomCode")
		}
		
		@Test("RawRepresentable initializer creates custom")
		func rawRepresentableInitializer() {
			let code = QizhDiagnosticCode(rawValue: "fromRawValue")
			#expect(code.rawValue == "fromRawValue")
		}
		
		@Test("Description matches raw value")
		func descriptionMatchesRawValue() {
			#expect(QizhDiagnosticCode.missingArgument.description == "missingArgument")
			#expect(QizhDiagnosticCode.custom("test").description == "test")
		}
		
		@Test("ExpressibleByStringLiteral creates custom")
		func stringLiteralCreatesCustom() {
			let code: QizhDiagnosticCode = "literalCode"
			#expect(code.rawValue == "literalCode")
		}
		
		@Test("Hashable conformance")
		func hashableConformance() {
			let set: Set<QizhDiagnosticCode> = [.missingArgument, .invalidUsage, .custom("x")]
			#expect(set.count == 3)
			#expect(set.contains(.missingArgument))
		}
	}
	
	// MARK: - QizhFixMessageID Tests
	
	@Suite("QizhFixMessageID")
	struct QizhFixMessageIDTests {
		
		@Test("Predefined IDs have correct raw values")
		func predefinedIDsRawValues() {
			#expect(QizhFixMessageID.addCase.rawValue == "addCase")
		}
		
		@Test("Custom ID stores value")
		func customIDStoresValue() {
			let custom = QizhFixMessageID.custom("myFixID")
			#expect(custom.rawValue == "myFixID")
		}
		
		@Test("RawRepresentable initializer creates custom")
		func rawRepresentableInitializer() {
			let id = QizhFixMessageID(rawValue: "fromRawValue")
			#expect(id.rawValue == "fromRawValue")
		}
		
		@Test("Description matches raw value")
		func descriptionMatchesRawValue() {
			#expect(QizhFixMessageID.addCase.description == "addCase")
			#expect(QizhFixMessageID.custom("test").description == "test")
		}
		
		@Test("ExpressibleByStringLiteral creates custom")
		func stringLiteralCreatesCustom() {
			let id: QizhFixMessageID = "literalID"
			#expect(id.rawValue == "literalID")
		}
		
		@Test("Hashable conformance")
		func hashableConformance() {
			let set: Set<QizhFixMessageID> = [.addCase, .custom("x"), .custom("y")]
			#expect(set.count == 3)
			#expect(set.contains(.addCase))
		}
	}
	
	// MARK: - Diagnostic Extension Tests
	
	@Suite("Diagnostic Extensions")
	struct DiagnosticExtensionTests {
		
		@Test("Creates error diagnostic")
		func createsErrorDiagnostic() {
			let source: SourceFileSyntax = "let x = 1"
			let diagnostic = Diagnostic.error(
				node: source,
				message: "Test error",
				id: .invalidUsage
			)
			
			#expect(diagnostic.message == "Test error")
			#expect(diagnostic.diagMessage.severity == .error)
		}
		
		@Test("Creates warning diagnostic")
		func createsWarningDiagnostic() {
			let source: SourceFileSyntax = "let x = 1"
			let diagnostic = Diagnostic.warning(
				node: source,
				message: "Test warning",
				id: .noEnumCases
			)
			
			#expect(diagnostic.message == "Test warning")
			#expect(diagnostic.diagMessage.severity == .warning)
		}
		
		@Test("Creates note diagnostic")
		func createsNoteDiagnostic() {
			let source: SourceFileSyntax = "let x = 1"
			let diagnostic = Diagnostic.note(
				node: source,
				message: "Test note",
				id: .custom("noteID")
			)
			
			#expect(diagnostic.message == "Test note")
			#expect(diagnostic.diagMessage.severity == .note)
		}
		
		@Test("Creates remark diagnostic")
		func createsRemarkDiagnostic() {
			let source: SourceFileSyntax = "let x = 1"
			let diagnostic = Diagnostic.remark(
				node: source,
				message: "Test remark",
				id: .custom("remarkID")
			)
			
			#expect(diagnostic.message == "Test remark")
			#expect(diagnostic.diagMessage.severity == .remark)
		}
	}
	
	// MARK: - FixMessage Tests
	
	@Suite("FixMessage")
	struct FixMessageTests {
		
		@Test("Initializes with MessageID")
		func initWithMessageID() {
			let messageID = MessageID(domain: "test", id: "fixIt")
			let fix = FixMessage(message: "Apply fix", fixItID: messageID)
			
			#expect(fix.message == "Apply fix")
			// MessageID properties are private, verify it exists
			_ = fix.fixItID
		}
		
		@Test("Initializes with QizhFixMessageID")
		func initWithQizhFixMessageID() {
			let fix = FixMessage(message: "Add a case", id: .addCase)
			
			#expect(fix.message == "Add a case")
			// MessageID properties are private, verify it exists
			_ = fix.fixItID
		}
	}
}
#endif
