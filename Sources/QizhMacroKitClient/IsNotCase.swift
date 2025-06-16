//
//  IsNotCase.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 06.02.2025.
//

import Foundation
import QizhMacroKit

@IsNotCase
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
