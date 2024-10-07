import Foundation
import QizhMacroKit

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

currentStatus = .inSuperLongProgress(10, of: 500)

if currentStatus.isInSuperLongProgress {
	print("is In Super Long Progress")
}
