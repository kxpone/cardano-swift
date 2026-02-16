# Addresses

Working with Cardano addresses in Shelley and Byron formats.

## Overview

In the Cardano Swift SDK, the <doc:Address> class is the primary interface for handling addresses. It supports Bech32, Hex, and various address types including Base, Enterprise, Pointer, and Reward addresses.

### Creating an Address

You can create an `Address` from its Bech32 representation:

```swift
let address = try Address(bech32: "addr_test1qpu5sh7exv8v878q0p90v49f872kyv6968m6w86k4f8thqskkd69w2y3c848sh6lsh33u5m96v7a8tyd5whk60zay6xqlx0v9s")
```

Or from a Hex string:

```swift
let address = try Address(hex: "008bdfbc8777174624e54e4c3dcf0629738acb49bf44a2c9ac325c110300a875a6435bd787864f14ed60f089f268b8b0e796033324f6f1f4bd")
```

### Specialized Address Types

#### Enterprise Address

An enterprise address contains only a payment credential and no staking part.

```swift
let enterprise = try Address.enterprise(
    networkId: 0, 
    paymentCredential: myCredential
)
```

#### Reward Address

A reward address is used for staking and contains only a stake credential.

```swift
let reward = try Address.reward(
    networkId: 0, 
    stakeCredential: myStakeCredential
)
```

## Topics

### Reference

- <doc:Address>
