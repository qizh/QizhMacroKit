import Foundation
import QizhMacroKit

// MARK: IsCase

@IsCase
public enum Status {
	case idle
	case loading
	case success(data: Data)
	case failure(error: Error)
	case inSuperLongProgress(_ loaded: Double, of: Double)
}

public fileprivate(set) var currentStatus = Status.loading

if currentStatus.isLoading {
	print("is loading")
}

currentStatus = Status.inSuperLongProgress(10, of: 500)

if currentStatus.isInSuperLongProgress {
	print("is In Super Long Progress")
}

// MARK: CaseName

@CaseName
public enum Status2 {
	case idle
	case loading
	case success(data: Data)
	case failure(error: Error)
	case inSuperLongProgress(_ loaded: Double, of: Double)
}

public fileprivate(set) var currentStatus2 = Status2.loading

if currentStatus2.caseName == "loading" {
	print("Success")
}

currentStatus2 = .inSuperLongProgress(10, of: 500)

if currentStatus2.caseName == "inSuperLongProgress" {
	print("Success")
}
