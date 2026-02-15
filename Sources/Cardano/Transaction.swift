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

/// Represents the witness set (signatures) for a Cardano transaction.
public class TransactionWitnessSet {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
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
    public func toHex() throws -> String {
        return try CSL.getString { csl_bridge_transaction_to_hex(pointer, $0, $1) }
    }
    
    /// Returns the raw bytes (CBOR) of the full transaction.
    public func toBytes() throws -> [UInt8] {
        let data = try CSL.getData { csl_bridge_transaction_to_bytes(pointer, $0, $1) }
        return [UInt8](data)
    }
}

extension Wallet {
    /// Signs a transaction body using the provided keychain.
    /// - Parameters:
    ///   - transactionBody: The `TransactionBody` to constructed transaction body.
    ///   - keychain: The derived keychain (usually at index m/1852'/1815'/0'/0/X) to sign with.
    /// - Returns: A complete `Transaction` object ready for submission.
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
}
