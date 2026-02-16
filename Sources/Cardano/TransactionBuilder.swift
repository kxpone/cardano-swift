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

/// Managed wrapper for a mint builder.
public class MintBuilder {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
    
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_mint_builder_new($0, $1) }
    }
    
    public func addAsset(witness: MintWitness, assetName: AssetName, amount: BigInt) throws {
        try CSL.voidCall { csl_bridge_mint_builder_add_asset(pointer, witness.pointer, assetName.pointer, amount.pointer, $0) }
    }
}

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
    ///   - exUnitPrices: (Optional) Prices for Plutus execution units.
    public init(linearFeeA: UInt64 = 44, linearFeeB: UInt64 = 155381, poolDeposit: UInt64 = 500000000, keyDeposit: UInt64 = 2000000, exUnitPrices: ExUnitPrices? = nil) throws {
        let bigA = try CSL.callRPtr { csl_bridge_big_num_from_str(String(linearFeeA), $0, $1) }
        let bigB = try CSL.callRPtr { csl_bridge_big_num_from_str(String(linearFeeB), $0, $1) }
        let linearFee = try CSL.callRPtr {
            csl_bridge_linear_fee_new(bigA, bigB, $0, $1)
        }
        
        let config = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_new($0, $1) }
        let configWithFee = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_fee_algo(config, linearFee, $0, $1) }
        
        var currentConfig = configWithFee
        var exUnitsConfig: RPtr? = nil
        if let exUnitPrices = exUnitPrices {
            print("TransactionBuilder.init: setting exUnitPrices")
            let euc = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_ex_unit_prices(currentConfig, exUnitPrices.pointer, $0, $1) }
            exUnitsConfig = euc
            currentConfig = euc
        }

        let poolDep = try CSL.callRPtr { csl_bridge_big_num_from_str(String(poolDeposit), $0, $1) }
        let configWithPool = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_pool_deposit(currentConfig, poolDep, $0, $1) }
        print("TransactionBuilder.init: configWithPool created")
        
        let keyDep = try CSL.callRPtr { csl_bridge_big_num_from_str(String(keyDeposit), $0, $1) }
        let configWithKey = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_key_deposit(configWithPool, keyDep, $0, $1) }
        print("TransactionBuilder.init: configWithKey created")
        
        // Configuration for maximum transaction sizes and native asset costs (v8/v9 era defaults)
        let configWithSize = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_max_tx_size(configWithKey, 16384, $0, $1) }
        let configWithValSize = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_max_value_size(configWithSize, 5000, $0, $1) }
        
        let coinsPerByte = try CSL.callRPtr { csl_bridge_big_num_from_str("34482", $0, $1) }
        let configWithCoins = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_coins_per_utxo_byte(configWithValSize, coinsPerByte, $0, $1) }
        
        let configWithPure = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_prefer_pure_change(configWithCoins, true, $0, $1) }
        
        let finalConfig = try CSL.callRPtr { csl_bridge_transaction_builder_config_builder_build(configWithPure, $0, $1) }
        
        self.builder = try CSL.callRPtr { csl_bridge_transaction_builder_new(finalConfig, $0, $1) }
        
        // Clean up temporary config pointers
        var pointers = [bigA, bigB, linearFee, config, configWithFee, poolDep, configWithPool, keyDep, configWithKey, configWithSize, configWithValSize, coinsPerByte, configWithCoins, finalConfig]
        if let euc = exUnitsConfig {
            pointers.append(euc)
        }
        // for var p in pointers {
        //     csl_bridge_rptr_free(&p)
        // }
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
    
    /// Adds a Plutus script input to the transaction.
    /// - Parameters:
    ///   - witness: The `PlutusWitness` containing the script and redeemer.
    ///   - input: The `TransactionInput` to spend.
    ///   - amount: The amount (Value) of the UTXO.
    public func addPlutusScriptInput(witness: PlutusWitness, input: TransactionInput, amount: Value) throws {
        let amountPtr = try amount.toPointer()
        try CSL.voidCall { csl_bridge_transaction_builder_add_plutus_script_input(builder, witness.pointer, input.pointer, amountPtr, $0) }
        var p = amountPtr
        csl_bridge_rptr_free(&p)
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

    /// Adds a Plutus script input to the transaction.
    /// - Parameters:
    ///   - witness: The `PlutusWitness` containing script, datum, and redeemer.
    ///   - utxo: The `UTXO` to spend.
    public func addPlutusScriptInput(witness: PlutusWitness, utxo: UTXO) throws {
        let txHashPtr = try CSL.callRPtr { csl_bridge_transaction_hash_from_hex(utxo.txHash, $0, $1) }
        let inputPtr = try CSL.callRPtr { csl_bridge_transaction_input_new(txHashPtr, Int64(utxo.index), $0, $1) }
        let valPtr = try utxo.value.toPointer()
        
        try CSL.voidCall { csl_bridge_transaction_builder_add_plutus_script_input(builder, witness.pointer, inputPtr, valPtr, $0) }
        
        var p1 = txHashPtr
        var p2 = inputPtr
        var p3 = valPtr
        csl_bridge_rptr_free(&p1)
        csl_bridge_rptr_free(&p2)
        csl_bridge_rptr_free(&p3)
    }
    
    /// Sets the collateral inputs for the transaction (required for Plutus scripts).
    /// - Parameter utxos: An array of `UTXO` available as collateral.
    public func setCollateral(utxos: [UTXO]) throws {
        let inputs = try CSL.callRPtr { csl_bridge_transaction_unspent_outputs_new($0, $1) }
        for utxo in utxos {
            let txUnspentOutput = try utxo.toTransactionUnspentOutput()
            try CSL.voidCall { csl_bridge_transaction_unspent_outputs_add(inputs, txUnspentOutput, $0) }
            var p = txUnspentOutput
            csl_bridge_rptr_free(&p)
        }
        try CSL.voidCall { csl_bridge_transaction_builder_set_collateral(builder, inputs, $0) }
        var p = inputs
        csl_bridge_rptr_free(&p)
    }

    /// Adds a required signer to the transaction (must sign the final transaction).
    /// - Parameter keyHash: The `KeyHash` of the required signer.
    public func addRequiredSigner(keyHash: KeyHash) throws {
        try CSL.voidCall { csl_bridge_transaction_builder_add_required_signer(builder, keyHash.pointer, $0) }
    }

    /// Automatically calculates and sets the script data hash.
    /// - Parameter costModels: The `CostModels` used for calculation.
    public func calcScriptDataHash(costModels: CostModels) throws {
        try CSL.voidCall { csl_bridge_transaction_builder_calc_script_data_hash(builder, costModels.pointer, $0) }
    }

    /// Explicitly sets the script data hash.
    /// - Parameter hash: The script data hash as `Data`.
    public func setScriptDataHash(hash: Data) throws {
        let hashPtr = try hash.withUnsafeBytes { ptr in
            try CSL.callRPtr { csl_bridge_script_data_hash_from_bytes(ptr.bindMemory(to: UInt8.self).baseAddress!, uintptr_t(hash.count), $0, $1) }
        }
        try CSL.voidCall { csl_bridge_transaction_builder_set_script_data_hash(builder, hashPtr, $0) }
        var p = hashPtr
        csl_bridge_rptr_free(&p)
    }

    /// Adds a Plutus mint witness for a specific asset.
    /// - Parameters:
    ///   - witness: The `MintWitness` (script and redeemer).
    ///   - assetName: The name of the asset to mint.
    ///   - amount: The amount to mint (positive) or burn (negative).
    public func addPlutusMintWitness(witness: MintWitness, assetName: AssetName, amount: Int64) throws {
        let amountBigInt = try BigInt(string: String(amount))
        let mintBuilder = try MintBuilder()
        try mintBuilder.addAsset(witness: witness, assetName: assetName, amount: amountBigInt)
        try CSL.voidCall { csl_bridge_transaction_builder_set_mint_builder(builder, mintBuilder.pointer, $0) }
    }

    /// Adds an extra datum to the witness set.
    /// - Parameter datum: The `PlutusData` to add.
    public func addExtraWitnessDatum(datum: PlutusData) throws {
        try CSL.voidCall { csl_bridge_transaction_builder_add_extra_witness_datum(builder, datum.pointer, $0) }
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

    // MARK: - Async API Methods

    /// Asynchronously adds a list of UTXOs as inputs.
    /// Executes input preparation on a background thread.
    /// - Parameter utxos: An array of `UTXO` objects available to spend.
    public func addInputs(from utxos: [UTXO]) async throws {
        return try await Task.detached(priority: .userInitiated) {
            try self.addInputs(from: utxos)
        }.value
    }

    /// Asynchronously adds a Plutus script input.
    /// - Parameters:
    ///   - witness: The `PlutusWitness` containing script, datum, and redeemer.
    ///   - utxo: The `UTXO` to spend.
    public func addPlutusScriptInput(witness: PlutusWitness, utxo: UTXO) async throws {
        return try await Task.detached(priority: .userInitiated) {
            try self.addPlutusScriptInput(witness: witness, utxo: utxo)
        }.value
    }

    /// Asynchronously finalizes the transaction construction.
    /// Performs fee calculation and change calculation on a background thread.
    /// Recommended for complex transactions with many inputs/outputs.
    /// - Parameter changeAddress: The `Address` where the remaining funds should be sent.
    /// - Returns: A `TransactionBody` containing the finalized transaction details.
    public func build(changeAddress: Address) async throws -> TransactionBody {
        return try await Task.detached(priority: .userInitiated) {
            try self.build(changeAddress: changeAddress)
        }.value
    }

    /// Asynchronously sets the collateral inputs.
    /// - Parameter utxos: An array of `UTXO` available as collateral.
    public func setCollateral(utxos: [UTXO]) async throws {
        return try await Task.detached(priority: .userInitiated) {
            try self.setCollateral(utxos: utxos)
        }.value
    }
}
