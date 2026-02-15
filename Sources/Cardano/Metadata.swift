//
//  Metadata.swift
//  Cardano
//
//  Created by hellc.
//  Copyright © 2020-2026 KXP. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import CCardano

/// Represents the general transaction metadata.
public class Metadata {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_general_transaction_metadata_new($0, $1) }
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
    
    public func count() throws -> Int64 {
        return try CSL.call { csl_bridge_general_transaction_metadata_len(pointer, $0, $1) }
    }
    
    public func insert(label: BigNum, value: Metadatum) throws {
        _ = try CSL.callRPtr { csl_bridge_general_transaction_metadata_insert(pointer, label.pointer, value.pointer, $0, $1) }
    }
    
    public func get(label: BigNum) throws -> Metadatum? {
        let valPtr = try CSL.callRPtr { csl_bridge_general_transaction_metadata_get(pointer, label.pointer, $0, $1) }
        return Metadatum(pointer: valPtr)
    }
    
    public func toHex() throws -> String {
        return try CSL.getString { csl_bridge_general_transaction_metadata_to_hex(pointer, $0, $1) }
    }
}

/// Represents the auxiliary data which can include metadata and scripts.
public class AuxiliaryData {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_auxiliary_data_new($0, $1) }
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
    
    public func setMetadata(_ metadata: Metadata) throws {
        try CSL.voidCall { csl_bridge_auxiliary_data_set_metadata(pointer, metadata.pointer, $0) }
    }
    
    public func toHex() throws -> String {
        return try CSL.getString { csl_bridge_auxiliary_data_to_hex(pointer, $0, $1) }
    }
}

/// A wrapper for a single piece of metadata (TransactionMetadatum).
public class Metadatum {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
    
    public static func newText(_ text: String) throws -> Metadatum {
        return try Metadatum(pointer: CSL.callRPtr { csl_bridge_transaction_metadatum_new_text(text, $0, $1) })
    }
    
    public static func newInt(_ value: BigNum) throws -> Metadatum {
        let intPtr = try CSL.callRPtr { csl_bridge_int_new(value.pointer, $0, $1) }
        return try Metadatum(pointer: CSL.callRPtr { csl_bridge_transaction_metadatum_new_int(intPtr, $0, $1) })
    }
    
    public static func newMap(_ map: MetadataMap) throws -> Metadatum {
        return try Metadatum(pointer: CSL.callRPtr { csl_bridge_transaction_metadatum_new_map(map.pointer, $0, $1) })
    }
    
    public func asText() throws -> String {
        return try CSL.getString { csl_bridge_transaction_metadatum_as_text(pointer, $0, $1) }
    }
}

/// A map structure within the metadata.
public class MetadataMap {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_metadata_map_new($0, $1) }
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
    
    public func insert(key: String, value: Metadatum) throws {
        _ = try CSL.callRPtr { csl_bridge_metadata_map_insert_str(pointer, key, value.pointer, $0, $1) }
    }
    
    public func get(key: String) throws -> Metadatum? {
        let valPtr = try CSL.callRPtr { csl_bridge_metadata_map_get_str(pointer, key, $0, $1) }
        return Metadatum(pointer: valPtr)
    }
    
    public func count() throws -> Int64 {
        return try CSL.call { csl_bridge_metadata_map_len(pointer, $0, $1) }
    }
}
