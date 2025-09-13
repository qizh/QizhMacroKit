//
//  File.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 06.09.2025.
//

import Foundation
import QizhMacroKit

fileprivate func _labeled() {
	let firstName = "Serhii"
	let lastName = "Shevchenko"
	@Labeled let dict = [
		firstName,
		lastName,
	]
	
	@Labeled
	let names = [
		firstName,
		lastName,
	]
	
	print("dict: \(dict)")
	print("names: \(names)")
}
