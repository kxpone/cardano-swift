# Transactions

Building, signing, and serializing transactions.

## Overview

The <doc:TransactionBuilder> handles the complexity of balancing inputs, outputs, and fees.

### Basic Transaction

```swift
// 1. Initialize builder
let builder = try TransactionBuilder()

// 2. Add inputs (UTXOs)
try builder.addInputs(from: [utxo])

// 3. Add outputs
try builder.addOutput(address: destination, value: Value(coin: 10_000_000))

// 4. Set TTL (Time To Live)
try builder.setTTL(ttl: 500_000)

// 5. Build and calculate change
let body = try builder.build(changeAddress: myAddress)
```

### Signing and Serialization

Sign the transaction body using a <doc:Wallet>:

```swift
let transaction = try wallet.sign(transactionBody: body, keychain: keychain)
let hex = try transaction.toHex()
```

## Topics

### Reference

- <doc:Transaction>
- <doc:TransactionBuilder>
- <doc:UTXO>
- <doc:Value>
- <doc:Assets>
