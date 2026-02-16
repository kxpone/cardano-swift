//
//  Keychain.swift
//  Cardano
//
//  Created by hellc.
//  Copyright © 2020-2026 KXP. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import CCardano

/// Managed container for BIP32 hierarchical deterministic keys.
/// It provides functionality for deriving child keys and converting between private/public key formats.
public class Keychain {
    /// Opaque pointer to the internal BIP32 private root key.
    private let rootKey: RPtr
    
    /// Initializes a root keychain from a mnemonic and an optional password.
    /// - Parameters:
    ///   - mnemonic: The `Mnemonic` instance to use for entropy.
    ///   - password: An optional BIP39 passphrase (defaults to empty).
    /// - Throws: CardanoError if initialization fails.
    public init(mnemonic: Mnemonic, password: [UInt8] = []) throws {
        let entropy = try mnemonic.toEntropy()
        self.rootKey = try entropy.withUnsafeBytes { entropyPtr in
            try password.withUnsafeBytes { passwordPtr in
                try CSL.callRPtr {
                    csl_bridge_bip32_private_key_from_bip39_entropy(
                        entropyPtr.bindMemory(to: UInt8.self).baseAddress!,
                        uintptr_t(entropy.count),
                        passwordPtr.bindMemory(to: UInt8.self).baseAddress!,
                        uintptr_t(password.count),
                        $0, $1
                    )
                }
            }
        }
    }
    
    deinit {
        var p = rootKey
        csl_bridge_rptr_free(&p)
    }
    
    /// Derives a child keychain using a standard derivation path (e.g., "m/1852'/1815'/0'/0/0").
    /// - Parameter path: The full derivation path as a string.
    /// - Returns: A new `Keychain` instance initialized with the derived private key.
    /// - Throws: CardanoError if derivation fails or path is invalid.
    public func derive(path: String) throws -> Keychain {
        let components = path.split(separator: "/").filter { $0 != "m" }
        var currentKey = rootKey
        
        for component in components {
            let isHardened = component.hasSuffix("'")
            let indexString = isHardened ? component.dropLast() : component
            guard var index = UInt32(indexString) else {
                throw CardanoError.invalidPath
            }
            if isHardened {
                index += 0x80000000
            }
            currentKey = try CSL.callRPtr { csl_bridge_bip32_private_key_derive(currentKey, Int64(index), $0, $1) }
        }
        
        return Keychain(rootKey: currentKey)
    }
    
    /// Internal initializer for creating keychains from existing pointers.
    private init(rootKey: RPtr) {
        self.rootKey = rootKey
    }
    
    /// Returns the BIP32 public key corresponding to this keychain's private key.
    /// - Returns: A `Bip32PublicKey` wrapper.
    /// - Throws: CardanoError if key extraction fails.
    public func publicKey() throws -> Bip32PublicKey {
        let ptr = try CSL.callRPtr { csl_bridge_bip32_private_key_to_public(rootKey, $0, $1) }
        return Bip32PublicKey(pointer: ptr)
    }
    
    /// Returns the raw Ed25519 private key. 
    /// This is used for generating transaction witnesses and signatures.
    /// - Returns: A `PrivateKey` wrapper.
    /// - Throws: CardanoError if key extraction fails.
    public func privateKey() throws -> PrivateKey {
        let ptr = try CSL.callRPtr { csl_bridge_bip32_private_key_to_raw_key(rootKey, $0, $1) }
        return PrivateKey(pointer: ptr)
    }

    // MARK: - Async API Methods

    /// Asynchronously derives a child keychain using a derivation path.
    /// Executes the full derivation chain on a background thread.
    /// Useful when deriving multiple paths or deep derivation chains.
    /// - Parameter path: The full derivation path as a string.
    /// - Returns: A new `Keychain` instance initialized with the derived private key.
    /// - Throws: CardanoError if derivation fails.
    public func derive(path: String) async throws -> Keychain {
        return try await Task.detached(priority: .userInitiated) {
            try self.derive(path: path)
        }.value
    }

    /// Asynchronously derives multiple keychains in parallel.
    /// Significantly faster than sequential derivation for multiple paths.
    /// - Parameter paths: An array of derivation path strings.
    /// - Returns: An array of `Keychain` objects in the same order as input paths.
    /// - Throws: CardanoError if derivation fails.
    public func derive(paths: [String]) async throws -> [Keychain] {
        let keychains = try await withThrowingTaskGroup(of: (Int, Keychain).self, returning: [Keychain].self) { group in
            for (idx, path) in paths.enumerated() {
                group.addTask {
                    let keychain = try self.derive(path: path)
                    return (idx, keychain)
                }
            }
            
            var results = [(Int, Keychain)]()
            for try await (idx, keychain) in group {
                results.append((idx, keychain))
            }
            
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
        return keychains
    }

    /// Asynchronously gets the BIP32 public key.
    /// - Returns: A `Bip32PublicKey` wrapper.
    /// - Throws: CardanoError if key extraction fails.
    public func publicKey() async throws -> Bip32PublicKey {
        return try await Task.detached(priority: .userInitiated) {
            try self.publicKey()
        }.value
    }

    /// Asynchronously gets the raw Ed25519 private key.
    /// - Returns: A `PrivateKey` wrapper.
    /// - Throws: CardanoError if key extraction fails.
    public func privateKey() async throws -> PrivateKey {
        return try await Task.detached(priority: .userInitiated) {
            try self.privateKey()
        }.value
    }
}
