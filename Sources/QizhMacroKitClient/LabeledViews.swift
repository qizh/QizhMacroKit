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

extension String {
	func labeledView(label: String) -> some View {
		HStack(alignment: .firstTextBaseline, spacing: 4) {
			Text(label).foregroundStyle(.secondary)
			Text(self)
		}
		.font(.caption)
	}
}

struct TestView: View {
	let firstName = "Serhii"
	let lastName = "Shevchenko"
	
	var body: some View {
		getName()
		// name1
		// name2
	}
	
	@LabeledViews
	func getName() -> some View {
		firstName
		lastName
	}
	
	/*
	var name1: some View {
		@LabeledViews
		get {
			firstName
			lastName
		}
	}
	*/
	
	@LabeledViews
	var name: some View {
		firstName
		lastName
	}
}

