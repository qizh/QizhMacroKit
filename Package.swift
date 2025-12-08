// swift-tools-version: 6.2

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
			// type: .static,
			targets: ["QizhMacroKit"]
		),
		.executable(
			name: "QizhMacroKitClient",
			targets: ["QizhMacroKitClient"]
		),
		/*
		.library(
			name: "QizhMacroKitPlayground",
			type: .dynamic,
			targets: ["QizhMacroKitPlayground"]
		)
		*/
	],
	dependencies: [
		.package(
			url: "https://github.com/swiftlang/swift-syntax.git",
			/// Pinned to match Xcode 26.2 / Swift 6.2 toolchain
			/// to avoid `_SwiftSyntaxCShims` resolution errors
			/// ## Changelog
			/// - `"602.0.0" ..< "700.0.0"`
			/// - `exact: "602.0.0"`
			/// - `.upToNextMajor(from: "602.0.0")`
			/// - `exact: "602.1.0"`
			/// - `branch: "release/6.2"` (matches Xcode 26.2 / Swift 6.2)
			from: "602.0.0"
		),
		// .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.2.0")),
		/*
		.package(
			url: "https://github.com/apple/swift-testing.git",
			/// Was `branch: "main"`
			.upToNextMajor(from: "6.2.0")
		),
		*/
	],
	targets: [
		
		/// Macro plugin target
		
		.macro(
			name: "QizhMacroKitMacros",
			dependencies: [
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
				.product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
				.product(name: "SwiftDiagnostics", package: "swift-syntax"),
				// .product(name: "OrderedCollections", package: "swift-collections"),
			]
		),
		
		/// Library target that exposes the macro
		
		.target(
			name: "QizhMacroKit",
			dependencies: [
				// .product(name: "OrderedCollections", package: "swift-collections"),
			],
			resources: [
				.process("PrivacyInfo.xcprivacy")
			],
			plugins: [
				.plugin(name: "QizhMacroKitMacros")
			]
		),
		
		/// Internal library to test macros with playgrounds
		
		/*
		.target(
			name: "QizhMacroKitPlayground",
			dependencies: [
				"QizhMacroKit",
			],
			path: "Sources/Playgrounds",
			swiftSettings: [
				.define("ENABLE_DEBUG_DYLIB", .when(configuration: .debug))
			]
		),
		*/
		
		/// Client executable target that uses the macro
		
		.executableTarget(
			name: "QizhMacroKitClient",
			dependencies: ["QizhMacroKit"],
			resources: [
				.process("PrivacyInfo.xcprivacy")
			]
		),
		
		/// Test target
		
		.testTarget(
			name: "QizhMacroKitTests",
			dependencies: [
				"QizhMacroKit",
				"QizhMacroKitMacros",
				.product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
				// .product(name: "Testing", package: "swift-testing"),
			],
			path: "Tests"
		),
	],
	swiftLanguageModes: [
		// .v5,
		.v6,
	]
)

