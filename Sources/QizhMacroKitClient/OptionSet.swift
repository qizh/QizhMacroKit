//
//  OptionSet.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 08.12.2025.
//

import Foundation
import QizhMacroKit

@OptionSet<UInt8>
struct BusinessColorApplications {
	private enum Options: UInt8 {
		case tint
		case tintGradient
		case accent
	}
}
