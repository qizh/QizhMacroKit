# PR #48 & #49 Analysis: Xcode 26.3 RC Compatibility

This document explains the analysis and merging of two PRs addressing the same issue: **"No such module 'SwiftCompilerPlugin'"** error with Xcode 26.3 RC (Swift 6.2.4).

## Summary

Both PRs are **correct** and address **complementary aspects** of the problem. They have been combined into a single comprehensive fix.

---

## PR #48 (`salt-1`): Version-specific Package.swift Manifests

### PR #48 Approach

Uses multiple `Package.swift` manifests for different Swift toolchains:

| Manifest                     | Swift Version | swift-syntax |
| ---------------------------- | ------------- | ------------ |
| `Package.swift`              | 6.3+          | 603.x        |
| `Package@swift-6.2.4.swift`  | 6.2.4         | 603.x        |
| `Package@swift-6.2.swift`    | 6.2.0–6.2.3   | 602.x        |

### PR #48 Root Cause Addressed

**Prebuilt module binary incompatibility** — swift-syntax 602.0.0 prebuilts were compiled with an older Swift 6.2.x compiler. Swift 6.2.4 (Xcode 26.3 RC) cannot use these prebuilts, causing module incompatibility errors.

### PR #48 Fix Type

Toolchain compatibility at the package manifest level.

---

## PR #49 (`pepper-1`): Remove `@_exported` Imports

### PR #49 Approach

- Removed `@_exported` attribute from imports in `_QizhMacroKitMacro.swift`
- Added explicit imports to each generator file

### PR #49 Root Cause Addressed

**Improper dependency re-export** — Using `@_exported` in a macro target can leak compiler-time dependencies (SwiftCompilerPlugin, SwiftSyntax, etc.) to consuming projects. Macro targets are compiler plugins executing at build time; their dependencies are internal implementation details and should never be re-exported.

### PR #49 Fix Type

Code hygiene and correctness at the source level.

---

## Why Both Fixes Are Needed

| Aspect     | PR #48                                   | PR #49                                                  |
| ---------- | ---------------------------------------- | ------------------------------------------------------- |
| **Issue**  | Prebuilt module version mismatch         | Dependency leakage via `@_exported`                     |
| **Scope**  | Package.swift manifests                  | Source code imports                                     |
| **Impact** | Enables correct swift-syntax version     | Prevents consuming projects from seeing macro internals |

The two fixes are **orthogonal** and **complementary**:

1. **PR #48** ensures the correct swift-syntax version is used for each Swift toolchain
2. **PR #49** ensures proper encapsulation of macro implementation details

Without PR #48, users on Swift 6.2.4+ would get prebuilt module errors.  
Without PR #49, `@_exported` would continue to leak internal dependencies (bad practice, potential future issues).

---

## Combined Solution

This branch (`feature/toolchain/603-prerelease/combined-by-cascade`) merges both PRs:

1. **From PR #48:**
   - Version-specific `Package.swift` manifests
   - Updated `KNOWN_ISSUES.md` with macro trust documentation
   - Scheme consolidation for testing

2. **From PR #49:**
   - Removed `@_exported` from `_QizhMacroKitMacro.swift`
   - Added explicit imports to generator files
   - Added DocC documentation to all generators
   - Updated `KNOWN_ISSUES.md` with resolved issue entry

---

## Verification

- **Build:** ✅ Success (Swift 6.2.4)
- **Tests:** ✅ 133/133 passed

---

*Analyzed and combined by `Cascade`*
