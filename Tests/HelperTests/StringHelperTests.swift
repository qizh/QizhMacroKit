//
//  StringHelperTests.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 18.12.2025.
//

#if os(macOS)
import Testing
@testable import QizhMacroKitMacros

/// Tests for String helper extensions used in macro implementations.
@Suite("String Helpers")
struct StringHelperTests {
	
	// MARK: - Backtick Trimming Tests
	
	@Suite("withBackticksTrimmed")
	struct BacktickTrimmingTests {
		
		@Test("Trims leading backtick")
		func trimsLeadingBacktick() {
			#expect("`keyword".withBackticksTrimmed == "keyword")
		}
		
		@Test("Trims trailing backtick")
		func trimsTrailingBacktick() {
			#expect("keyword`".withBackticksTrimmed == "keyword")
		}
		
		@Test("Trims both backticks")
		func trimsBothBackticks() {
			#expect("`keyword`".withBackticksTrimmed == "keyword")
		}
		
		@Test("Returns unchanged when no backticks")
		func returnsUnchangedWithoutBackticks() {
			#expect("normal".withBackticksTrimmed == "normal")
		}
		
		@Test("Handles empty string")
		func handlesEmptyString() {
			#expect("".withBackticksTrimmed == "")
		}
		
		@Test("Handles only backticks")
		func handlesOnlyBackticks() {
			#expect("``".withBackticksTrimmed == "")
		}
	}
	
	// MARK: - Swift Keyword Escaping Tests
	
	@Suite("escapedSwiftIdentifier")
	struct SwiftKeywordEscapingTests {
		
		@Test("Escapes class keyword")
		func escapesClassKeyword() {
			#expect("class".escapedSwiftIdentifier == "`class`")
		}
		
		@Test("Escapes struct keyword")
		func escapesStructKeyword() {
			#expect("struct".escapedSwiftIdentifier == "`struct`")
		}
		
		@Test("Escapes enum keyword")
		func escapesEnumKeyword() {
			#expect("enum".escapedSwiftIdentifier == "`enum`")
		}
		
		@Test("Escapes func keyword")
		func escapesFuncKeyword() {
			#expect("func".escapedSwiftIdentifier == "`func`")
		}
		
		@Test("Escapes Self keyword")
		func escapesSelfKeyword() {
			#expect("Self".escapedSwiftIdentifier == "`Self`")
		}
		
		@Test("Escapes self keyword")
		func escapesLowercaseSelfKeyword() {
			#expect("self".escapedSwiftIdentifier == "`self`")
		}
		
		@Test("Escapes async keyword")
		func escapesAsyncKeyword() {
			#expect("async".escapedSwiftIdentifier == "`async`")
		}
		
		@Test("Escapes await keyword")
		func escapesAwaitKeyword() {
			#expect("await".escapedSwiftIdentifier == "`await`")
		}
		
		@Test("Does not escape non-keywords")
		func doesNotEscapeNonKeywords() {
			#expect("myVariable".escapedSwiftIdentifier == "myVariable")
			#expect("someFunction".escapedSwiftIdentifier == "someFunction")
			#expect("CustomType".escapedSwiftIdentifier == "CustomType")
		}
		
		@Test("Escapes control flow keywords")
		func escapesControlFlowKeywords() {
			#expect("if".escapedSwiftIdentifier == "`if`")
			#expect("else".escapedSwiftIdentifier == "`else`")
			#expect("for".escapedSwiftIdentifier == "`for`")
			#expect("while".escapedSwiftIdentifier == "`while`")
			#expect("switch".escapedSwiftIdentifier == "`switch`")
			#expect("case".escapedSwiftIdentifier == "`case`")
			#expect("default".escapedSwiftIdentifier == "`default`")
		}
	}
	
	// MARK: - Case Conversion Tests
	
	@Suite("toCamelCase")
	struct CamelCaseTests {
		
		@Test("Converts snake_case")
		func convertsSnakeCase() {
			#expect("hello_world".toCamelCase == "helloWorld")
		}
		
