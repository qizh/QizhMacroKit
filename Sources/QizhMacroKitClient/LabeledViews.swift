//
//  File.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 07.09.2025.
//

import SwiftUI
import QizhMacroKit

struct LabeledViews<Content: View>: View {
	let content: () -> Content
	init(@ViewBuilder _ content: @escaping () -> Content) { self.content = content }
	var body: some View { content() }
}

extension View {
	func labeledView(label: String) -> some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(label).font(.caption).foregroundStyle(.secondary)
			self
		}
	}
}

struct TestView: View {
	let firstName = "Serhii"
	let lastName = "Shevchenko"
	
	var body: some View {
		name1
		name2
	}
	
	var name1: some View {
		@LabeledViews
		get {
			firstName
			lastName
		}
	}
	
	@LabeledViews
	var name2: some View {
		firstName
		lastName
	}
}

