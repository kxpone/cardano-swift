# Wallets

Managing keys and deriving addresses with Mnemonic and Wallet.

## Overview

The SDK provides a high-level <doc:Wallet> class that simplifies key management and address derivation following CIP-1852 standards.

### Working with Mnemonics

First, create a <doc:Mnemonic> from a recovery phrase:

```swift
let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
let mnemonic = Mnemonic(phrase: words)
```

### Initializing a Wallet

Initialize a wallet with the mnemonic and network ID (0 for testnet, 1 for mainnet):

```swift
let wallet = try Wallet(mnemonic: mnemonic, networkId: 0)
```

### Deriving Addresses

Derive addresses for specific accounts and indices:

```swift
let address = try wallet.getAddress(account: 0, index: 0)
print("Address: \(try address.toBech32())")
```

Generate multiple addresses concurrently:

```swift
let addresses = try await wallet.getAddress(account: 0, startIndex: 0, count: 20)
```

## Topics

### Reference

- <doc:Wallet>
- <doc:Mnemonic>
- <doc:Keychain>
