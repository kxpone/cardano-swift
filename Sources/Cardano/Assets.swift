//
//  Assets.swift
//  Cardano
//
//  Created by hellc.
//  Copyright © 2020-2026 KXP. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import CCardano

/// Represents a collection of assets (native tokens) within a single policy of the Cardano blockchain.
///
/// ### Example
/// ```swift
/// let assets = try Assets()
/// try assets.add(assetName: "KXP", amount: 1000)
/// ```
public class Assets {
    /// Opaque pointer to the underlying Rust assets object.
    internal let pointer: RPtr
    
    /// Initializes an empty assets collection.
    /// - Throws: CardanoError if initialization fails.
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_assets_new($0, $1) }
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }

    /// Returns the number of assets in the collection.
    public func len() throws -> Int {
        Int(try CSL.call { csl_bridge_assets_len(pointer, $0, $1) })
    }
    
    /// Adds a token to the collection.
    /// - Parameters:
    ///   - assetName: The name of the asset (string).
    ///   - amount: The quantity of the asset to add.
    /// - Throws: CardanoError if addition fails.
    public func add(assetName: String, amount: UInt64) throws {
        let nameData = Data(assetName.utf8)
        let namePtr = try nameData.withUnsafeBytes { ptr in
            try CSL.callRPtr { csl_bridge_asset_name_new(ptr.bindMemory(to: UInt8.self).baseAddress!, uintptr_t(nameData.count), $0, $1) }
        }
        let amountPtr = try CSL.callRPtr { csl_bridge_big_num_from_str(String(amount), $0, $1) }
        _ = try CSL.callRPtr { csl_bridge_assets_insert(pointer, namePtr, amountPtr, $0, $1) }
    }
}

/// Represents multiple asset collections, grouped by their respective policy IDs.
///
/// ### Example
/// ```swift
/// let multiAsset = try MultiAsset()
/// let assets = try Assets()
/// try assets.add(assetName: "KXP", amount: 1000)
/// try multiAsset.insert(policyId: "6b8d3c96...", assets: assets)
/// ```
public class MultiAsset {
    /// Opaque pointer to the underlying Rust MultiAsset object.
    internal let pointer: RPtr
    
    /// Initializes an empty multi-asset container.
    /// - Throws: CardanoError if initialization fails.
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_multi_asset_new($0, $1) }
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }

    /// Returns the number of policies in the multi-asset collection.
    public func len() throws -> Int {
        Int(try CSL.call { csl_bridge_multi_asset_len(pointer, $0, $1) })
    }
    
    /// Inserts a set of assets for a given policy ID.
    /// - Parameters:
    ///   - policyId: The hexadecimal string of the policy ID (Script Hash).
    ///   - assets: The `Assets` collection to associate with this policy.
    /// - Throws: CardanoError if insertion fails.
    public func insert(policyId: String, assets: Assets) throws {
        let policyPtr = try CSL.callRPtr { csl_bridge_script_hash_from_hex(policyId, $0, $1) }
        _ = try CSL.callRPtr { csl_bridge_multi_asset_insert(pointer, policyPtr, assets.pointer, $0, $1) }
        var p = policyPtr
        csl_bridge_rptr_free(&p)
    }
}

extension Data {
    /// Internal helper to initialize Data from a hexadecimal string.
    init(hex: String) {
        self.init()
        var hex = hex
        if hex.hasPrefix("0x") { hex = String(hex.dropFirst(2)) }
        var tempHex = hex
        while tempHex.count > 0 {
            let sub = String(tempHex.prefix(2))
            tempHex = String(tempHex.dropFirst(2))
            if let b = UInt8(sub, radix: 16) {
                self.append(b)
            }
        }
    }
}
