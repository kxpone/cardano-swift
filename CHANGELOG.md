# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-15

### 🚀 Added
- **Unified SDK Foundation**: Initial production-ready release of the Cardano Swift SDK. Built upon the industry-standard `cardano-serialization-lib` (CSL) to ensure maximum compatibility with the Cardano ecosystem.
- **Zero-Config Bootstrap (Auto-Discovery)**: Implemented an automated build system that detects the host environment (Linux, macOS, iOS) and its architecture (x86_64, ARM64). The `scripts/init.sh` automatically fetches or compiles the required native Rust binaries, eliminating manual setup hurdles for developers.
- **Comprehensive Address Management**: 
    - Full support for Shelley-era addresses: Base, Enterprise, Reward, and Pointer.
    - Legacy support for Byron-era addresses (Icarus/Daedalus style).
    - Seamless conversion between Bech32, Base58 (legacy), and raw Hex formats.
- **High-Level Transaction Builder**: 
    - Automated input selection from UTXO sets.
    - Precision fee calculation based on transaction size and native asset overhead.
    - Smart change addressing logic to automatically return excess funds to the sender.
    - Flexible Time-to-Live (TTL) configuration.
- **Native Multi-Asset Engine**: 
    - Full lifecycle support for Cardano Native Tokens (Minting, Burning, and Transferring).
    - Specialized `Assets` and `MultiAsset` containers for efficient management of multiple policies in a single transaction.
- **Rich Metadata Support**: 
    - Implementation of Auxiliary Data for attaching structured information to transactions.
    - Support for Metadata Labels (e.g., label 674 for data signing or 721 for NFT standards).
    - JSON-to-Metadata bridging for easy dApp integration.
- **Staking & Governance Ready**: 
    - Direct derivation of Reward Addresses from account keys.
    - Support for Staking Withdrawals and certificate handling for delegation.
- **CIP-30 Data Signing logic**: Integrated `signData` and signature verification logic, enabling the SDK to act as a secure backend for modern Cardano Web3 wallets.
- **Universal CI/CD Pipelines**: Orchestrated GitHub Actions to perform automated testing across Linux (Ubuntu), macOS (Intel/Silicon), and iOS (Simulator/Device) to ensure cross-platform stability.

### 🛠 Changed
- **Automatic Memory Management (ARC)**: Shifted from manual Rust pointer (`RPtr`) lifecycle management to a class-based Automatic Reference Counting model. Objects now automatically call `csl_bridge_rptr_free` in their `deinit` block, effectively preventing memory leaks in high-load scenarios.
- **Enhanced Type Safety**: Replaced generic pointer wrappers with strongly-typed Swift primitives (`PublicKey`, `KeyHash`, `Credential`, `Address`).
- **Modernized Test Architecture**: Migrated from static test manifests to Swift's modern Test Discovery, reducing project clutter and speeding up CI execution.
- **Version Compatibility**: Standardized on Swift 5.3+ to provide the widest possible compatibility for existing iOS and Server-side Swift projects.

### 🐞 Fixed
- Resolved memory leaks occurring during the chain-creation of configuration objects in `TransactionBuilder`.
- Fixed a scope issue in `Keychain` derivation where the entropy was not correctly preserved during mnemonic expansion.
- Corrected linking flags for Linux environments to ensure the `CCardano` module is found during the `swift test` phase.

### 🗑 Removed
- Obsolete `LinuxMain.swift` and `XCTestManifests.swift` files.
- Redundant byte-to-hex conversion helpers in favor of a centralized `Data` extension.

---
[0.1.0]: https://github.com/kxpone/cardano-swift/releases/tag/0.1.0
