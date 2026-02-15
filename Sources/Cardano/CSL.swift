//
//  CSL.swift
//  Cardano
//
//  Created by hellc.
//  Copyright © 2020-2026 KXP. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import CCardano

/// Errors thrown by the Cardano SDK, often wrapping internal results from the Rust core.
public enum CardanoError: Error, LocalizedError {
    /// An error returned directly from the Cardano Serialization Library (Rust).
    case cslError(String)
    /// Indicates that the provided derivation path is malformed.
    case invalidPath
    /// Key derivation failed in the underlying crypto layer.
    case derivationFailed
    /// Failed to construct an address from the provided credentials.
    case addressCreationFailed
    
    public var errorDescription: String? {
        switch self {
        case .cslError(let message): return message
        case .invalidPath: return "Invalid derivation path"
        case .derivationFailed: return "Key derivation failed"
        case .addressCreationFailed: return "Failed to create address"
        }
    }
}

/// Internal helper to manage the bridge between Swift and the native C-interface of the Rust Cardano library.
/// This class ensures the Rust runtime is initialized and provides safe wrappers for calling various types of C functions.
internal class CSL {
    /// Ensures that the underlying Rust bridge is initialized exactly once.
    private static let initialized: Void = {
        init_csl_mobile_bridge()
        return ()
    }()

    /// Generic wrapper for C functions that return a success/failure boolean and use pointers for output.
    /// - Parameter body: A closure calling the specific CSL bridge function.
    /// - Returns: The value of type `T` returned by the Rust core.
    static func call<T>(_ body: (UnsafeMutablePointer<T>, UnsafeMutablePointer<CharPtr?>) -> Bool) throws -> T {
        _ = initialized
        let result = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { result.deallocate() }
        var error: CharPtr?
        if !body(result, &error) {
            if let err = error {
                let message = String(cString: err)
                var mutableErr: CharPtr? = err
                csl_bridge_charptr_free(&mutableErr)
                throw CardanoError.cslError(message)
            }
        }
        return result.pointee
    }
    
    /// Wrapper for C functions that return a `RPtr` (Opaque Pointer to a Rust object).
    /// - Parameter body: A closure calling the specific bridge function.
    /// - Returns: A `RPtr` representing the underlying Rust object.
    static func callRPtr(_ body: (UnsafeMutablePointer<RPtr>, UnsafeMutablePointer<CharPtr?>) -> Bool) throws -> RPtr {
        _ = initialized
        let result = UnsafeMutablePointer<RPtr>.allocate(capacity: 1)
        result.pointee = RPtr(_0: nil) // Default to nil for None results
        defer { result.deallocate() }
        var error: CharPtr?
        if !body(result, &error) {
            if let err = error {
                let message = String(cString: err)
                var mutableErr: CharPtr? = err
                csl_bridge_charptr_free(&mutableErr)
                throw CardanoError.cslError(message)
            }
        }
        return result.pointee
    }
    
    /// Wrapper for functions that return a C-style string.
    /// Manages memory by freeing the returned string using `csl_bridge_charptr_free`.
    static func getString(_ body: (UnsafeMutablePointer<CharPtr?>, UnsafeMutablePointer<CharPtr?>) -> Bool) throws -> String {
        var result: CharPtr?
        var error: CharPtr?
        if !body(&result, &error) {
            let message = error != nil ? String(cString: error!) : "Unknown CSL error"
            if error != nil {
                csl_bridge_charptr_free(&error)
            }
            throw CardanoError.cslError(message)
        }
        let str = String(cString: result!)
        csl_bridge_charptr_free(&result)
        return str
    }
    
    /// Wrapper for functions that return a `DataPtr` (pointer + length).
    /// Converts the raw bytes into a Swift `Data` object and frees the Rust-allocated memory.
    static func getData(_ body: (UnsafeMutablePointer<DataPtr>, UnsafeMutablePointer<CharPtr?>) -> Bool) throws -> Data {
        var result = DataPtr()
        var error: CharPtr?
        if !body(&result, &error) {
            let message = error != nil ? String(cString: error!) : "Unknown CSL error"
            if error != nil {
                csl_bridge_charptr_free(&error)
            }
            throw CardanoError.cslError(message)
        }
        let data = Data(bytes: result.ptr, count: Int(result.len))
        csl_bridge_dataptr_free(&result)
        return data
    }
    
    /// Wrapper for C functions that do not return a value but might return an error.
    @discardableResult
    static func voidCall(_ body: (UnsafeMutablePointer<CharPtr?>) -> Bool) throws -> Bool {
        _ = initialized
        var error: CharPtr?
        if !body(&error) {
            let message = error != nil ? String(cString: error!) : "Unknown CSL error"
            if error != nil {
                csl_bridge_charptr_free(&error)
            }
            throw CardanoError.cslError(message)
        }
        return true
    }
}
