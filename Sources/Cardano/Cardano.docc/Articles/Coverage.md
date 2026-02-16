# Code Coverage Report - Cardano Swift SDK

This document details the code coverage status of the Cardano Swift SDK as of version 0.2.3.

## Coverage Statistics

| Filename | Lines Coverage | Region Coverage | Status |
| :--- | :--- | :--- | :--- |
| **Address.swift** | 100.00% | 100.00% | ✅ Full |
| **UTXO.swift** | 100.00% | 100.00% | ✅ Full |
| **Value.swift** | 100.00% | 100.00% | ✅ Full |
| **AsyncHelpers.swift** | 100.00% | 100.00% | ✅ Full |
| **Assets.swift** | 100.00% | 97.14% | ✅ Full |
| **Mnemonic.swift** | 100.00% | 96.55% | ✅ Full |
| **Wallet.swift** | 97.37% | 97.01% | 🛡️ High |
| **Metadata.swift** | 97.06% | 96.55% | 🛡️ High |
| **BigNum.swift** | 96.84% | 92.86% | 🛡️ High |
| **Keychain.swift** | 94.63% | 93.88% | 🛡️ High |
| **TransactionBuilder.swift** | 93.75% | 92.48% | 🛡️ High |
| **Plutus.swift** | 92.89% | 91.46% | 🛡️ High |
| **Keys.swift** | 92.31% | 88.37% | 🛡️ High |
| **Withdrawals.swift** | 90.32% | 94.44% | 🛡️ High |
| **Transaction.swift** | 84.39% | 79.35% | 🛡️ High |
| **CSL.swift** | 80.72% | 67.44% | 🛡️ High (Bridge) |

**Overall Line Coverage: 93.31%**

## Why not 100%?

Achieving 100% line coverage in a library that wraps a native C/Rust core ([Cardano Serialization Library](https://github.com/Emurgo/cardano-serialization-lib)) presents specific challenges. The remaining roughly 6.5% of uncovered lines fall into the following categories:

### 1. Native Bridge Error Handling (<doc:CSL>)

The `CSL` helper class contains generic wrappers for C functions. These wrappers include error-checking logic like:
```swift
if !body(result, &error) {
    if let err = error {
        // ... throw CardanoError.cslError ...
    }
}
```
In many cases, the Rust core functions are designed such that they only return `false` (error) under conditions that are impossible to trigger with valid inputs (e.g., failed memory allocation or internal logic errors in the Rust core). Simulating these failures from the Swift side would require corrupted memory state, which would make the test suite unstable and unreliable.

### 2. Defensive guard blocks

We maintain defensive `guard` statements and `nil` checks for objects returned by the bridge to ensure the SDK never crashes, even if the underlying core has a version mismatch. Since the current pinned version of the core is stable and always returns valid pointers for the exercised scenarios, these "safety net" branches are never reached during standard testing.

### 3. Internal initializers and boilerplate

Certain classes have internal `init(pointer:)` methods intended for future expansion or for use in complex assembly scenarios that are not yet part of the public API surface. While we have exposed many of these for white-box testing, some remains uncovered to prioritize API stability.

### 4. LLVM Coverage Artifacts

Some `deinit` blocks and closing braces of complex closures are occasionally marked as "missed" by `llvm-cov` due to how the Swift compiler optimizes the binary for the test runner, even when the objects are properly deallocated.

## Conclusion

The current coverage level of **93.31%** ensures that all business-critical logic, cryptographic operations, and transaction building sequences are verified and stable. The remaining uncovered parts are primarily low-level infrastructure and safety checks.
