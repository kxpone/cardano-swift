//
//  UTXO.swift
//  Cardano
//
//  Created by hellc.
//  Copyright © 2020-2026 KXP. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import CCardano

/// Represents an Unspent Transaction Output (UTXO) on the Cardano blockchain.
/// A UTXO is defined by its source transaction hash, output index, the amount it holds, and the owning address.
public struct UTXO {
    /// The hexadecimal string of the transaction that created this output.
    public let txHash: String
    /// The index of this output in the source transaction.
    public let index: UInt32
    /// The value (ADA and tokens) contained in this output.
    public let value: Value
    /// The address that owns this output.
    public let address: Address
    
    /// Initializes a new UTXO record.
    /// - Parameters:
    ///   - txHash: Hexadecimal transaction hash.
    ///   - index: Output index.
    ///   - value: Total value (coin + multi-assets).
    ///   - address: Owning wallet address.
    public init(txHash: String, index: UInt32, value: Value, address: Address) {
        self.txHash = txHash
        self.index = index
        self.value = value
        self.address = address
    }
    
    /// Internal helper to convert this struct into a native Rust `TransactionUnspentOutput` object.
    internal func toTransactionUnspentOutput() throws -> RPtr {
        let txHashPtr = try CSL.callRPtr { csl_bridge_transaction_hash_from_hex(txHash, $0, $1) }
        let inputPtr = try CSL.callRPtr { csl_bridge_transaction_input_new(txHashPtr, Int64(index), $0, $1) }
        let valuePtr = try value.toPointer()
        let outputPtr = try CSL.callRPtr { csl_bridge_transaction_output_new(address.pointer, valuePtr, $0, $1) }
        let res = try CSL.callRPtr { csl_bridge_transaction_unspent_output_new(inputPtr, outputPtr, $0, $1) }
        
        var p1 = txHashPtr
        var p2 = inputPtr
        var p3 = valuePtr
        var p4 = outputPtr
        csl_bridge_rptr_free(&p1)
        csl_bridge_rptr_free(&p2)
        csl_bridge_rptr_free(&p3)
        csl_bridge_rptr_free(&p4)
        
        return res
    }
}
