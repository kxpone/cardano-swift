//
//  Value.swift
//  Cardano
//
//  Created by hellc.
//  Copyright © 2020-2026 KXP. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import CCardano

/// Represents the total asset balance of a transaction output, including ADA (coin) and optional native tokens.
public struct Value {
    /// The amount of ADA in Lovelace (1 ADA = 1,000,000 Lovelace).
    public let coin: UInt64
    /// Optional collection of native assets associated with this value.
    public let multiAsset: MultiAsset?
    
    /// Initializes a Value object.
    /// - Parameters:
    ///   - coin: Amount in Lovelace (1 ADA = 1,000,000 Lovelace).
    ///   - multiAsset: (Optional) `MultiAsset` container for native tokens.
    public init(coin: UInt64, multiAsset: MultiAsset? = nil) {
        self.coin = coin
        self.multiAsset = multiAsset
    }
    
    /// Internal helper to convert this struct into a native Rust `Value` object.
    /// - Returns: An RPtr pointing to the Value.
    /// - Throws: CardanoError if conversion fails.
    internal func toPointer() throws -> RPtr {
        let coinBigNum = try CSL.callRPtr { csl_bridge_big_num_from_str(String(coin), $0, $1) }
        let value = try CSL.callRPtr { csl_bridge_value_new(coinBigNum, $0, $1) }
        
        if let multiAsset = multiAsset {
            try CSL.voidCall { csl_bridge_value_set_multiasset(value, multiAsset.pointer, $0) }
        }
        
        var p = coinBigNum
        csl_bridge_rptr_free(&p)
        
        return value
    }
}
