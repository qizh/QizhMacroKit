/// Generates a helper wrapper view that injects environment values into the attached view expression.
///
/// The macro accepts an optional name and a closure with plain variable declarations. Each declaration
/// describes an environment dependency that will be fetched inside the generated wrapper view and passed
/// into the wrapped expression.
@freestanding(codeItem, names: arbitrary)
public macro WithEnvironment(
	_ name: StringLiteralType? = nil,
	declarations: () -> Void
) = #externalMacro(module: "QizhMacroKitMacros", type: "WithEnvironmentGenerator")
