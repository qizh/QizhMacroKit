//
//  String+fnv1aHash.swift
//  QizhMacroKit
//
//  Created by Serhii Shevchenko in December 2025.
//

import Foundation

extension String {
	/// Returns a short hash suffix derived from this string using the FNV-1a algorithm.
	///
	/// FNV-1a (Fowler–Noll–Vo) is a non-cryptographic hash function known for its
	/// simplicity and good distribution properties. It's particularly well-suited
	/// for hash table lookups and generating unique identifiers from strings.
	///
	/// **Algorithm details:**
	/// - Uses the 64-bit FNV-1a variant
	/// - Offset basis: `0xcbf29ce484222325`
	/// - Prime: `0x100000001b3`
	/// - XOR-then-multiply approach (the "1a" variant)
	///
	/// The resulting hash is truncated to the last 8 hexadecimal characters (32 bits)
	/// for brevity while maintaining reasonable uniqueness for typical use cases.
	///
	/// - Returns: An 8-character uppercase hexadecimal string representing the hash suffix.
	///
	/// - Example:
	///   ```swift
	///   "myViewName".fnv1aHashSuffix  // Returns something like "A1B2C3D4"
	///   ```
	///
	/// - SeeAlso: [FNV Hash on Wikipedia](https://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function)
	internal var fnv1aHashSuffix: String {
		var value: UInt64 = 0xcbf29ce484222325  // FNV-1a 64-bit offset basis
		for scalar in self.unicodeScalars {
			value ^= UInt64(scalar.value)
			value = value &* 0x100000001b3  // FNV-1a 64-bit prime
		}
		let hex = String(value, radix: 16, uppercase: true)
		return String(hex.suffix(8))
	}
}
