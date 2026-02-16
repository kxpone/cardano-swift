//
//  Transaction.swift
//  Cardano
//
//  Created by hellc.
//  Copyright © 2020-2026 KXP. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import CCardano

/// Represents the body of a Cardano transaction.
public class TransactionBody {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
}

/// Represents an input to a Cardano transaction (UTXO reference).
public class TransactionInput {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    /// Initializes a TransactionInput from a transaction hash and output index.
    /// - Parameter hash: The transaction hash (32 bytes) of the UTXO.
    /// - Parameter index: The output index within the transaction.
    /// - Throws: CardanoError if initialization fails.
    public init(hash: Data, index: UInt32) throws {
        let hashPtr = try hash.withUnsafeBytes { ptr in
            try CSL.callRPtr { csl_bridge_transaction_hash_from_bytes(ptr.bindMemory(to: UInt8.self).baseAddress!, uintptr_t(hash.count), $0, $1) }
        }
        self.pointer = try CSL.callRPtr { csl_bridge_transaction_input_new(hashPtr, Int64(index), $0, $1) }
        var p = hashPtr
        csl_bridge_rptr_free(&p)
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
}

/// Represents the witness set (signatures) for a Cardano transaction.
public class TransactionWitnessSet {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    /// Initializes a new empty TransactionWitnessSet.
    /// - Returns: A new empty TransactionWitnessSet.
    /// - Throws: CardanoError if initialization fails.
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_transaction_witness_set_new($0, $1) }
    }
    
    /// Sets the Plutus scripts for smart contract validation.
    /// - Parameter scripts: A PlutusScripts collection containing the scripts.
    /// - Throws: CardanoError if setting scripts fails.
    public func setPlutusScripts(scripts: PlutusScripts) throws {
        try CSL.voidCall { csl_bridge_transaction_witness_set_set_plutus_scripts(pointer, scripts.pointer, $0) }
    }
    
    /// Sets the Plutus data (datums) required by the scripts.
    /// - Parameter data: A PlutusList containing the datum objects.
    /// - Throws: CardanoError if setting data fails.
    public func setPlutusData(data: PlutusList) throws {
        try CSL.voidCall { csl_bridge_transaction_witness_set_set_plutus_data(pointer, data.pointer, $0) }
    }
    
    /// Sets the redeemers (script execution arguments) for this transaction.
    /// - Parameter redeemers: A Redeemers collection containing the redeemer objects.
    /// - Throws: CardanoError if setting redeemers fails.
    public func setRedeemers(redeemers: Redeemers) throws {
        try CSL.voidCall { csl_bridge_transaction_witness_set_set_redeemers(pointer, redeemers.pointer, $0) }
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
}

/// Represents a complete Cardano transaction, including the body and witness set (signatures).
public class Transaction {
    /// Opaque pointer to the underlying Rust transaction object.
    private let pointer: RPtr
    
    /// Initializes a transaction with its components.
    /// - Parameters:
    ///   - body: The `TransactionBody`.
    ///   - witnessSet: The `TransactionWitnessSet` containing signatures.
    ///   - auxiliaryData: Optional `AuxiliaryData`.
    public init(body: TransactionBody, witnessSet: TransactionWitnessSet, auxiliaryData: AuxiliaryData? = nil) throws {
        if let aux = auxiliaryData {
            self.pointer = try CSL.callRPtr { csl_bridge_transaction_new_with_auxiliary_data(body.pointer, witnessSet.pointer, aux.pointer, $0, $1) }
        } else {
            self.pointer = try CSL.callRPtr { csl_bridge_transaction_new(body.pointer, witnessSet.pointer, $0, $1) }
        }
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }

    /// Deserializes a transaction from a Hexadecimal string.
    /// - Parameter hex: The hex encoded CBOR of the transaction.
    public static func fromHex(_ hex: String) throws -> Transaction {
        let ptr = try CSL.callRPtr { csl_bridge_transaction_from_hex(hex, $0, $1) }
        return Transaction(pointer: ptr)
    }

    /// Internal initializer for creating transactions from existing pointers.
    private init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    /// Computes the transaction hash.
    /// Uses a "fixed" transaction body bridge to ensure consistent hashing across different CSL versions.
    /// - Returns: The transaction hash as a hexadecimal string.
    /// - Throws: CardanoError if hashing fails.
    public func hash() throws -> String {
        let body = try CSL.callRPtr { csl_bridge_transaction_body(pointer, $0, $1) }
        let bodyData = try CSL.getData { csl_bridge_transaction_body_to_bytes(body, $0, $1) }
        let fixedBody = try CSL.callRPtr { (res: UnsafeMutablePointer<RPtr>, err: UnsafeMutablePointer<CharPtr?>) -> Bool in
            bodyData.withUnsafeBytes { ptr in
                csl_bridge_fixed_transaction_body_from_bytes(ptr.bindMemory(to: UInt8.self).baseAddress!, uintptr_t(bodyData.count), res, err)
            }
        }
        let hash = try CSL.callRPtr { csl_bridge_fixed_transaction_body_tx_hash(fixedBody, $0, $1) }
        let hex = try CSL.getString { csl_bridge_transaction_hash_to_hex(hash, $0, $1) }
        
        var p1 = body
        var p2 = fixedBody
        var p3 = hash
        csl_bridge_rptr_free(&p1)
        csl_bridge_rptr_free(&p2)
        csl_bridge_rptr_free(&p3)
        
        return hex
    }
    
