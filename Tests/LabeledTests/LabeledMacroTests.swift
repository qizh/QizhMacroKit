import Testing
import QizhMacroKit
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import SwiftSyntaxMacrosGenericTestSupport
import QizhMacroKitMacros
import OrderedCollections

/// Tests for the ``Labeled`` macro.
@Suite("Labeled macro")
struct LabeledMacroTests {
	/// Macro implementations under test.
	let macros: [String: any Macro.Type] = [
		"Labeled": LabeledGenerator.self,
	]
	
	// MARK: - Macro Expansion Tests
	
	/// Ensures the array expands to an ``OrderedDictionary``.
	@Test("expands array with variable references to OrderedDictionary")
	func expandsToOrderedDictionary() {
		assertMacroExpansion(
			#"""
			let dict = #Labeled([firstName, lastName])
			"""#,
			expandedSource:
			#"""
			let dict = ["firstName": firstName, "lastName": lastName]
			"""#,
			macros: macros
		)
	}
	
	/// Tests expansion with a single element.
	@Test("expands single element array")
	func expandsSingleElement() {
		assertMacroExpansion(
			#"""
			let dict = #Labeled([value])
			"""#,
			expandedSource:
			#"""
			let dict = ["value": value]
			"""#,
			macros: macros
		)
	}
	
	/// Tests expansion with an empty array.
	@Test("expands empty array to empty dictionary")
	func expandsEmptyArray() {
		assertMacroExpansion(
			#"""
			let dict = #Labeled([])
			"""#,
			expandedSource:
			#"""
			let dict = [:]
			"""#,
			macros: macros
		)
	}
	
	/// Tests expansion with multiple elements.
	@Test("expands multiple elements")
	func expandsMultipleElements() {
		assertMacroExpansion(
			#"""
			let dict = #Labeled([a, b, c, d])
			"""#,
			expandedSource:
			#"""
			let dict = ["a": a, "b": b, "c": c, "d": d]
			"""#,
			macros: macros
		)
	}
	
	/// Tests expansion handles underscored variable names.
	@Test("expands underscored variable names")
	func expandsUnderscoredNames() {
		assertMacroExpansion(
			#"""
			let dict = #Labeled([first_name, last_name])
			"""#,
			expandedSource:
			#"""
			let dict = ["first_name": first_name, "last_name": last_name]
			"""#,
			macros: macros
		)
	}
	
	/// Tests expansion with property access expressions.
	@Test("expands property access expressions")
	func expandsPropertyAccess() {
		assertMacroExpansion(
			#"""
			let dict = #Labeled([user.name, user.age])
			"""#,
			expandedSource:
			#"""
			let dict = ["user.name": user.name, "user.age": user.age]
			"""#,
			macros: macros
		)
	}
	
	// MARK: - Runtime Tests
	
	/// Uses the macro at runtime with string values.
	@Test("runtime dictionary with strings")
	func runtimeDictionaryWithStrings() {
		let firstName = "Serhii"
		let lastName = "Shevchenko"
		let dict = #Labeled([firstName, lastName])
		#expect(dict.keys.first == "firstName")
		#expect(dict["firstName"] == "Serhii")
		#expect(dict["lastName"] == lastName)
		#expect(dict.count == 2)
	}
	
	/// Tests runtime with integer values.
	@Test("runtime dictionary with integers")
	func runtimeDictionaryWithIntegers() {
		let width = 100
		let height = 200
		let depth = 50
		let dimensions = #Labeled([width, height, depth])
		#expect(dimensions["width"] == 100)
		#expect(dimensions["height"] == 200)
		#expect(dimensions["depth"] == 50)
		#expect(dimensions.keys.contains("width"))
	}
	
	/// Tests that order is preserved in the resulting dictionary.
	@Test("preserves element order")
	func preservesOrder() {
		let first = 1
		let second = 2
		let third = 3
		let dict = #Labeled([first, second, third])
		let keys = Array(dict.keys)
		#expect(keys == ["first", "second", "third"])
	}
	
	/// Tests runtime with a single element.
	@Test("runtime single element")
	func runtimeSingleElement() {
		let onlyValue = "single"
		let dict = #Labeled([onlyValue])
		#expect(dict.count == 1)
		#expect(dict["onlyValue"] == "single")
	}
	
	/// Tests runtime with empty array.
	@Test("runtime empty array")
	func runtimeEmptyArray() {
		let dict: OrderedDictionary<String, Int> = #Labeled([])
		#expect(dict.isEmpty)
		#expect(dict.count == 0)
	}
	
	/// Tests that the dictionary is of the correct type.
	@Test("returns OrderedDictionary type")
	func returnsOrderedDictionaryType() {
		let value = 42
		let dict = #Labeled([value])
		// This should compile - verifying the type is OrderedDictionary
		let _: OrderedDictionary<String, Int> = dict
		#expect(dict is OrderedDictionary<String, Int>)
	}
	
	/// Tests runtime with Boolean values.
	@Test("runtime dictionary with booleans")
	func runtimeDictionaryWithBooleans() {
		let isEnabled = true
		let isVisible = false
		let flags = #Labeled([isEnabled, isVisible])
		#expect(flags["isEnabled"] == true)
		#expect(flags["isVisible"] == false)
	}
	
	/// Tests runtime with Double values.
	@Test("runtime dictionary with doubles")
	func runtimeDictionaryWithDoubles() {
		let latitude = 50.4501
		let longitude = 30.5234
		let coordinates = #Labeled([latitude, longitude])
		#expect(coordinates["latitude"] == 50.4501)
		#expect(coordinates["longitude"] == 30.5234)
	}
	
	/// Tests runtime with optional values.
	@Test("runtime dictionary with optionals")
	func runtimeDictionaryWithOptionals() {
		let optionalName: String? = "Test"
		let optionalAge: String? = nil
		let optionals = #Labeled([optionalName, optionalAge])
		#expect(optionals["optionalName"] == "Test")
		#expect(optionals["optionalAge"] == String?.none)
	}
	
	/// Tests iteration over the dictionary preserves order.
	@Test("iteration preserves order")
	func iterationPreservesOrder() {
		let alpha = "A"
		let beta = "B"
		let gamma = "C"
		let dict = #Labeled([alpha, beta, gamma])
		
		var iteratedKeys: [String] = []
		for (key, _) in dict {
			iteratedKeys.append(key)
		}
		#expect(iteratedKeys == ["alpha", "beta", "gamma"])
	}
	
	/// Tests values can be accessed by index.
	@Test("access by index")
	func accessByIndex() {
		let first = 10
		let second = 20
		let third = 30
		let dict = #Labeled([first, second, third])
		
		#expect(dict.elements[0].key == "first")
		#expect(dict.elements[0].value == 10)
		#expect(dict.elements[2].key == "third")
		#expect(dict.elements[2].value == 30)
	}
}

