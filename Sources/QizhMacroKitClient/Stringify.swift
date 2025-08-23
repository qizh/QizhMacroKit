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

/*
#if ENABLE_DEBUG_DYLIB

import Playgrounds

#Playground("stringify") {
	let isConnected = false
	let connectionID: Int? = 123
	
	_ = #stringify(isConnected)
	_ = #stringify(isConnected && connectionID != nil)
	_ = #stringify(connectionID != nil)
}

#Playground("stringify and calculate") {
	let isConnected = false
	let connectionID: Int? = 123
	
	_ = #stringifyAndCalculate(isConnected)
	_ = #stringifyAndCalculate(isConnected && connectionID != nil)
	_ = #stringifyAndCalculate(connectionID != nil)
	
	let id = #stringifyAndCalculate(connectionID).value
	_ = #stringify(id)
}

#endif
*/
