//
//  String+trimmingBackticks.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 16.06.2025.
//

import Foundation

fileprivate let backticks: CharacterSet = .init(charactersIn: "`")

extension String {
	internal var withBackticksTrimmed: String {
		trimmingCharacters(in: backticks)
	}
}
