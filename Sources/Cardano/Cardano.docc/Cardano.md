# Cardano

A high-performance Cardano SDK for Swift that works natively on **iOS**, **macOS**, **tvOS**, **watchOS**, and **Linux**.

## Overview

The Cardano Swift SDK bridges the industry-standard [Cardano Serialization Lib (CSL)](https://github.com/Emurgo/cardano-serialization-lib) via a thin Rust-C-Swift bridge. It provides high-level Swift abstractions for working with wallets, addresses, transactions, and smart contracts.

### Key Features

- **Pure Swift API**: High-level abstractions for Wallets, Addresses, and Transactions.
- **Async/Await Support**: Full async/await API for multi-core performance.
- **Universal Support**: One codebase for all Apple platforms and Linux.
- **Plutus V1/V2/V3**: Comprehensive smart contract support.

## Topics

### Essentials

- <doc:Addresses>
- <doc:Wallets>
- <doc:Transactions>

### Advanced Topics

- <doc:Plutus>
- <doc:Concurrency>
- <doc:Coverage>

### Reference

#### Foundation & Keys

- <doc:BigNum>
- <doc:Mnemonic>
- <doc:Keychain>
- <doc:Bip32PublicKey>
- <doc:Bip32PrivateKey>
- <doc:PublicKey>
- <doc:PrivateKey>
- <doc:Credential>

#### Wallet & Addresses

- <doc:Wallet>
- <doc:Address>
- <doc:RewardAddress>
- <doc:ByronAddress>

#### Transactions

- <doc:Transaction>
- <doc:TransactionBuilder>
- <doc:TransactionBody>
- <doc:TransactionInput>
- <doc:TransactionOutput>
- <doc:TransactionInputs>
- <doc:TransactionOutputs>
- <doc:TransactionWitnessSet>
- <doc:VKeyWitness>
- <doc:Value>
- <doc:Assets>
- <doc:MultiAsset>
- <doc:UTXO>
- <doc:Metadata>
- <doc:Metadatum>
- <doc:AuxiliaryData>

#### Plutus Smart Contracts

- <doc:PlutusData>
- <doc:PlutusScript>
- <doc:Redeemer>
- <doc:ExUnits>
- <doc:ExUnitPrices>
- <doc:CostModel>
- <doc:CostModels>
- <doc:Language>
- <doc:PlutusList>
- <doc:PlutusMap>
- <doc:PlutusMapValues>
- <doc:ConstrPlutusData>
- <doc:ScriptHash>
- <doc:PlutusScriptSource>
- <doc:MintWitness>

#### Staking & Governance

- <doc:Withdrawals>

#### Utilities

- <doc:AsyncHelpers>
- <doc:CSL>
