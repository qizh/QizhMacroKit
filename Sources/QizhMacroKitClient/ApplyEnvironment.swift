//
//  SwiftUIView.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 06.12.2025.
//

/*
import SwiftUI
import QizhMacroKit

struct Before {
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
		let int1 = 1
		let int2 = 2
		let str1 = "1"
		let str2 = "2"
		
		var body: some View {
			VStack {
				Text("Header").font(.title)
				
				@MyMacroName {
					@EnvironmentObject var foo: Foo
					@Environment(Bar.self) var bar: Bar
				}
				HStack {
					Label {
						Text("Hello, World! \(int2) \(str1) \(foo.message) \(bar.text)")
					} icon: {
						Image(systemName: "xmark")
					}
				}
			}
		}
	}
}

struct After {
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
		let int1 = 1
		let int2 = 2
		let str1 = "1"
		let str2 = "2"

		var body: some View {
			VStack {
				Text("Header").font(.title)
				
				_MyMacroNameView_cbf29ce4(int2: int2, str1: str1)
			}
		}
	}

	struct _MyMacroNameView_cbf29ce4: View {
		@EnvironmentObject var foo: Foo
		@Environment(Bar.self) var bar: Bar
		
		let int2: Int
		let str1: String
		
		var body: some View {
			HStack {
				Label {
					Text("Hello, World! \(int2) \(str1) \(foo.message) \(bar.text)")
				} icon: {
					Image(systemName: "xmark")
				}
			}
		}
	}
}
*/

/*
struct ViewUsingApplyEnvironment2: View {
	let int = 1
	let str = "2"
	
	var body: some View {
		VStack {
			Text("Header 2").font(.title)
			
			#ApplyEnvironment("WithName") {
				@EnvironmentObject var foo: Foo
				@Environment(Bar.self) var bar: Bar
			} to: {
				Text("Hello, World! \(int) \(str) \(foo.message) \(bar.text)")
			}
		}
	}
}

struct WrapperView: View {
	@StateObject var foo: Foo = .init(message: "Hello, World!")
	@State var bar: Bar = .init(text: "World!")
	
	var body: some View {
		ViewUsingApplyEnvironment()
			.environmentObject(foo)
			.environment(bar)
	}
}

#Preview {
	@Previewable @StateObject var foo: Foo = .init(message: "Hello, World!")
	@Previewable @State var bar: Bar = .init(text: "World!")
	WrapperView()
}
*/
