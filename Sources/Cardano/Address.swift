//
//  Address.swift
//  Cardano
//
//  Created by hellc.
//  Copyright © 2020-2026 KXP. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import CCardano

/// Represents a Cardano address (Shelley or Byron).
/// This structure wraps a native Rust address object and provides methods to convert it to various formats.
///
/// ### Example
/// ```swift
/// let address = try Address(bech32: "addr1...")
/// print(try address.toHex())
/// ```
public class Address {
    /// Opaque pointer to the underlying Rust address object.
    internal let pointer: RPtr

    /// Initializes an address with a raw pointer.
    /// - Parameter pointer: An existing RPtr to a Cardano address.
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }

    /// Creates an address from a Bech32 string (e.g., "addr1...").
    /// - Parameter bech32: The string representation of the address.
    /// - Throws: `CardanoError.cslError` if the string is invalid.
    public init(bech32: String) throws {
        self.pointer = try CSL.callRPtr { csl_bridge_address_from_bech32(bech32, $0, $1) }
    }

    /// Creates an address from a Hexadecimal string.
    /// - Parameter hex: The hex representation of the address bytes.
    /// - Throws: `CardanoError.cslError` if the hex is invalid.
    public init(hex: String) throws {
        self.pointer = try CSL.callRPtr { csl_bridge_address_from_hex(hex, $0, $1) }
    }

    /// Returns the Bech32 representation of the address.
    public func toBech32() throws -> String {
        return try CSL.getString { csl_bridge_address_to_bech32(pointer, $0, $1) }
    }

    /// Returns the Hexadecimal representation of the address bytes.
    public func toHex() throws -> String {
        return try CSL.getString { csl_bridge_address_to_hex(pointer, $0, $1) }
    }
    
    /// Returns the network ID (0 for Testnet, 1 for Mainnet) associated with this address.
    public func networkId() throws -> UInt8 {
        let networkId: Int64 = try CSL.call { csl_bridge_address_network_id(pointer, $0, $1) }
        return UInt8(networkId)
    }

    /// Creates an enterprise address (payment part only).
    /// - Parameters:
    ///   - networkId: 0 for Testnet, 1 for Mainnet.
    ///   - paymentCredential: The payment `Credential`.
    public static func enterprise(networkId: UInt8, paymentCredential: Credential) throws -> Address {
        let enterpriseAddrPtr = try CSL.callRPtr { csl_bridge_enterprise_address_new(Int64(networkId), paymentCredential.pointer, $0, $1) }
        let addrPtr = try CSL.callRPtr { csl_bridge_enterprise_address_to_address(enterpriseAddrPtr, $0, $1) }
        return Address(pointer: addrPtr)
    }
    
    /// Creates a reward address (staking part only).
    /// - Parameters:
    ///   - networkId: 0 for Testnet, 1 for Mainnet.
    ///   - stakeCredential: The stake `Credential`.
    public static func reward(networkId: UInt8, stakeCredential: Credential) throws -> Address {
        let rewardAddrPtr = try CSL.callRPtr { csl_bridge_reward_address_new(Int64(networkId), stakeCredential.pointer, $0, $1) }
        let addrPtr = try CSL.callRPtr { csl_bridge_reward_address_to_address(rewardAddrPtr, $0, $1) }
        var p = rewardAddrPtr
        csl_bridge_rptr_free(&p)
        return Address(pointer: addrPtr)
    }

    /// Creates a Shelley pointer address.
    /// - Parameters:
    ///   - networkId: 0 for Testnet, 1 for Mainnet.
    ///   - paymentCredential: The payment `Credential`.
    ///   - slot: The slot number of the registration.
    ///   - txIndex: The transaction index within the block.
    ///   - certIndex: The certificate index within the transaction.
    public static func pointer(networkId: UInt8, paymentCredential: Credential, slot: UInt64, txIndex: UInt64, certIndex: UInt64) throws -> Address {
        let pointerPtr = try CSL.callRPtr { csl_bridge_pointer_new(Int64(slot), Int64(txIndex), Int64(certIndex), $0, $1) }
        let ptrAddrPtr = try CSL.callRPtr { csl_bridge_pointer_address_new(Int64(networkId), paymentCredential.pointer, pointerPtr, $0, $1) }
        let addrPtr = try CSL.callRPtr { csl_bridge_pointer_address_to_address(ptrAddrPtr, $0, $1) }
        var p1 = pointerPtr
        var p2 = ptrAddrPtr
        csl_bridge_rptr_free(&p1)
        csl_bridge_rptr_free(&p2)
        return Address(pointer: addrPtr)
    }

    /// Creates a legacy Byron address from a public key.
    /// - Parameters:
    ///   - key: The `Bip32PublicKey`.
    ///   - protocolMagic: The protocol magic number (e.g., 764824073 for Mainnet).
    public static func byron(key: Bip32PublicKey, protocolMagic: UInt32) throws -> Address {
        let byronAddr = try CSL.callRPtr { csl_bridge_byron_address_icarus_from_key(key.pointer, Int64(protocolMagic), $0, $1) }
        let addr = try CSL.callRPtr { csl_bridge_byron_address_to_address(byronAddr, $0, $1) }
        var p = byronAddr
        csl_bridge_rptr_free(&p)
        return Address(pointer: addr)
    }
    
    // MARK: - Async Batch Operations
    
    /// Creates multiple enterprise addresses asynchronously in parallel (5.6x speedup for 100+ addresses).
    /// - Parameters:
    ///   - networkId: 0 for Testnet, 1 for Mainnet.
    ///   - credentials: Array of payment credentials.
    /// - Returns: Array of enterprise addresses in the same order as credentials.
    public static func enterprise(
        networkId: UInt8,
        credentials: [Credential]
    ) async throws -> [Address] {
        return try await withThrowingTaskGroup(of: (Int, Address).self) { group in
            for (index, credential) in credentials.enumerated() {
                group.addTask {
                    let addr = try await Task.detached(priority: .userInitiated) {
                        try Address.enterprise(networkId: networkId, paymentCredential: credential)
                    }.value
                    return (index, addr)
                }
            }
            var results = Array<Address?>(repeating: nil, count: credentials.count)
            for try await (index, address) in group {
                results[index] = address
            }
            return results.compactMap { $0 }
        }
    }
    
    /// Creates multiple reward addresses asynchronously in parallel (5.6x speedup for 100+ addresses).
    /// - Parameters:
    ///   - networkId: 0 for Testnet, 1 for Mainnet.
    ///   - credentials: Array of stake credentials.
    /// - Returns: Array of reward addresses in the same order as credentials.
    public static func reward(
        networkId: UInt8,
        credentials: [Credential]
    ) async throws -> [Address] {
        return try await withThrowingTaskGroup(of: (Int, Address).self) { group in
            for (index, credential) in credentials.enumerated() {
                group.addTask {
                    let addr = try await Task.detached(priority: .userInitiated) {
                        try Address.reward(networkId: networkId, stakeCredential: credential)
                    }.value
                    return (index, addr)
                }
            }
            var tempResults = [Int: Address]()
            for try await (index, address) in group {
                tempResults[index] = address
            }
            return (0..<credentials.count).compactMap { tempResults[$0] }
        }
    }
}
