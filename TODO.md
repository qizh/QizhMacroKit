# TODO — Roadmap & Planned Improvements

> Last Updated: November 27, 2025

This document outlines planned features, improvements, and tasks for QizhMacroKit.

## High Priority

### Documentation

- [ ] **Add DocC documentation catalog**
  - Create `Sources/QizhMacroKit/Documentation.docc` with full API documentation
  - Include interactive tutorials for each macro
  - Generate documentation website

- [ ] **Improve inline code documentation**
  - Add comprehensive doc comments to all public APIs
  - Include code examples in doc comments
  - Document all error conditions and edge cases

### Testing

- [ ] **Expand test coverage**
  - Add edge case tests for reserved keywords
  - Test all access modifier combinations
  - Add performance benchmarks for macro expansion

- [ ] **Add integration tests**
  - Test macros in real-world usage scenarios
  - Verify generated code compiles on all platforms

---

## Medium Priority

### New Macros

- [ ] **`@CaseID` macro**
  - Generate unique, stable identifiers for enum cases
  - Support custom ID types (String, Int, UUID)

- [ ] **`@CaseCodable` macro**
  - Auto-generate `Codable` conformance for enums with associated values
  - Support custom encoding strategies

- [ ] **`@CaseComparable` macro**
  - Generate `Comparable` conformance based on case order
  - Allow custom comparison logic

### Macro Improvements

- [ ] **CaseValue improvements**
  - Add option to generate throwing accessors instead of optionals
  - Support custom property name overrides via macro parameters
  - Generate `as<CaseName>` methods returning non-optional when matched

- [ ] **IsCase improvements**
  - Add option to generate `@inlinable` properties for performance
  - Support excluding specific cases from generation
  - Generate static `allCases` convenience

- [ ] **CaseName improvements**
  - Support custom naming strategies (e.g., uppercase, lowercase, kebab-case)
  - Add option to include associated value descriptions

### Error Handling

- [ ] **Improved diagnostics**
  - Add Fix-It suggestions for common errors
  - Provide more context in error messages
  - Add warnings for potential issues (e.g., name collisions)

---

## Low Priority

### Build & CI

- [ ] **Cross-platform CI improvements**
  - Add Windows CI support when Swift macros are available
  - Optimize build times with caching

- [ ] **Release automation**
  - Auto-generate release notes from commits
  - Publish to Swift Package Index automatically

### Developer Experience

- [ ] **Xcode integration**
  - Create Xcode project templates using QizhMacroKit
  - Add code snippets for common patterns

- [ ] **Playground examples**
  - Create interactive Swift Playgrounds demonstrating each macro
  - Include before/after expansion examples

### Performance

- [ ] **Macro expansion optimization**
  - Profile and optimize macro expansion time
  - Reduce memory usage during compilation

---

## Completed

### v1.1.12 (November 2025)

- [x] Set up Copilot instructions
- [x] Add comprehensive documentation (`Docs/` folder)
- [x] Create README with installation and usage guides
- [x] Document known issues and limitations

### v1.1.x

- [x] Implement `@CaseName` macro
- [x] Implement `@IsCase` macro with membership checking
- [x] Implement `@IsNotCase` macro
- [x] Implement `@CaseValue` macro
- [x] Implement `#stringify` macro
- [x] Implement `#dictionarify` macro
- [x] Add Swift keyword escaping support
- [x] Add access modifier inheritance
- [x] Set up GitHub Actions CI

---

## Contributing

Want to help? Here's how:

1. **Pick a task** from the High or Medium priority sections
2. **Open an issue** to discuss your approach
3. **Submit a PR** with your implementation
4. **Add tests** for any new functionality

See [KNOWN_ISSUES.md](KNOWN_ISSUES.md) for bugs that need fixing.

## Feature Requests

Have an idea not listed here? [Open a feature request](https://github.com/qizh/QizhMacroKit/issues/new?labels=enhancement) with:

- Clear description of the proposed feature
- Use cases and examples
- Any potential implementation concerns
