//
//  CaseValue.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 31.05.2025.
//

import Foundation
import QizhMacroKit

fileprivate struct Content: Hashable, Sendable {
	let id: Int
	let name: String
	let options: [String]
}

fileprivate enum Option: String, Hashable, Sendable {
	case foo
	case bar
}

@CaseValue
fileprivate enum TestEnum {
	case option(_ option: Option)
	case foo(_ id: UInt?)
	case bar(_ id: UInt)
	case content(_ name: String, _ value: Content)
	case customer(UInt)
	case visit(UInt, String, Date, UInt)
	case request(_ id: UInt, _ name: String)
	case unknown
}
