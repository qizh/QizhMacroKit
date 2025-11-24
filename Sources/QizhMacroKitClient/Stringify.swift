//
//  Stringify.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko on 08.10.2024.
//

import Foundation
import QizhMacroKit

func shouldBeNoErrors() {
	let isConnected = false
	let connectionID: Int? = 123
	
	_ = #stringify(isConnected)
	_ = #stringify(isConnected && connectionID != nil)
	_ = #stringify(connectionID != nil)
	
	_ = #dictionarify(isConnected)
	_ = #dictionarify(isConnected && connectionID != nil)
	_ = #dictionarify(connectionID != nil)
}

#if DEBUG && canImport(Playgrounds) && swift(>=6.2)
/// Code below is only compiled in DEBUG builds, with Swift v6.2+, and when the Playgrounds module is available.
/// If Playgrounds is not available, this block will be silently excluded even in DEBUG builds with Swift 6.2+.

import Playgrounds /// Conditionally compiled

#Playground("stringify") {
	let isConnected = false
	let connectionID: Int? = 123
	
	_ = #stringify(isConnected)
	_ = #stringify(isConnected && connectionID != nil)
	_ = #stringify(connectionID != nil)
}

#Playground("dictionarify") {
	let isConnected = false
	let connectionID: Int? = 123
	
	_ = #dictionarify(isConnected)
	_ = #dictionarify(isConnected && connectionID != nil)
	_ = #dictionarify(connectionID != nil)
	
	let id = #dictionarify(connectionID).value
	_ = #stringify(id)
}

#endif
