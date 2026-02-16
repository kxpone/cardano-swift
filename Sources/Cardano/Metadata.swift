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
///
/// ### Example
/// ```swift
/// let metadata = try Metadata()
/// try metadata.insert(label: 674, value: Metadata.fromJSON(json: "{\"msg\": [\"Hello\"]}"))
/// ```
public class Metadata {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    /// Initializes an empty Metadata collection.
    /// - Throws: CardanoError if initialization fails.
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_general_transaction_metadata_new($0, $1) }
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
    
    /// Returns the number of metadata entries.
    /// - Returns: The count of metadata entries.
    /// - Throws: CardanoError if counting fails.
    public func count() throws -> Int64 {
        return try CSL.call { csl_bridge_general_transaction_metadata_len(pointer, $0, $1) }
    }
    
    /// Inserts or updates a metadata entry.
    /// - Parameters:
    ///   - label: The metadata label (as BigNum).
    ///   - value: The Metadatum value to store.
    /// - Throws: CardanoError if insertion fails.
    public func insert(label: BigNum, value: Metadatum) throws {
        _ = try CSL.callRPtr { csl_bridge_general_transaction_metadata_insert(pointer, label.pointer, value.pointer, $0, $1) }
    }
    
    /// Retrieves a metadata entry by label.
    /// - Parameter label: The metadata label (as BigNum).
    /// - Returns: The Metadatum value, or nil if not found.
    /// - Throws: CardanoError if retrieval fails.
    public func get(label: BigNum) throws -> Metadatum? {
        let valPtr = try CSL.callRPtr { csl_bridge_general_transaction_metadata_get(pointer, label.pointer, $0, $1) }
        return Metadatum(pointer: valPtr)
    }
    
    /// Converts the metadata to a hexadecimal string (CBOR).
    /// - Returns: The hex-encoded metadata.
    /// - Throws: CardanoError if conversion fails.
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
    
    /// Initializes an empty AuxiliaryData container.
    /// - Throws: CardanoError if initialization fails.
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_auxiliary_data_new($0, $1) }
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
    
    /// Attaches metadata to the auxiliary data.
    /// - Parameter metadata: The Metadata object to set.
    /// - Throws: CardanoError if setting fails.
    public func setMetadata(_ metadata: Metadata) throws {
        try CSL.voidCall { csl_bridge_auxiliary_data_set_metadata(pointer, metadata.pointer, $0) }
    }
    
    /// Returns the metadata attached to this container, if any.
    public func metadata() throws -> Metadata? {
        let ptr = try CSL.callRPtr { csl_bridge_auxiliary_data_metadata(pointer, $0, $1) }
        guard ptr._0 != nil else { return nil }
        return Metadata(pointer: ptr)
    }

    /// Converts the auxiliary data to a hexadecimal string (CBOR).
    /// - Returns: The hex-encoded auxiliary data.
    /// - Throws: CardanoError if conversion fails.
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
    
    /// Creates a Metadatum from a text string.
    /// - Parameter text: The text value to store in metadata.
    /// - Returns: A new Metadatum containing the text.
    /// - Throws: CardanoError if creation fails.
    public static func newText(_ text: String) throws -> Metadatum {
        return try Metadatum(pointer: CSL.callRPtr { csl_bridge_transaction_metadatum_new_text(text, $0, $1) })
    }
    
    /// Creates a Metadatum from an integer value.
    /// - Parameter value: The BigNum integer value to store in metadata.
    /// - Returns: A new Metadatum containing the integer.
    /// - Throws: CardanoError if creation fails.
    public static func newInt(_ value: BigNum) throws -> Metadatum {
        let intPtr = try CSL.callRPtr { csl_bridge_int_new(value.pointer, $0, $1) }
        return try Metadatum(pointer: CSL.callRPtr { csl_bridge_transaction_metadatum_new_int(intPtr, $0, $1) })
    }
    
    /// Creates a Metadatum from a metadata map.
    /// - Parameter map: The MetadataMap to wrap as a metadatum.
    /// - Returns: A new Metadatum containing the map.
    /// - Throws: CardanoError if creation fails.
    public static func newMap(_ map: MetadataMap) throws -> Metadatum {
        return try Metadatum(pointer: CSL.callRPtr { csl_bridge_transaction_metadatum_new_map(map.pointer, $0, $1) })
    }
    
    /// Extracts a text value from this metadatum.
    /// - Returns: The text value if this metadatum contains text.
    /// - Throws: CardanoError if extraction fails.
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
    
    /// Initializes an empty MetadataMap.
    /// - Throws: CardanoError if initialization fails.
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_metadata_map_new($0, $1) }
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
    
    /// Inserts a string key-value pair into the map.
    /// - Parameters:
    ///   - key: The string key.
    ///   - value: The Metadatum value to store.
    /// - Throws: CardanoError if insertion fails.
    public func insert(key: String, value: Metadatum) throws {
        _ = try CSL.callRPtr { csl_bridge_metadata_map_insert_str(pointer, key, value.pointer, $0, $1) }
    }
    
    /// Retrieves a value by string key.
    /// - Parameter key: The string key to look up.
    /// - Returns: The Metadatum value if found, nil otherwise.
    /// - Throws: CardanoError if retrieval fails.
    public func get(key: String) throws -> Metadatum? {
        let valPtr = try CSL.callRPtr { csl_bridge_metadata_map_get_str(pointer, key, $0, $1) }
        return Metadatum(pointer: valPtr)
    }
    
    /// Returns the number of key-value pairs in the map.
    /// - Returns: The count of entries.
    /// - Throws: CardanoError if counting fails.
    public func count() throws -> Int64 {
        return try CSL.call { csl_bridge_metadata_map_len(pointer, $0, $1) }
    }
}
