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

@IsCase
fileprivate enum CaseError: Error {
	case somethingWentWrong
}

@IsCase
fileprivate enum AnotherCaseError: Error {
	case somethingWentWrong(String)
}

@IsCase /// Suppose to produce a warning
fileprivate enum Empty { }

@IsCase
@MainActor public enum StringFormat: String, Codable, Hashable, Equatable, Sendable, CaseIterable {
	case ipv4, ipv6, uuid, date, time, email, duration, hostname, dateTime = "date-time"
	case `default`
}
