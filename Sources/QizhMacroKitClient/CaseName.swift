//
//  CaseName.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 08.10.2024.
//

import Foundation
import QizhMacroKit

@CaseName
fileprivate enum Status {
	case idle
	case loading
	case success(data: Data)
	case failure(_ error: Error)
	case inSuperLongProgress(_ loaded: Double, of: Double)
}

@CaseName(snakeCase: true)
fileprivate enum Status2 {
	case idleState
	case loadingNow
	case success(data: Data)
	case failure(_ error: Error)
	case inSuperLongProgress(_ loaded: Double, of: Double)
}
