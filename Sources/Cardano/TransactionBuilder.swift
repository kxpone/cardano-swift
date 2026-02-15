//
//  TransactionBuilder.swift
//  Cardano
//
//  Created by hellc.
//  Copyright © 2020-2026 KXP. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import CCardano

/// A high-level helper for constructing Cardano transactions.
/// Handles fee calculation, input selection, outputs, and automatic change addressing.
public class TransactionBuilder {
    /// Opaque pointer to the internal Rust TransactionBuilder object.
    internal let builder: RPtr
    
    /// Initializes a new builder with specific network configuration.
    /// Default values correspond to common Cardano mainnet/preprod settings.
    /// - Parameters:
    ///   - linearFeeA: The fixed per-transaction fee component.
    ///   - linearFeeB: The fee component per byte of transaction size.
    ///   - poolDeposit: Amount required for pool registration.
    ///   - keyDeposit: Amount required for stake key registration.
    public init(linearFeeA: UInt64 = 44, linearFeeB: UInt64 = 155381, poolDeposit: UInt64 = 500000000, keyDeposit: UInt64 = 2000000) throws {
        let bigA = try CSL.callRPtr { csl_bridge_big_num_from_str(String(linearFeeA), $0, $1) }
        let bigB = try CSL.callRPtr { csl_bridge_big_num_from_str(String(linearFeeB), $0, $1) }
        let linearFee = try CSL.callRPtr {
            csl_bridge_linear_fee_new(bigA, bigB, $0, $1)
        }
        
        let config = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_new($0, $1) }
        let configWithFee = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_fee_algo(config, linearFee, $0, $1) }
        
        let poolDep = try CSL.callRPtr { csl_bridge_big_num_from_str(String(poolDeposit), $0, $1) }
        let configWithPool = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_pool_deposit(configWithFee, poolDep, $0, $1) }
        
        let keyDep = try CSL.callRPtr { csl_bridge_big_num_from_str(String(keyDeposit), $0, $1) }
        let configWithKey = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_key_deposit(configWithPool, keyDep, $0, $1) }
        
        // Configuration for maximum transaction sizes and native asset costs (v8/v9 era defaults)
        let configWithSize = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_max_tx_size(configWithKey, 16384, $0, $1) }
        let configWithValSize = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_max_value_size(configWithSize, 5000, $0, $1) }
        
        let coinsPerByte = try CSL.callRPtr { csl_bridge_big_num_from_str("34482", $0, $1) }
        let configWithCoins = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_coins_per_utxo_byte(configWithValSize, coinsPerByte, $0, $1) }
        
        let finalConfig = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_build(configWithCoins, $0, $1) }
        
        self.builder = try CSL.callRPtr { csl_bridge_transaction_builder_new(finalConfig, $0, $1) }
        
        // Clean up temporary config pointers
        let pointers = [bigA, bigB, linearFee, config, configWithFee, poolDep, configWithPool, keyDep, configWithKey, configWithSize, configWithValSize, coinsPerByte, configWithCoins, finalConfig]
        for var p in pointers {
            csl_bridge_rptr_free(&p)
        }
    }

    deinit {
        var p = builder
        csl_bridge_rptr_free(&p)
    }
    
    /// Adds a destination output to the transaction.
    /// - Parameters:
    ///   - address: The recipient's `Address`.
    ///   - value: The amount and assets to send.
    public func addOutput(address: Address, value: Value) throws {
        let valPtr = try value.toPointer()
        let output = try CSL.callRPtr { csl_bridge_transaction_output_new(address.pointer, valPtr, $0, $1) }
        try CSL.voidCall { csl_bridge_transaction_builder_add_output(builder, output, $0) }
        
        var p1 = valPtr
        var p2 = output
        csl_bridge_rptr_free(&p1)
        csl_bridge_rptr_free(&p2)
    }
    
    /// Adds a list of Unspent Transaction Outputs (UTXOs) as inputs to the builder.
    /// - Parameter utxos: An array of `UTXO` objects available to spend.
    public func addInputs(from utxos: [UTXO]) throws {
        let inputs = try CSL.callRPtr { csl_bridge_transaction_unspent_outputs_new($0, $1) }
        for utxo in utxos {
            let txUnspentOutput = try utxo.toTransactionUnspentOutput()
            try CSL.voidCall { csl_bridge_transaction_unspent_outputs_add(inputs, txUnspentOutput, $0) }
            var p = txUnspentOutput
            csl_bridge_rptr_free(&p)
        }
        try CSL.voidCall { csl_bridge_transaction_builder_add_inputs_from(builder, inputs, 0, $0) }
        var p = inputs
        csl_bridge_rptr_free(&p)
    }
    
    /// Sets the Time-to-Live (TTL) for the transaction.
    /// - Parameter ttl: The slot number after which the transaction becomes invalid.
    public func setTTL(ttl: UInt32) throws {
        try CSL.voidCall { csl_bridge_transaction_builder_set_ttl(builder, Int64(ttl), $0) }
    }
    
    /// Attaches auxiliary data (metadata/scripts) to the transaction.
    /// - Parameter auxiliaryData: The `AuxiliaryData` to attach.
    public func setAuxiliaryData(auxiliaryData: AuxiliaryData) throws {
        try CSL.voidCall { csl_bridge_transaction_builder_set_auxiliary_data(builder, auxiliaryData.pointer, $0) }
    }

    /// Attaches certificates (e.g., stake registration or delegation) to the transaction.
    /// - Parameter certificates: RPtr to the certificates collection.
    public func setCertificates(certificates: RPtr) throws {
        try CSL.voidCall { csl_bridge_transaction_builder_set_certs(builder, certificates, $0) }
    }
    
    /// Finalizes the transaction construction.
    /// Calculates the required fee and sends the remaining balance to the change address.
    /// - Parameter changeAddress: The `Address` where the remaining funds should be sent.
    /// - Returns: A `TransactionBody` containing the finalized transaction details.
    public func build(changeAddress: Address) throws -> TransactionBody {
        _ = try CSL.call { (res: UnsafeMutablePointer<Bool>, err: UnsafeMutablePointer<CharPtr?>) -> Bool in
            csl_bridge_transaction_builder_add_change_if_needed(builder, changeAddress.pointer, res, err)
        }
        let ptr = try CSL.callRPtr { csl_bridge_transaction_builder_build(builder, $0, $1) }
        return TransactionBody(pointer: ptr)
    }
}
