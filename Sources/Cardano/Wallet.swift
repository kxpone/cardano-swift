//
//  Wallet.swift
//  Cardano
//
//  Created by hellc.
//  Copyright © 2020-2026 KXP. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import CCardano

/// High-level interface for managing a Cardano wallet.
/// Provides functionality for address derivation and data signing using a mnemonic.
public class Wallet {
    /// Internal BIP32 keychain used for key derivation.
    internal let keychain: Keychain
    /// Current network ID (0 for Testnet, 1 for Mainnet).
    public let networkId: UInt8
    
    /// Initializes a new wallet from a mnemonic phrase.
    /// - Parameters:
    ///   - mnemonic: The `Mnemonic` instance containing the recovery phrase.
    ///   - networkId: The target network (defaults to 1 - Mainnet).
    /// - Throws: CardanoError if wallet initialization fails.
    public init(mnemonic: Mnemonic, networkId: UInt8 = 1) throws {
        self.keychain = try Keychain(mnemonic: mnemonic)
        self.networkId = networkId
    }
    
    /// Derives a Shelley base address (Payment + Staking) for a specific account and index.
    /// Uses standard BIP44 derivation path: `m/1852'/1815'/account'/0/index`.
    /// - Parameters:
    ///   - account: The account index (hardened).
    ///   - index: The address index within the account.
    /// - Returns: An `Address` object representing the derived base address.
    /// - Throws: CardanoError if derivation fails.
    public func getAddress(account: UInt32 = 0, index: UInt32 = 0) throws -> Address {
        let paymentPath = "m/1852'/1815'/\(account)'/0/\(index)"
        let stakePath = "m/1852'/1815'/\(account)'/2/0"
        
        // High-level public key derivation
        let paymentCred = try keychain.derive(path: paymentPath).publicKey().toRawKey().hash().toCredential()
        let stakeCred = try keychain.derive(path: stakePath).publicKey().toRawKey().hash().toCredential()
        
        let baseAddrPointer = try CSL.callRPtr { csl_bridge_base_address_new(Int64(networkId), paymentCred.pointer, stakeCred.pointer, $0, $1) }
        let addrPointer = try CSL.callRPtr { csl_bridge_base_address_to_address(baseAddrPointer, $0, $1) }
        
        return Address(pointer: addrPointer)
    }

    /// Signs raw data using the wallet's private key.
    /// Compatible with CIP-30 standards for decentralized applications.
    /// - Parameters:
    ///   - data: The binary data to be signed.
    ///   - address: The intended address (informative).
    /// - Returns: A `DataSignature` containing the hex-encoded signature and public key.
    /// - Throws: CardanoError if signing fails.
    public func signData(data: Data, withAddress address: String) throws -> DataSignature {
        let privateKey = try keychain.privateKey()
        let hashData = try CSL.callRPtr { (res: UnsafeMutablePointer<RPtr>, err: UnsafeMutablePointer<CharPtr?>) -> Bool in
            data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
                csl_bridge_transaction_hash_from_bytes(ptr.bindMemory(to: UInt8.self).baseAddress!, uintptr_t(data.count), res, err)
            }
        }
        
        let signature = try CSL.callRPtr { csl_bridge_make_vkey_witness(hashData, privateKey.pointer, $0, $1) }
        let sig = try CSL.callRPtr { csl_bridge_vkeywitness_signature(signature, $0, $1) }
        let vkey = try CSL.callRPtr { csl_bridge_vkeywitness_vkey(signature, $0, $1) }
        
        return try DataSignature(signature: sig, key: vkey)
    }

    // MARK: - Async API Methods

    /// Asynchronously derives a Shelley base address.
    /// Executes BIP32 key derivation on a background thread to avoid blocking the main thread.
    /// Recommended for UI applications and when deriving multiple addresses.
    /// - Parameters:
    ///   - account: The account index (hardened).
    ///   - index: The address index within the account.
    /// - Returns: An `Address` object representing the derived base address.
    /// - Throws: CardanoError if derivation fails.
    public func getAddressAsync(account: UInt32 = 0, index: UInt32 = 0) async throws -> Address {
        return try await Task.detached(priority: .userInitiated) {
            try self.getAddress(account: account, index: index)
        }.value
    }

    /// Asynchronously signs raw data using the wallet's private key.
    /// Executes Ed25519 signing on a background thread.
    /// - Parameters:
    ///   - data: The binary data to be signed.
    ///   - address: The intended address (informative).
    /// - Returns: A `DataSignature` containing the hex-encoded signature and public key.
    /// - Throws: CardanoError if signing fails.
    public func signDataAsync(data: Data, withAddress address: String) async throws -> DataSignature {
        return try await Task.detached(priority: .userInitiated) {
            try self.signData(data: data, withAddress: address)
        }.value
    }

    /// Asynchronously derives multiple addresses in parallel.
    /// Significantly faster than sequential derivation, especially for large batches (100+ addresses).
    /// - Parameters:
    ///   - account: The account index (hardened).
    ///   - startIndex: The starting address index.
    ///   - count: The number of addresses to derive.
    /// - Returns: An array of `Address` objects in order.
    /// - Throws: CardanoError if derivation fails.
    public func getAddressesAsync(account: UInt32 = 0, startIndex: UInt32 = 0, count: Int) async throws -> [Address] {
        let addresses = try await withThrowingTaskGroup(of: (Int, Address).self, returning: [Address].self) { group in
            for i in 0..<count {
                let index = startIndex + UInt32(i)
                group.addTask {
                    let addr = try self.getAddress(account: account, index: index)
                    return (i, addr)
                }
            }
            
            var results = [(Int, Address)]()
            for try await (idx, addr) in group {
                results.append((idx, addr))
            }
            
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
        return addresses
    }

    /// Asynchronously signs multiple data payloads in parallel.
    /// Useful for batch signing operations.
    /// - Parameters:
    ///   - dataList: Array of tuples (data to sign, address).
    /// - Returns: Array of `DataSignature` objects in the same order as input.
    /// - Throws: CardanoError if signing fails.
    public func signDataBatchAsync(dataList: [(data: Data, address: String)]) async throws -> [DataSignature] {
        let signatures = try await withThrowingTaskGroup(of: (Int, DataSignature).self, returning: [DataSignature].self) { group in
            for (idx, item) in dataList.enumerated() {
                group.addTask {
                    let sig = try self.signData(data: item.data, withAddress: item.address)
                    return (idx, sig)
                }
            }
            
            var results = [(Int, DataSignature)]()
            for try await (idx, sig) in group {
                results.append((idx, sig))
            }
            
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
        return signatures
    }
}

/// A container for cryptographic signatures of data.
public struct DataSignature {
    /// The Hex-encoded Ed25519 signature.
    public let signature: String
    /// The Hex-encoded public key used for signing.
    public let key: String
    
    /// Internal initializer from Rust object pointers.
    /// - Parameter signature: RPtr to the Ed25519 signature.
    /// - Parameter key: RPtr to the verification key.
    /// - Throws: CardanoError if conversion fails.
    internal init(signature: RPtr, key: RPtr) throws {
        self.signature = try CSL.getString { csl_bridge_ed25519_signature_to_hex(signature, $0, $1) }
        let pubKey = try CSL.callRPtr { csl_bridge_vkey_public_key(key, $0, $1) }
        self.key = try CSL.getString { csl_bridge_public_key_to_hex(pubKey, $0, $1) }
    }
}

extension Data {
    /// Internal helper for hex string representation.
    var hexDescription: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}
