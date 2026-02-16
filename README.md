# Cardano Swift (Universal)

[![Swift CI](https://github.com/kxpone/cardano-swift/actions/workflows/swift.yml/badge.svg)](https://github.com/kxpone/cardano-swift/actions/workflows/swift.yml)
[![Swift Version](https://img.shields.io/badge/Swift-5.3+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20Linux-blue.svg)](https://github.com/kxpone/cardano-swift)
[![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Cardano.svg)](https://cocoapods.org/pods/Cardano)
[![License](https://img.shields.io/badge/License-MIT-black.svg)](LICENSE)

A high-performance Cardano SDK for Swift that works natively on **iOS**, **macOS**, **tvOS**, **watchOS**, and **Linux**. It bridges the industry-standard [Cardano Serialization Lib (CSL)](https://github.com/Emurgo/cardano-serialization-lib) via a thin Rust-C-Swift bridge.

## 🚀 Features

- **Pure Swift API**: High-level abstractions for Wallets, Addresses, and Transactions.
- **✅ Async/Await Support**: Full async/await API with Swift Concurrency for multi-core performance (up to 7.5x speedup).
- **Complete Documentation**: 200+ documented methods with parameters, returns, and error handling.
- **Native Performance**: No JavaScript or Node.js required. Runs at Rust speed.
- **Universal Support**: One codebase for mobile (iOS/watchOS), desktop (macOS), entertainment (tvOS), and server-side Swift (Linux).
- **Zero Configuration**: Automated build system for the native bridge.

## 🛠 Installation

### Swift Package Manager (Recommended)

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/kxpone/cardano-swift.git", from: "0.2.1")
]
```

**Note:** The first build may take some time as SPM will automatically download and compile the native Rust bridge for your host architecture. No manual action is required.

### CocoaPods

Add the following to your `Podfile`:

```ruby
pod 'Cardano', :git => 'https://github.com/kxpone/cardano-swift.git'
```

Running `pod install` will automatically trigger the native build process via `prepare_command`.

### Carthage

Add the following to your `Cartfile`:

```ogdl
github "kxpone/cardano-swift" "main"
```

Because this SDK relies on a native Rust bridge, you must run the bootstrap script after updating your dependencies:

```bash
carthage update
./Carthage/Checkouts/cardano-swift/scripts/init.sh
```

## ⚙️ How it works

The SDK features an **Auto-Bootstrap** system:
1. **Zero Configuration**: When you add the package, it detects your OS (Linux/macOS/iOS) and architecture.
2. **Pinned Core**: It compiles the [CSL Rust Bridge](https://github.com/Emurgo/csl-mobile-bridge) (fixed at version `9.0.1`) specifically for your machine. This ensures compatibility with Cardano Serialization Lib `15.0.3`.
3. **No External Dependencies**: You don't need to manually install any pre-compiled binaries or manage system libraries.

### 🍎 Apple Platform Support (tvOS & watchOS)

While **iOS** and **macOS** are supported on the stable Rust toolchain, **tvOS** and **watchOS** targets are currently Tier 2/3 and require the **nightly** toolchain.

To enable support for these platforms, ensure you have the nightly toolchain and relevant targets installed:

```bash
rustup toolchain install nightly
rustup target add aarch64-apple-tvos aarch64-apple-tvos-sim --toolchain nightly
rustup target add aarch64-apple-watchos aarch64-apple-watchos-sim --toolchain nightly
```

During build, the `init.sh` script will automatically:
1. Patch the underlying `rand_os` dependency to enable tvOS/watchOS support (these platforms were missing from the crate's platform checks)
2. Use `-Z build-std=core,alloc,std` to compile the Rust standard library from source for unsupported targets
3. Link with the Apple Security framework which is universally available on all Apple platforms

**Technical Details:** The build patches `rand_os v0.1.2` to recognize `tvOS` and `watchOS` as valid targets, allowing it to use the existing macOS/iOS implementation which leverages `SecRandomCopyBytes` from the Security framework.

## 🧪 Testing

Verify the installation by running tests:

```bash
swift test --enable-test-discovery
```

## 📦 Usage

### Derive Address from Mnemonic
```swift
// Valid 15-word mnemonic or longer
let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
let wallet = try Wallet(mnemonic: Mnemonic(phrase: words), networkId: 0) // 0 for testnet, 1 for mainnet

let address = try wallet.getAddress(account: 0, index: 0)
print("Bech32 Address: \(address.toBech32())")
```

### Build and Sign Transaction
```swift
// 1. Prepare Wallet and Keychain
let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
let mnemonic = Mnemonic(phrase: words)
let wallet = try Wallet(mnemonic: mnemonic, networkId: 0)
let keychain = try Keychain(mnemonic: mnemonic)

let myAddress = try wallet.getAddress(account: 0, index: 0)
let destination = try Address(bech32: "addr_test1qpu5sh7exv8v878q0p90v49f872kyv6968m6w86k4f8thqskkd69w2y3c848sh6lsh33u5m96v7a8tyd5whk60zay6xqlx0v9s")

// 2. Define UTXOs
let utxo = UTXO(
    txHash: "fd656fb1f4cf6fbbc36f2705568a4d3b7a970ec0b39f80cc81e1293626b77316",
    index: 0,
    value: Value(coin: 20_000_000),
    address: myAddress
)

// 3. Build Transaction
let builder = try TransactionBuilder()
try builder.addInputs(from: [utxo])
try builder.addOutput(address: destination, value: Value(coin: 10_000_000))
try builder.setTTL(ttl: 500000)

let body = try builder.build(changeAddress: myAddress)

// 4. Sign and get Hex
let transaction = try wallet.sign(transactionBody: body, keychain: keychain)
let hex = try transaction.toHex()
print("Signed Transaction Hex: \(hex)")
```

### Multi-Asset Transaction
```swift
let assets = try Assets()
try assets.add(assetName: "KXP", amount: 500)

let multiAsset = try MultiAsset()
try multiAsset.insert(policyId: "6b8d3c96102aa674a26fed7c394c8b8dc0778c1c5e4f2f45ccf411e3", assets: assets)

let value = try Value(coin: 2_000_000, multiAsset: multiAsset)
try builder.addOutput(address: destination, value: value)
```

### Transaction with Metadata
```swift
// Create Metadata
let metadata = try Metadata()
try metadata.insert(label: 674, value: Metadata.fromJSON(json: "{\"msg\": [\"Cardano Swift SDK\", \"Native Metadata\"]}"))

// Attach to Builder
let builder = try TransactionBuilder()
// ... add inputs/outputs ...
try builder.setAuxiliaryData(auxiliaryData: try AuxiliaryData(metadata: metadata))

let body = try builder.build(changeAddress: myAddress)
```
### Async/Await: Batch Address Generation
```swift
// Generate 100 addresses in parallel (up to 7.5x faster than sequential)
let wallet = try Wallet(mnemonic: Mnemonic(phrase: words), networkId: 0)

let addresses = try await wallet.getAddress(account: 0, startIndex: 0, count: 100)
print("Generated \(addresses.count) addresses concurrently")
```

### Async/Await: Batch Transaction Serialization
```swift
// Serialize multiple transactions in parallel (1.5x speedup for 50+ transactions)
let transactions: [Transaction] = /* ... */
let hexStrings = try await Transaction.toHex(transactions: transactions)

for (index, hex) in hexStrings.enumerated() {
    print("TX \(index): \(hex.prefix(32))...")
}
```

### Async/Await: Parallel Mnemonic Validation
```swift
// Validate 1000 mnemonics in parallel (non-blocking)
let phrases = [/* ... 1000 phrases ... */]
let validationResults = try await Mnemonic.validate(phrases: phrases)

let validCount = validationResults.filter { $0 }.count
print("\(validCount)/\(phrases.count) mnemonics are valid")
```

### Async/Await: Data Signing
```swift
// Sign data with non-blocking UI updates
let data = "message to sign".data(using: .utf8)!
let signature = try await wallet.signData(
    data: data,
    withAddress: address.toBech32()
)
print("Signature: \(signature.signature)")
print("Public Key: \(signature.key)")
```
## 📱 Mobile Support (iOS)

The SDK is fully compatible with iOS. For the best experience, ensure your environment has the necessary Rust targets:
```bash
rustup target add aarch64-apple-ios x86_64-apple-ios
```
The build system will automatically bundle these into the framework during the installation phase.

## 📚 Documentation

### Guides & Resources

| Document | Description |
|----------|-------------|
| **[Plutus Scripts Guide](./docs/PLUTUS_SCRIPTS.md)** | Complete Plutus V1/V2/V3 smart contract guide with cost analysis & examples |
| **[Concurrency & Performance](./docs/CONCURRENCY.md)** | High-performance async/await patterns, benchmarks, and 7.5x speedup analysis |
| **[CHANGELOG](./docs/CHANGELOG.md)** | Version history and feature releases |

### Quick Links

- **[Cardano Docs](https://docs.cardano.org/)** - Official Cardano documentation
- **[Plutus Docs](https://plutus.readthedocs.io/)** - Plutus smart contract reference
- **[CIP-31 (V2)](https://github.com/cardano-foundation/CIPs/tree/master/CIP-0031)** - Plutus V2 specification
- **[CIP-87 (V3)](https://github.com/cardano-foundation/CIPs/tree/master/CIP-0087)** - Plutus V3 specification

---

## 📊 Comparison

| Feature | [cardano-swift](https://github.com/kxpone/cardano-swift) | [CardanoKit](https://github.com/TokeoPay/CardanoKit) | [Cardano.swift](https://github.com/tesseract-one/Cardano.swift) | [swift-cardano-core](https://github.com/Kingpin-Apps/swift-cardano-core) | [CSL Bridge](https://github.com/Emurgo/csl-mobile-bridge) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **macOS Support** | ✅ (10.15+) | ✅ (15.0+) | ✅ (10.15+) | ✅ (14.0+) | ✅* |
| **iOS Support** | ✅ (13.0+) | ✅ (17.0+) | ✅ (13.0+) | ✅ (14.0+) | ✅ |
| **tvOS Support** | ✅ (13.0+) | ❌ | ❌ | ✅ (14.0+) | ✅* |
| **watchOS Support** | ✅ (6.0+) | ❌ | ❌ | ✅ (7.0+) | ✅* |
| **Linux Support** | ✅ (Universal) | ❌ | ⚠️ (Manual) | ✅ | ✅* |
| **Async/Await Support** | ✅ (Parallelized) | ✅ (Standard) | ❌ | ⚠️ (Basic) | ❌ |
| **BIP39 Mnemonics** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Transaction Builder** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Plutus V1/V2 Support** | ✅ | ⚠️ (Partial) | ❌ (Alonzo) | ✅ | ✅ |
| **Plutus V3 Support** | ✅ | ❌ | ❌ | ⚠️ (In-progress) | ✅ |
| **CIP-30 Data Signing** | ✅ | ✅ | ❌ | ❌ | ✅ |
| **Native Script Support** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Pure Swift (No Rust)** | ❌ | ❌ | ❌ | ✅ | ❌ |
| **Pinned Core Stability** | ✅ (v9.0.1) | ❌ (Alpha) | ❌ (Legacy) | ✅ (N/A) | ❌ |
| **Latest Era (Conway)** | ✅ | ✅ | ❌ | ✅ | ✅ |

*\* Supports any platform where Rust can be compiled (requires manual compilation for non-mobile targets).*

---

## 🏁 Roadmap

### 🏁 Done (v0.2.1)
- [x] **Universal Apple Support**: Native support for **tvOS** and **watchOS** platforms.
- [x] **Pinned Core Stability**: Native bridge core pinned to **v9.0.1** (CSL 15.0.3).
- [x] **Async/Await API**: Complete Swift Concurrency support (7.5x speedup for batch operations).
- [x] **Complete Documentation**: 200+ documented methods with parameters, returns, and errors.
- [x] **Universal Linux/macOS/iOS support** via unified Rust bridge.
- [x] **Auto-Bootstrap system** for SPM and CocoaPods.
- [x] **Address Management**: Shelley (Bech32), Byron (Base58), Pointer addresses.
- [x] **Transaction Builder**: Support for simple and complex transactions with automated change calculation.
- [x] **Multi-Asset Support**: Minting and transferring native tokens.
- [x] **Metadata Support**: Attaching JSON/CBOR metadata (labels).
- [x] **Staking Support**: Withdrawals and reward address derivation.
- [x] **Memory Safety**: Automated RPtr management and error handling from Rust core.
- [x] **CIP-30 Compatibility**: Data signing and verification.
- [x] **Plutus V1/V2/V3**: Full support for scripts, datums, and redeemers.
- [x] **Min-ADA Logic**: Automated calculation of minimum required ADA for multi-asset outputs.

### 📅 To Do
- [ ] **Governance (CIP-1694)**: Support for DRep registration, voting, and delegation (Conway era).
- [ ] **Native Scripts**: Multi-signature support (ALL, ANY, N-of-M) and time-locks.
- [ ] **Pluggable Providers**: Protocol-based interface for easy integration with Blockfrost, Koios, or Ogmios.
- [ ] **Unified Documentation**: Full API reference via DocC with detailed code examples.
- [ ] **Collateral & Change**: Automated collateral selection for smart contract interactions.

## 📜 License

MIT - See [LICENSE](LICENSE) for details.
Copyright © 2020-2026 KXP. All rights reserved.
