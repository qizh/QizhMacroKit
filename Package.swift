// swift-tools-version:5.10

import PackageDescription
import CompilerPluginSupport

let package = Package(
	name: "QizhMacroKit",
	platforms: [.macOS(.v13), .iOS(.v16), .macCatalyst(.v13)],
	products: [
		.library(
			name: "QizhMacroKit",
			targets: ["QizhMacroKit"]
		),
		.executable(
			name: "QizhMacroKitClient",
			targets: ["QizhMacroKitClient"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "510.0.0"),
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
		.target(name: "QizhMacroKit", dependencies: ["QizhMacroKitMacros"]),
		/// Client executable target that uses the macro
		.executableTarget(name: "QizhMacroKitClient", dependencies: ["QizhMacroKit"]),
		/*
		/// Test target
		.testTarget(
			name: "QizhMacroKitTests",
			dependencies: [
				"QizhMacroKitMacros",
				.product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
			]
		),
		*/
	]
)
