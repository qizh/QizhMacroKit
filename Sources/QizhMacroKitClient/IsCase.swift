//
//  IsCase.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 08.10.2024.
//

import Foundation
import QizhMacroKit

@IsCase
fileprivate enum Status {
	case idle
	case loading
	case success(data: Data)
	case failure(error: Error)
	case inSuperLongProgress(_ loaded: Double, of: Double)
	case onSelect(_ callback: () -> Void)
	case `default`(Bool)
	case `is`(_ value: Bool)
}
