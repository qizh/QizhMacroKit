//
//  Labeled.swift
//  QizhMacroKit
//
//  Created by OpenAI ChatGPT on 13.01.2025.
//

@attached(peer, names: arbitrary)
/// Attribute that converts an array literal into an ``OrderedDictionary`` keyed by the element expressions.
public macro Labeled() = #externalMacro(module: "QizhMacroKitMacros", type: "LabeledGenerator")

@_exported import OrderedCollections

