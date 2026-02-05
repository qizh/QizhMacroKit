// swift-tools-version: 6.2

/// Package manifest for Swift 6.2.4 toolchain (Xcode 26.3 RC)
/// swift-syntax 602.0.0 prebuilts are incompatible with Swift 6.2.4
/// See Package@swift-6.2.swift for Swift 6.2.0-6.2.3 (Xcode 26.2)
/// See Package.swift for Swift 6.3+ toolchain

import PackageDescription
import CompilerPluginSupport

let package = Package(
	name: "QizhMacroKit",
	platforms: [
		.iOS(.v17),
		.macOS(.v14),
		.macCatalyst(.v17),
	],
	products: [
		.library(
			name: "QizhMacroKit",
			targets: ["QizhMacroKit"]
		),
		.library(
			name: "QizhMacroKitPreviewSupport",
			targets: ["QizhMacroKitPreviewSupport"]
		),
		.executable(
			name: "QizhMacroKitClient",
			targets: ["QizhMacroKitClient"]
		),
	],
	dependencies: [
		/// swift-syntax 603.x for Swift 6.2.4 compatibility
		.package(
			url: "https://github.com/swiftlang/swift-syntax.git",
			from: "603.0.0-prerelease-2025-12-17"
		),
		
		/// DocC plugin (command plugin)
		.package(
			url: "https://github.com/swiftlang/swift-docc-plugin",
			from: "1.1.0"
		),
	],
	targets: [
		/// Macro implementation (executable "plugin" for the compiler)
		.macro(
			name: "QizhMacroKitMacros",
			dependencies: [
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
				.product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
				.product(name: "SwiftDiagnostics", package: "swift-syntax"),
			]
		),
		
		/// Library API (declare `@attached` / `#externalMacro`, etc in it)
		.target(
			name: "QizhMacroKit",
			dependencies: [
				"QizhMacroKitMacros",
			],
			resources: [
				.process("PrivacyInfo.xcprivacy")
			]
		),

		.executableTarget(
			name: "QizhMacroKitClient",
			dependencies: ["QizhMacroKit", "QizhMacroKitPreviewSupport"],
			resources: [.process("PrivacyInfo.xcprivacy"),]
		),
		
		/// Preview support library target for Xcode canvas
		.target(
			name: "QizhMacroKitPreviewSupport",
			dependencies: ["QizhMacroKit"]
		),
		
		.testTarget(
			name: "QizhMacroKitTests",
			dependencies: [
				"QizhMacroKit",
				"QizhMacroKitMacros",
				.product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
			],
			path: "Tests"
		),
	],
	swiftLanguageModes: [.v6]
)