		@Test("Converts PascalCase")
		func convertsPascalCase() {
			#expect("HelloWorld".toCamelCase == "helloWorld")
		}
		
		@Test("Handles single word")
		func handlesSingleWord() {
			#expect("hello".toCamelCase == "hello")
		}
		
		@Test("Handles UPPERCASE")
		func handlesUppercase() {
			#expect("HELLO".toCamelCase == "hello")
		}
		
		@Test("Handles mixed case")
		func handlesMixedCase() {
			#expect("helloWORLD".toCamelCase == "helloWorld")
		}
		
		@Test("Handles acronyms")
		func handlesAcronyms() {
			#expect("XMLParser".toCamelCase == "xmlParser")
			#expect("parseXML".toCamelCase == "parseXml")
		}
		
		@Test("Handles numbers")
		func handlesNumbers() {
			#expect("value123Test".toCamelCase == "value123Test")
		}
	}
	
	@Suite("toPascalCase")
	struct PascalCaseTests {
		
		@Test("Converts snake_case")
		func convertsSnakeCase() {
			#expect("hello_world".toPascalCase == "HelloWorld")
		}
		
		@Test("Converts camelCase")
		func convertsCamelCase() {
			#expect("helloWorld".toPascalCase == "HelloWorld")
		}
		
		@Test("Handles single word")
		func handlesSingleWord() {
			#expect("hello".toPascalCase == "Hello")
		}
		
		@Test("Handles UPPERCASE")
		func handlesUppercase() {
			#expect("HELLO".toPascalCase == "Hello")
		}
	}
	
	@Suite("toSnakeCase")
	struct SnakeCaseTests {
		
		@Test("Converts camelCase")
		func convertsCamelCase() {
			#expect("helloWorld".toSnakeCase == "hello_world")
		}
		
		@Test("Converts PascalCase")
		func convertsPascalCase() {
			#expect("HelloWorld".toSnakeCase == "hello_world")
		}
		
		@Test("Handles single word")
		func handlesSingleWord() {
			#expect("hello".toSnakeCase == "hello")
		}
		
		@Test("Handles acronyms")
		func handlesAcronyms() {
			#expect("XMLParser".toSnakeCase == "xml_parser")
		}
	}
	
	@Suite("toKebabCase")
	struct KebabCaseTests {
		
		@Test("Converts camelCase")
		func convertsCamelCase() {
			#expect("helloWorld".toKebabCase == "hello-world")
		}
		
		@Test("Converts PascalCase")
		func convertsPascalCase() {
			#expect("HelloWorld".toKebabCase == "hello-world")
		}
		
		@Test("Handles single word")
		func handlesSingleWord() {
			#expect("hello".toKebabCase == "hello")
		}
	}
	
	@Suite("toDotCase")
	struct DotCaseTests {
		
		@Test("Converts camelCase")
		func convertsCamelCase() {
			#expect("helloWorld".toDotCase == "hello.world")
		}
		
		@Test("Converts PascalCase")
		func convertsPascalCase() {
			#expect("HelloWorld".toDotCase == "hello.world")
		}
		
		@Test("Handles single word")
		func handlesSingleWord() {
			#expect("hello".toDotCase == "hello")
		}
	}
	
	@Suite("toWordsArray")
	struct WordsArrayTests {
		
		@Test("Splits camelCase into words")
		func splitsCamelCase() {
			let words = "helloWorld".toWordsArray()
			#expect(words == ["hello", "world"])
		}
		
		@Test("Splits PascalCase into words")
		func splitsPascalCase() {
			let words = "HelloWorld".toWordsArray()
			#expect(words == ["hello", "world"])
		}
		
		@Test("Handles numbers")
		func handlesNumbers() {
			let words = "value123test".toWordsArray()
			#expect(words == ["value", "123", "test"])
		}
		
		@Test("Handles single word")
		func handlesSingleWord() {
			let words = "hello".toWordsArray()
			#expect(words == ["hello"])
		}
		
		@Test("Returns empty for empty string")
		func returnsEmptyForEmptyString() {
			let words = "".toWordsArray()
			#expect(words.isEmpty)
		}
	}
}
#endif
