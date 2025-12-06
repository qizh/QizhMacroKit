//
//  SwiftUIView.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 06.12.2025.
//

import SwiftUI
import QizhMacroKit

class Foo: ObservableObject {
	@Published var message: String = "Hello, World!"
	
	init(message: String) {
		self.message = message
	}
}

@Observable
class Bar {
	var text: String = "Hello, World!"
	
	init(text: String) {
		self.text = text
	}
}

struct ViewUsingApplyEnvironment: View {
	let int = 1
	let str = "2"
	
    var body: some View {
		#ApplyEnvironment {
			@EnvironmentObject var foo: Foo
			@Environment(Bar.self) var bar
		} {
			Text("Hello, World! \(int) \(str) \(foo.message) \(bar.text)")
		}
    }
