//
//  Keys.swift
//  Cardano
//
//  Created by hellc.
//  Copyright © 2020-2026 KXP. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import CCardano

/// Managed wrapper for a BIP32 public key.
public class Bip32PublicKey {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
    
    /// Converts the BIP32 public key to a raw Ed25519 public key.
    public func toRawKey() throws -> PublicKey {
        let ptr = try CSL.callRPtr { csl_bridge_bip32_public_key_to_raw_key(pointer, $0, $1) }
        return PublicKey(pointer: ptr)
    }
}

/// Managed wrapper for a BIP32 private key.
public class Bip32PrivateKey {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
    
    /// Converts the BIP32 private key to a raw Ed25519 private key.
    /// - Returns: A `PrivateKey` wrapper.
    public func toRawKey() throws -> PrivateKey {
        let ptr = try CSL.callRPtr { csl_bridge_bip32_private_key_to_raw_key(pointer, $0, $1) }
        return PrivateKey(pointer: ptr)
    }
    
    /// Returns the BIP32 public key corresponding to this private key.
    /// - Returns: A `Bip32PublicKey` wrapper.
    public func toPublic() throws -> Bip32PublicKey {
        let ptr = try CSL.callRPtr { csl_bridge_bip32_private_key_to_public(pointer, $0, $1) }
        return Bip32PublicKey(pointer: ptr)
    }
}

/// Managed wrapper for a raw Ed25519 public key.
public class PublicKey {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
    
    /// Hashes the public key to its standard Cardano hash (28 bytes).
    /// - Returns: A `KeyHash` wrapper.
    public func hash() throws -> KeyHash {
        let ptr = try CSL.callRPtr { csl_bridge_public_key_hash(pointer, $0, $1) }
        return KeyHash(pointer: ptr)
    }
}

/// Managed wrapper for a raw Ed25519 private key.
public class PrivateKey {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
    
    /// Returns the public key corresponding to this private key.
    /// - Returns: A `PublicKey` wrapper.
    public func toPublic() throws -> PublicKey {
        let ptr = try CSL.callRPtr { csl_bridge_private_key_to_public(pointer, $0, $1) }
        return PublicKey(pointer: ptr)
    }
}

/// Managed wrapper for a public key hash.
public class KeyHash {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
    
    /// Converts the key hash into a payment or stake credential.
    public func toCredential() throws -> Credential {
        let ptr = try CSL.callRPtr { csl_bridge_credential_from_keyhash(pointer, $0, $1) }
        return Credential(pointer: ptr)
    }
}

/// Managed wrapper for a script hash.
public class ScriptHash {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
    
    /// Converts the script hash into a payment or stake credential.
    public func toCredential() throws -> Credential {
        let ptr = try CSL.callRPtr { csl_bridge_credential_from_scripthash(pointer, $0, $1) }
        return Credential(pointer: ptr)
    }
    
    public func toHex() throws -> String {
        return try CSL.getString { csl_bridge_script_hash_to_hex(pointer, $0, $1) }
    }
}

/// Represents a Cardano credential (can be based on a key hash or script hash).
public class Credential {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
}
