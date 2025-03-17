// swift-tools-version:6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
	name: "QizhMacroKit",
	platforms: [
		.iOS(.v16),
		.macOS(.v13),
		.macCatalyst(.v13),
	],
	products: [
		.library(
			name: "QizhMacroKit",
			type: .static,
			targets: ["QizhMacroKit"]
		),
		.executable(
			name: "QizhMacroKitClient",
			targets: ["QizhMacroKitClient"]
		),
	],
	dependencies: [
		// .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "600.0.0"),
		.package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0" ..< "610.0.0"),
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
			]
		),
		
		/// Library target that exposes the macro
		
		.target(
			name: "QizhMacroKit",
			dependencies: [],
			resources: [
				.process("PrivacyInfo.xcprivacy")
			],
			plugins: [
				.plugin(name: "QizhMacroKitMacros")
			]
		),
		
		/// Client executable target that uses the macro
		
		.executableTarget(
			name: "QizhMacroKitClient",
			dependencies: ["QizhMacroKit"],
			resources: [
				.process("PrivacyInfo.xcprivacy")
			]
		),
		
		/// Test target
		
		/*
		.testTarget(
			name: "QizhMacroKitTests",
			dependencies: [
				"QizhMacroKitMacros",
				.product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
			]
		),
		*/
	],
	swiftLanguageModes: [
		// .v5,
		.v6,
	]
)