    /// Returns the Hexadecimal (CBOR) representation of the full transaction.
    /// - Returns: The transaction encoded as a hex string.
    /// - Throws: CardanoError if serialization fails.
    public func toHex() throws -> String {
        return try CSL.getString { csl_bridge_transaction_to_hex(pointer, $0, $1) }
    }
    
    /// Returns the raw bytes (CBOR) of the full transaction.
    /// - Returns: The transaction bytes as an array of UInt8.
    /// - Throws: CardanoError if serialization fails.
    public func toBytes() throws -> [UInt8] {
        let data = try CSL.getData { csl_bridge_transaction_to_bytes(pointer, $0, $1) }
        return [UInt8](data)
    }
    
    // MARK: - Priority 3: Async Batch Operations
    
    /// Asynchronously serializes multiple transactions to hex format in parallel
    /// - Parameter transactions: Array of Transaction objects to serialize
    /// - Returns: Array of hex-encoded transaction strings
    public static func toHex(transactions: [Transaction]) async throws -> [String] {
        return try await withThrowingTaskGroup(
            of: (Int, String).self,
            returning: [String].self
        ) { group in
            for (index, tx) in transactions.enumerated() {
                group.addTask {
                    let hex = try tx.toHex()
                    return (index, hex)
                }
            }
            
            var results = Array(repeating: "", count: transactions.count)
            for try await (index, hex) in group {
                results[index] = hex
            }
            return results
        }
    }
    
    /// Asynchronously parses multiple transactions from hex format in parallel
    /// - Parameter hexStrings: Array of hex-encoded transaction strings
    /// - Returns: Array of parsed Transaction objects
    public static func fromHex(hexStrings: [String]) async throws -> [Transaction] {
        return try await withThrowingTaskGroup(
            of: (Int, Transaction).self,
            returning: [Transaction].self
        ) { group in
            for (index, hex) in hexStrings.enumerated() {
                group.addTask {
                    let tx = try Transaction.fromHex(hex)
                    return (index, tx)
                }
            }
            
            var tempResults: [Int: Transaction] = [:]
            for try await (index, tx) in group {
                tempResults[index] = tx
            }
            
            return (0..<hexStrings.count).compactMap { tempResults[$0] }
        }
    }
}

extension Wallet {
    /// Signs a transaction body using the provided keychain.
    /// - Parameters:
    ///   - transactionBody: The `TransactionBody` to sign.
    ///   - keychain: The derived keychain (usually at index m/1852'/1815'/0'/0/X) to sign with.
    /// - Returns: A complete `Transaction` object ready for submission.
    /// - Throws: CardanoError if signing fails.
    public func sign(transactionBody: TransactionBody, keychain: Keychain) throws -> Transaction {
        let bodyData = try CSL.getData { csl_bridge_transaction_body_to_bytes(transactionBody.pointer, $0, $1) }
        let fixedBody = try CSL.callRPtr { (res: UnsafeMutablePointer<RPtr>, err: UnsafeMutablePointer<CharPtr?>) -> Bool in
            bodyData.withUnsafeBytes { ptr in
                csl_bridge_fixed_transaction_body_from_bytes(ptr.bindMemory(to: UInt8.self).baseAddress!, uintptr_t(bodyData.count), res, err)
            }
        }
        let hash = try CSL.callRPtr { csl_bridge_fixed_transaction_body_tx_hash(fixedBody, $0, $1) }
        let vkeyWitnesses = try CSL.callRPtr { csl_bridge_vkeywitnesses_new($0, $1) }
        
        let privateKey = try keychain.privateKey()
        let vkeyWitness = try CSL.callRPtr { csl_bridge_make_vkey_witness(hash, privateKey.pointer, $0, $1) }
        _ = try CSL.call { (res: UnsafeMutablePointer<Bool>, err: UnsafeMutablePointer<CharPtr?>) -> Bool in
            return csl_bridge_vkeywitnesses_add(vkeyWitnesses, vkeyWitness, res, err)
        }
        
        let witnessSet = try CSL.callRPtr { csl_bridge_transaction_witness_set_new($0, $1) }
        try CSL.voidCall { csl_bridge_transaction_witness_set_set_vkeys(witnessSet, vkeyWitnesses, $0) }
        
        var p1 = fixedBody
        var p2 = hash
        var p3 = vkeyWitnesses
        var p4 = vkeyWitness
        csl_bridge_rptr_free(&p1)
        csl_bridge_rptr_free(&p2)
        csl_bridge_rptr_free(&p3)
        csl_bridge_rptr_free(&p4)
        
        return try Transaction(body: transactionBody, witnessSet: TransactionWitnessSet(pointer: witnessSet), auxiliaryData: nil)
    }

    /// Asynchronously signs a transaction body using the provided keychain.
    /// - Parameters:
    ///   - transactionBody: The `TransactionBody` to sign.
    ///   - keychain: The derived keychain (usually at index m/1852'/1815'/0'/0/X) to sign with.
    /// - Returns: A complete `Transaction` object ready for submission.
    /// - Throws: CardanoError if signing fails.
    public func sign(transactionBody: TransactionBody, keychain: Keychain) async throws -> Transaction {
        return try await Task.detached(priority: .userInitiated) {
            try self.sign(transactionBody: transactionBody, keychain: keychain)
        }.value
    }
}
