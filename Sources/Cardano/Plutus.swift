//
//  Plutus.swift
//  Cardano
//
//  Created by hellc.
//  Copyright © 2020-2026 KXP. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import CCardano

/// Represents the Plutus script versions.
public enum PlutusScriptVersion {
    case v1
    case v2
    case v3
}

/// Represents the kind of Plutus data.
public enum PlutusDataKind: Int32 {
    case constrPlutusData = 0
    case map = 1
    case list = 2
    case integer = 3
    case bytes = 4
}

/// A Plutus smart contract script.
public class PlutusScript {
    internal let pointer: RPtr
    public let version: PlutusScriptVersion

    internal init(pointer: RPtr, version: PlutusScriptVersion) {
        self.pointer = pointer
        self.version = version
    }

    /// Initializes a PlutusScript from raw bytes.
    /// - Parameters:
    ///   - bytes: The raw script bytes (CBOR encoded).
    ///   - version: The Plutus version (V1, V2, or V3).
    /// - Throws: CardanoError if the bytes are invalid.
    public init(bytes: Data, version: PlutusScriptVersion) throws {
        self.version = version
        self.pointer = try bytes.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> RPtr in
            let bytesPtr = ptr.bindMemory(to: UInt8.self).baseAddress!
            return try CSL.callRPtr { result, error in
                switch version {
                case .v1:
                    return csl_bridge_plutus_script_new(bytesPtr, uintptr_t(bytes.count), result, error)
                case .v2:
                    return csl_bridge_plutus_script_new_v2(bytesPtr, uintptr_t(bytes.count), result, error)
                case .v3:
                    return csl_bridge_plutus_script_new_v3(bytesPtr, uintptr_t(bytes.count), result, error)
                }
            }
        }
    }

    /// Computes the hash of the Plutus script.
    /// - Returns: The script hash (ScriptHash).
    /// - Throws: CardanoError if hashing fails.
    public func hash() throws -> ScriptHash {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_script_hash(pointer, $0, $1) }
        return ScriptHash(pointer: ptr)
    }

    /// Serializes the script to raw bytes (CBOR).
    /// - Returns: The script data as bytes.
    /// - Throws: CardanoError if serialization fails.
    public func toBytes() throws -> Data {
        return try CSL.getData { csl_bridge_plutus_script_to_bytes(pointer, $0, $1) }
    }

    /// Retrieves the language version (PlutusV1, V2, or V3) of the script.
    /// - Returns: The Language object for this script.
    /// - Throws: CardanoError if language lookup fails.
    public func languageVersion() throws -> Language {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_script_language_version(pointer, $0, $1) }
        return Language(pointer: ptr)
    }

    /// Asynchronously hashes multiple Plutus scripts in parallel.
    /// - Parameter scripts: Array of PlutusScript objects to hash.
    /// - Returns: Array of ScriptHash objects maintaining input order.
    public static func hash(scripts: [PlutusScript]) async throws -> [ScriptHash] {
        return try await withThrowingTaskGroup(of: (Int, ScriptHash).self) { group in
            for (index, script) in scripts.enumerated() {
                group.addTask {
                    let hash = try script.hash()
                    return (index, hash)
                }
            }
            var tempResults = [Int: ScriptHash]()
            for try await (index, hash) in group {
                tempResults[index] = hash
            }
            return (0..<scripts.count).compactMap { tempResults[$0] }
        }
    }

    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
}

/// A collection of Plutus scripts.
public class PlutusScripts {
    internal let pointer: RPtr

    /// Initializes an empty PlutusScripts collection.
    /// - Returns: A new empty PlutusScripts collection.
    /// - Throws: CardanoError if initialization fails.
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_plutus_scripts_new($0, $1) }
    }

    /// Adds a Plutus script to the collection.
    /// - Parameter script: The PlutusScript to add.
    /// - Throws: CardanoError if addition fails.
    public func add(script: PlutusScript) throws {
        try CSL.voidCall { csl_bridge_plutus_scripts_add(pointer, script.pointer, $0) }
    }

deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// Represents a fraction between 0 and 1.
public class UnitInterval {
    internal let pointer: RPtr
    
    /// Initializes a UnitInterval with numerator and denominator.
    /// - Parameter numerator: The numerator value.
    /// - Parameter denominator: The denominator value.
    /// - Throws: CardanoError if initialization fails or if values are invalid.
    public init(numerator: UInt64, denominator: UInt64) throws {
        let n = try BigNum(string: String(numerator))
        let d = try BigNum(string: String(denominator))
        self.pointer = try CSL.callRPtr { csl_bridge_unit_interval_new(n.pointer, d.pointer, $0, $1) }
    }
    
deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// Prices for execution units.
public class ExUnitPrices {
    internal let pointer: RPtr
    private let memPrice: UnitInterval
    private let stepPrice: UnitInterval
    
    /// Initializes ExUnitPrices with memory and CPU step prices.
    /// - Parameter memPrice: The price per unit of memory (as UnitInterval).
    /// - Parameter stepPrice: The price per unit of CPU step (as UnitInterval).
    /// - Throws: CardanoError if initialization fails.
    public init(memPrice: UnitInterval, stepPrice: UnitInterval) throws {
        self.memPrice = memPrice
        self.stepPrice = stepPrice
        self.pointer = try CSL.callRPtr { csl_bridge_ex_unit_prices_new(memPrice.pointer, stepPrice.pointer, $0, $1) }
    }
    
deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// Represents data used in Plutus scripts (Datums, Redeemers).
public class PlutusData {
    internal let pointer: RPtr

    internal init(pointer: RPtr) {
        self.pointer = pointer
    }

    /// Parses PlutusData from CBOR-encoded bytes.
    /// - Parameter bytes: The CBOR-encoded data to parse.
    /// - Returns: A PlutusData object.
    /// - Throws: CardanoError if parsing fails.
    public static func fromBytes(bytes: Data) throws -> PlutusData {
        let ptr = try bytes.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> RPtr in
            let bytesPtr = ptr.bindMemory(to: UInt8.self).baseAddress!
            return try CSL.callRPtr { csl_bridge_plutus_data_from_bytes(bytesPtr, uintptr_t(bytes.count), $0, $1) }
        }
        return PlutusData(pointer: ptr)
    }
    
    /// Parses PlutusData from a JSON representation.
    /// - Parameter json: The JSON string representing Plutus data.
    /// - Returns: A PlutusData object.
    /// - Throws: CardanoError if JSON parsing fails.
    public static func fromJSON(json: String) throws -> PlutusData {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_from_json(json, 1, $0, $1) } // 1 for DetailedComplexJson
        return PlutusData(pointer: ptr)
    }

    /// Creates a PlutusData integer from a 64-bit signed integer.
    /// - Parameter number: The integer value.
    /// - Returns: A PlutusData object representing the integer.
    /// - Throws: CardanoError if creation fails.
    public static func newInteger(number: Int64) throws -> PlutusData {
        let bigInt = try BigInt(string: String(number))
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_new_integer(bigInt.pointer, $0, $1) }
        return PlutusData(pointer: ptr)
    }

    /// Serializes the PlutusData to CBOR-encoded bytes.
    /// - Returns: The CBOR-encoded data.
    /// - Throws: CardanoError if serialization fails.
    public func toBytes() throws -> Data {
        return try CSL.getData { csl_bridge_plutus_data_to_bytes(pointer, $0, $1) }
    }
    
    /// Determines the type/kind of this PlutusData.
    /// - Returns: The PlutusDataKind (integer, bytes, list, map, etc).
    /// - Throws: CardanoError if kind lookup fails.
    public func kind() throws -> PlutusDataKind {
        let k: Int32 = try CSL.call { csl_bridge_plutus_data_kind(pointer, $0, $1) }
        return PlutusDataKind(rawValue: k) ?? .integer
    }
    
    /// Extracts integer data if this PlutusData is an integer type.
    /// - Returns: A BigInt object if the data is an integer, nil otherwise.
    /// - Throws: CardanoError if extraction fails.
    public func asInteger() throws -> BigInt? {
        guard try kind() == .integer else { return nil }
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_as_integer(pointer, $0, $1) }
        return BigInt(pointer: ptr)
    }
    
    /// Extracts bytes data if this PlutusData is a bytes type.
    /// - Returns: The bytes data if the data is of bytes type, nil otherwise.
    /// - Throws: CardanoError if extraction fails.
    public func asBytes() throws -> Data? {
        guard try kind() == .bytes else { return nil }
        return try CSL.getData { csl_bridge_plutus_data_as_bytes(pointer, $0, $1) }
    }
    
    /// Extracts list data if this PlutusData is a list type.
    /// - Returns: A PlutusList object if the data is a list, nil otherwise.
    /// - Throws: CardanoError if extraction fails.
    public func asList() throws -> PlutusList? {
        guard try kind() == .list else { return nil }
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_as_list(pointer, $0, $1) }
        return PlutusList(pointer: ptr)
    }
    
    /// Extracts map data if this PlutusData is a map type.
    /// - Returns: A PlutusMap object if the data is a map, nil otherwise.
    /// - Throws: CardanoError if extraction fails.
    public func asMap() throws -> PlutusMap? {
        guard try kind() == .map else { return nil }
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_as_map(pointer, $0, $1) }
        return PlutusMap(pointer: ptr)
    }
    
    /// Extracts constructor-based Plutus data if this PlutusData is a constructor type.
    /// - Returns: A ConstrPlutusData object if the data is a constructor, nil otherwise.
    /// - Throws: CardanoError if extraction fails.
    public func asConstrPlutusData() throws -> ConstrPlutusData? {
        guard try kind() == .constrPlutusData else { return nil }
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_as_constr_plutus_data(pointer, $0, $1) }
        return ConstrPlutusData(pointer: ptr)
    }

    /// Creates PlutusData from raw bytes.
    /// - Parameter bytes: The raw byte data.
    /// - Returns: A PlutusData object representing the bytes.
    /// - Throws: CardanoError if creation fails.
    public static func newBytes(bytes: Data) throws -> PlutusData {
        let ptr = try bytes.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> RPtr in
            let bytesPtr = ptr.bindMemory(to: UInt8.self).baseAddress!
            return try CSL.callRPtr { csl_bridge_plutus_data_new_bytes(bytesPtr, uintptr_t(bytes.count), $0, $1) }
        }
        return PlutusData(pointer: ptr)
    }

    /// Creates PlutusData from a PlutusList.
    /// - Parameter list: The PlutusList to wrap.
    /// - Returns: A PlutusData object representing the list.
    /// - Throws: CardanoError if creation fails.
    public static func newList(list: PlutusList) throws -> PlutusData {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_new_list(list.pointer, $0, $1) }
        return PlutusData(pointer: ptr)
    }

    /// Creates PlutusData from a PlutusMap.
    /// - Parameter map: The PlutusMap to wrap.
    /// - Returns: A PlutusData object representing the map.
    /// - Throws: CardanoError if creation fails.
    public static func newMap(map: PlutusMap) throws -> PlutusData {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_new_map(map.pointer, $0, $1) }
        return PlutusData(pointer: ptr)
    }

    /// Creates PlutusData from ConstrPlutusData.
    /// - Parameter constr: The ConstrPlutusData to wrap.
    /// - Returns: A PlutusData object representing the constructor data.
    /// - Throws: CardanoError if creation fails.
    public static func newConstrPlutusData(constr: ConstrPlutusData) throws -> PlutusData {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_new_constr_plutus_data(constr.pointer, $0, $1) }
        return PlutusData(pointer: ptr)
    }
    
    // MARK: - Priority 3: Async Batch Parsing
    
    /// Asynchronously parses multiple PlutusData objects from bytes in parallel
    /// - Parameter items: Array of (label, bytes) tuples to parse
    /// - Returns: Array of parsed PlutusData objects maintaining order
    public static func fromBytes(items: [(label: String, bytes: Data)]) async throws -> [PlutusData] {
        return try await withThrowingTaskGroup(
            of: (Int, PlutusData).self,
            returning: [PlutusData].self
        ) { group in
            for (index, item) in items.enumerated() {
                group.addTask {
                    let plutusData = try PlutusData.fromBytes(bytes: item.bytes)
                    return (index, plutusData)
                }
            }
            
            var tempResults: [Int: PlutusData] = [:]
            for try await (index, plutusData) in group {
                tempResults[index] = plutusData
            }
            
            return (0..<items.count).compactMap { tempResults[$0] }
        }
    }
    
    /// Asynchronously parses multiple PlutusData objects from JSON in parallel
    /// - Parameter items: Array of (label, json) tuples to parse
    /// - Returns: Array of parsed PlutusData objects maintaining order
    public static func fromJSON(items: [(label: String, json: String)]) async throws -> [PlutusData] {
        return try await withThrowingTaskGroup(
            of: (Int, PlutusData).self,
            returning: [PlutusData].self
        ) { group in
            for (index, item) in items.enumerated() {
                group.addTask {
                    let plutusData = try PlutusData.fromJSON(json: item.json)
                    return (index, plutusData)
                }
            }
            
            var tempResults: [Int: PlutusData] = [:]
            for try await (index, plutusData) in group {
                tempResults[index] = plutusData
            }
            
            return (0..<items.count).compactMap { tempResults[$0] }
        }
    }

deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// Represents a constructor and its fields in PlutusData.
/// Represents a constructor-based PlutusData (used in datatype constructors).
public class ConstrPlutusData {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    /// Initializes a ConstrPlutusData with an alternative index and data list.
    /// - Parameter alternative: The constructor alternative index.
    /// - Parameter data: The PlutusList containing constructor arguments.
    /// - Throws: CardanoError if initialization fails.
    public init(alternative: UInt64, data: PlutusList) throws {
        let altBN = try CSL.callRPtr { csl_bridge_big_num_from_str(String(alternative), $0, $1) }
        defer { 
            var p = altBN
            csl_bridge_rptr_free(&p) 
        }
        self.pointer = try CSL.callRPtr { csl_bridge_constr_plutus_data_new(altBN, data.pointer, $0, $1) }
    }
    
    /// Retrieves the alternative index of this constructor.
    /// - Returns: The alternative index as UInt64.
    /// - Throws: CardanoError if retrieval fails.
    public func alternative() throws -> UInt64 {
        let bn = try CSL.callRPtr { csl_bridge_constr_plutus_data_alternative(pointer, $0, $1) }
        let str = try CSL.getString { csl_bridge_big_num_to_str(bn, $0, $1) }
        var p = bn
        csl_bridge_rptr_free(&p)
        return UInt64(str) ?? 0
    }
    
    /// Retrieves the data list of constructor arguments.
    /// - Returns: A PlutusList containing the constructor arguments.
    /// - Throws: CardanoError if retrieval fails.
    public func data() throws -> PlutusList {
        let ptr = try CSL.callRPtr { csl_bridge_constr_plutus_data_data(pointer, $0, $1) }
        return PlutusList(pointer: ptr)
    }
    
deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// A list of PlutusData items.
public class PlutusList {
    internal let pointer: RPtr

    internal init(pointer: RPtr) {
        self.pointer = pointer
    }

    /// Initializes a new empty PlutusList.
    /// - Returns: A new empty PlutusList.
    /// - Throws: CardanoError if initialization fails.
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_plutus_list_new($0, $1) }
    }

    /// Adds a PlutusData item to the list.
    /// - Parameter data: The PlutusData to add.
    /// - Throws: CardanoError if addition fails.
    public func add(data: PlutusData) throws {
        try CSL.voidCall { csl_bridge_plutus_list_add(pointer, data.pointer, $0) }
    }
    
    /// Returns the number of items in the list.
    /// - Returns: The count of PlutusData items.
    /// - Throws: CardanoError if length lookup fails.
    public func len() throws -> UInt64 {
        let length: Int64 = try CSL.call { csl_bridge_plutus_list_len(pointer, $0, $1) }
        return UInt64(length)
    }
    
    /// Retrieves a PlutusData item at the specified index.
    /// - Parameter index: The zero-based index.
    /// - Returns: The PlutusData at the given index.
    /// - Throws: CardanoError if the index is out of bounds or retrieval fails.
    public func get(index: UInt64) throws -> PlutusData {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_list_get(pointer, Int64(index), $0, $1) }
        return PlutusData(pointer: ptr)
    }

deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}
/// A map of PlutusData items.
public class PlutusMap {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }

    /// Initializes a new empty PlutusMap.
    /// - Returns: A new empty PlutusMap.
    /// - Throws: CardanoError if initialization fails.
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_plutus_map_new($0, $1) }
    }

    /// Inserts or updates a key-value pair in the map.
    /// - Parameter key: The PlutusData key.
    /// - Parameter value: The PlutusMapValues containing the values for this key.
    /// - Throws: CardanoError if insertion fails.
    public func insert(key: PlutusData, value: PlutusMapValues) throws {
        var res = try CSL.callRPtr { csl_bridge_plutus_map_insert(pointer, key.pointer, value.pointer, $0, $1) }
        csl_bridge_rptr_free(&res)
    }
    
    /// Retrieves the values associated with a key.
    /// - Parameter key: The PlutusData key to look up.
    /// - Returns: A PlutusMapValues containing the values for this key, or nil if key not found.
    /// - Throws: CardanoError if lookup fails.
    public func get(key: PlutusData) throws -> PlutusMapValues? {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_map_get(pointer, key.pointer, $0, $1) }
        guard ptr._0 != nil else { return nil }
        return PlutusMapValues(pointer: ptr)
    }
    
    /// Returns the number of key-value pairs in the map.
    /// - Returns: The count of entries.
    /// - Throws: CardanoError if length lookup fails.
    public func len() throws -> UInt64 {
        let length: Int64 = try CSL.call { csl_bridge_plutus_map_len(pointer, $0, $1) }
        return UInt64(length)
    }
    
    /// Retrieves all keys in the map.
    /// - Returns: A PlutusList containing all keys.
    /// - Throws: CardanoError if key retrieval fails.
    public func keys() throws -> PlutusList {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_map_keys(pointer, $0, $1) }
        return PlutusList(pointer: ptr)
    }

deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// A collection of values for a PlutusMap key.
public class PlutusMapValues {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    /// Initializes a new empty PlutusMapValues collection.
    /// - Returns: A new empty PlutusMapValues.
    /// - Throws: CardanoError if initialization fails.
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_plutus_map_values_new($0, $1) }
    }
    
    /// Adds a PlutusData value to the collection.
    /// - Parameter data: The PlutusData to add.
    /// - Throws: CardanoError if addition fails.
    public func add(data: PlutusData) throws {
        try CSL.voidCall { csl_bridge_plutus_map_values_add(pointer, data.pointer, $0) }
    }
    
    /// Returns the number of values in the collection.
    /// - Returns: The count of values.
    /// - Throws: CardanoError if length lookup fails.
    public func len() throws -> UInt64 {
        let length: Int64 = try CSL.call { csl_bridge_plutus_map_values_len(pointer, $0, $1) }
        return UInt64(length)
    }
    
    /// Retrieves a value at the specified index.
    /// - Parameter index: The zero-based index.
    /// - Returns: The PlutusData value at the given index.
    /// - Throws: CardanoError if the index is out of bounds or retrieval fails.
    public func get(index: UInt64) throws -> PlutusData {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_map_values_get(pointer, Int64(index), $0, $1) }
        return PlutusData(pointer: ptr)
    }
    
deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// Represents a Plutus language.
public class Language {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    /// Creates a Plutus V1 language specification.
    /// - Returns: A Language object for Plutus V1.
    /// - Throws: CardanoError if creation fails.
    public static func plutusV1() throws -> Language {
        let ptr = try CSL.callRPtr { csl_bridge_language_new_plutus_v1($0, $1) }
        return Language(pointer: ptr)
    }
    
    /// Creates a Plutus V2 language specification.
    /// - Returns: A Language object for Plutus V2.
    /// - Throws: CardanoError if creation fails.
    public static func plutusV2() throws -> Language {
        let ptr = try CSL.callRPtr { csl_bridge_language_new_plutus_v2($0, $1) }
        return Language(pointer: ptr)
    }
    
    /// Creates a Plutus V3 language specification.
    /// - Returns: A Language object for Plutus V3.
    /// - Throws: CardanoError if creation fails.
    public static func plutusV3() throws -> Language {
        let ptr = try CSL.callRPtr { csl_bridge_language_new_plutus_v3($0, $1) }
        return Language(pointer: ptr)
    }
    
    /// Retrieves the numeric kind identifier for the language version.
    /// - Returns: An integer representing the language version (1 for V1, 2 for V2, 3 for V3).
    /// - Throws: CardanoError if kind lookup fails.
    public func kind() throws -> Int32 {
        return try CSL.call { csl_bridge_language_kind(pointer, $0, $1) }
    }

deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// Represents a Plutus cost model.
public class CostModel {
    internal var pointer: RPtr
    
    /// Initializes a new empty CostModel.
    /// - Returns: A new empty CostModel.
    /// - Throws: CardanoError if initialization fails.
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_cost_model_new($0, $1) }
    }
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    /// Sets the cost for a specific operation index.
    /// - Parameter index: The operation index.
    /// - Parameter cost: The cost value for this operation.
    /// - Throws: CardanoError if the set operation fails.
    public func set(index: Int, cost: Int64) throws {
        let costBigInt = try BigInt(string: String(cost))
        let newPointer = try CSL.callRPtr { csl_bridge_cost_model_set(pointer, Int64(index), costBigInt.pointer, $0, $1) }
        // Update pointer to the new one returned by the set operation
        var oldPointer = pointer
        csl_bridge_rptr_free(&oldPointer)
        self.pointer = newPointer
    }

deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// A collection of cost models for different languages.
public class CostModels {
    internal let pointer: RPtr
    private var languages: [Language] = []
    private var models: [CostModel] = []
    
    /// Initializes a new empty CostModels collection.
    /// - Returns: A new empty CostModels collection.
    /// - Throws: CardanoError if initialization fails.
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_costmdls_new($0, $1) }
    }
    
    /// Inserts a cost model for a specific language.
    /// - Parameter language: The Language for which to set the cost model.
    /// - Parameter costModel: The CostModel containing operation costs.
    /// - Throws: CardanoError if insertion fails.
    public func insert(language: Language, costModel: CostModel) throws {
        languages.append(language)
        models.append(costModel)
        var res = try CSL.callRPtr { csl_bridge_costmdls_insert(pointer, language.pointer, costModel.pointer, $0, $1) }
        csl_bridge_rptr_free(&res)
    }

deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// Execution units for Plutus scripts.
public class ExUnits {
    internal let pointer: RPtr

    /// Initializes ExUnits with memory and CPU step requirements.
    /// - Parameter mem: The memory units required.
    /// - Parameter step: The CPU step units required.
    /// - Throws: CardanoError if initialization fails.
    public init(mem: UInt64, step: UInt64) throws {
        let memBN = try CSL.callRPtr { csl_bridge_big_num_from_str(String(mem), $0, $1) }
        let stepBN = try CSL.callRPtr { csl_bridge_big_num_from_str(String(step), $0, $1) }
        self.pointer = try CSL.callRPtr { csl_bridge_ex_units_new(memBN, stepBN, $0, $1) }
    }

deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// A redeemer for a Plutus script.
public class Redeemer {
    internal let pointer: RPtr
    private let data: PlutusData
    private let exUnits: ExUnits

    /// Redeemer tag indicating what type of operation the redeemer applies to.
    public enum Tag: UInt32 {
        case spend = 0      // For UTXO spending
        case mint = 1       // For minting
        case certificate = 2 // For certificates
        case reward = 3     // For rewards
        case voting = 4     // For voting
        case proposing = 5  // For governance proposals
    }

    /// Initializes a Redeemer with tag, index, data, and execution units.
    /// - Parameter tag: The redeemer tag indicating the operation type.
    /// - Parameter index: The index of the input/output being executed.
    /// - Parameter data: The PlutusData argument passed to the script.
    /// - Parameter exUnits: The ExUnits specifying memory and CPU requirements.
    /// - Throws: CardanoError if initialization fails.
    public init(tag: Tag, index: UInt64, data: PlutusData, exUnits: ExUnits) throws {
        self.data = data
        self.exUnits = exUnits
        
        let tagPtr = try CSL.callRPtr { result, error in
            switch tag {
            case .spend: return csl_bridge_redeemer_tag_new_spend(result, error)
            case .mint: return csl_bridge_redeemer_tag_new_mint(result, error)
            case .certificate: return csl_bridge_redeemer_tag_new_cert(result, error)
            case .reward: return csl_bridge_redeemer_tag_new_reward(result, error)
            case .voting: return csl_bridge_redeemer_tag_new_vote(result, error)
            case .proposing: return csl_bridge_redeemer_tag_new_voting_proposal(result, error)
            }
        }
        let indexBN = try CSL.callRPtr { csl_bridge_big_num_from_str(String(index), $0, $1) }
        self.pointer = try CSL.callRPtr { csl_bridge_redeemer_new(tagPtr, indexBN, data.pointer, exUnits.pointer, $0, $1) }
    }

deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// A Plutus witness containing a script, datum, and redeemer.
public class PlutusWitness {
    internal let pointer: RPtr

    /// Initializes a PlutusWitness with script, datum, and redeemer.
    /// - Parameter script: The PlutusScript to execute.
    /// - Parameter datum: The PlutusData datum passed to the script.
    /// - Parameter redeemer: The Redeemer providing the redeemer data.
    /// - Throws: CardanoError if initialization fails.
    public init(script: PlutusScript, datum: PlutusData, redeemer: Redeemer) throws {
        self.pointer = try CSL.callRPtr { csl_bridge_plutus_witness_new(script.pointer, datum.pointer, redeemer.pointer, $0, $1) }
    }

    /// Initializes a PlutusWitness with script and redeemer (no datum).
    /// - Parameter script: The PlutusScript to execute.
    /// - Parameter redeemer: The Redeemer providing the redeemer data.
    /// - Throws: CardanoError if initialization fails.
    public init(script: PlutusScript, redeemer: Redeemer) throws {
        self.pointer = try CSL.callRPtr { csl_bridge_plutus_witness_new_without_datum(script.pointer, redeemer.pointer, $0, $1) }
    }
    
    /// Creates a PlutusWitness with script, datum, and redeemer sourced by reference.
    /// - Parameter script: A PlutusScriptSource (direct or reference).
    /// - Parameter datum: A DatumSource (direct or reference).
    /// - Parameter redeemer: The Redeemer providing the redeemer data.
    /// - Returns: A new PlutusWitness.
    /// - Throws: CardanoError if creation fails.
    public static func newWithRef(script: PlutusScriptSource, datum: DatumSource, redeemer: Redeemer) throws -> PlutusWitness {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_witness_new_with_ref(script.pointer, datum.pointer, redeemer.pointer, $0, $1) }
        return PlutusWitness(pointer: ptr)
    }
    
    /// Creates a PlutusWitness with script and redeemer sourced by reference (no datum).
    /// - Parameter script: A PlutusScriptSource (direct or reference).
    /// - Parameter redeemer: The Redeemer providing the redeemer data.
    /// - Returns: A new PlutusWitness.
    /// - Throws: CardanoError if creation fails.
    public static func newWithRefWithoutDatum(script: PlutusScriptSource, redeemer: Redeemer) throws -> PlutusWitness {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_witness_new_with_ref_without_datum(script.pointer, redeemer.pointer, $0, $1) }
        return PlutusWitness(pointer: ptr)
    }
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }

deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// A collection of redeemers.
public class Redeemers {
    internal let pointer: RPtr

    /// Initializes a new empty Redeemers collection.
    /// - Returns: A new empty Redeemers collection.
    /// - Throws: CardanoError if initialization fails.
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_redeemers_new($0, $1) }
    }

    /// Adds a Redeemer to the collection.
    /// - Parameter redeemer: The Redeemer to add.
    /// - Throws: CardanoError if addition fails.
    public func add(redeemer: Redeemer) throws {
        try CSL.voidCall { csl_bridge_redeemers_add(pointer, redeemer.pointer, $0) }
    }

deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// A collection of Plutus witnesses.
public class PlutusWitnesses {
    internal let pointer: RPtr

    /// Initializes a new empty PlutusWitnesses collection.
    /// - Returns: A new empty PlutusWitnesses collection.
    /// - Throws: CardanoError if initialization fails.
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_plutus_witnesses_new($0, $1) }
    }

    /// Adds a PlutusWitness to the collection.
    /// - Parameter witness: The PlutusWitness to add.
    /// - Throws: CardanoError if addition fails.
    public func add(witness: PlutusWitness) throws {
        try CSL.voidCall { csl_bridge_plutus_witnesses_add(pointer, witness.pointer, $0) }
    }

deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// Represents a source of a Plutus datum (direct or reference).
public class DatumSource {
    internal let pointer: RPtr
    
    /// Initializes a DatumSource with a direct PlutusData datum.
    /// - Parameter datum: The PlutusData to wrap as a datum source.
    /// - Throws: CardanoError if initialization fails.
    public init(datum: PlutusData) throws {
        self.pointer = try CSL.callRPtr { csl_bridge_datum_source_new(datum.pointer, $0, $1) }
    }
    
    /// Creates a DatumSource referencing a datum from a transaction input.
    /// - Parameter input: The TransactionInput whose associated datum should be referenced.
    /// - Returns: A new DatumSource using datum reference.
    /// - Throws: CardanoError if creation fails.
    public static func newRefInput(input: TransactionInput) throws -> DatumSource {
        let ptr = try CSL.callRPtr { csl_bridge_datum_source_new_ref_input(input.pointer, $0, $1) }
        return DatumSource(pointer: ptr)
    }
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
}

/// A wrapper for a Plutus script source (direct or reference).
public class PlutusScriptSource {
    internal let pointer: RPtr
    
    /// Initializes a PlutusScriptSource with a direct PlutusScript.
    /// - Parameter script: The PlutusScript to wrap as a script source.
    /// - Throws: CardanoError if initialization fails.
    public init(script: PlutusScript) throws {
        self.pointer = try CSL.callRPtr { csl_bridge_plutus_script_source_new(script.pointer, $0, $1) }
    }
    
    /// Creates a PlutusScriptSource referencing a script from the transaction inputs.
    /// - Parameter scriptHash: The ScriptHash to identify the referenced script.
    /// - Parameter input: The TransactionInput containing the script reference.
    /// - Parameter language: The Language version of the script.
    /// - Parameter scriptSize: The size of the script in bytes (for cost calculation).
    /// - Returns: A new PlutusScriptSource using script reference.
    /// - Throws: CardanoError if creation fails.
    public static func newRefInput(scriptHash: ScriptHash, input: TransactionInput, language: Language, scriptSize: Int64) throws -> PlutusScriptSource {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_script_source_new_ref_input(scriptHash.pointer, input.pointer, language.pointer, scriptSize, $0, $1) }
        return PlutusScriptSource(pointer: ptr)
    }
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// A wrapper for a native script source (direct or reference).
public class NativeScriptSource {
    internal let pointer: RPtr
    
    /// Initializes a NativeScriptSource from raw script bytes.
    /// - Parameter bytes: The CBOR-encoded native script bytes.
    /// - Throws: CardanoError if bytes parsing fails.
    public init(bytes: Data) throws {
        let scriptPtr = try bytes.withUnsafeBytes { ptr in
            try CSL.callRPtr { csl_bridge_native_script_from_bytes(ptr.bindMemory(to: UInt8.self).baseAddress!, uintptr_t(bytes.count), $0, $1) }
        }
        self.pointer = try CSL.callRPtr { csl_bridge_native_script_source_new(scriptPtr, $0, $1) }
        var p = scriptPtr
        csl_bridge_rptr_free(&p)
    }
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
}

/// A Plutus witness for minting assets.
public class MintWitness {
    internal let pointer: RPtr
    
    public static func newPlutusScript(script: PlutusScriptSource, redeemer: Redeemer) throws -> MintWitness {
        let ptr = try CSL.callRPtr { csl_bridge_mint_witness_new_plutus_script(script.pointer, redeemer.pointer, $0, $1) }
        return MintWitness(pointer: ptr)
    }
    
    public static func newNativeScript(script: NativeScriptSource) throws -> MintWitness {
        let ptr = try CSL.callRPtr { csl_bridge_mint_witness_new_native_script(script.pointer, $0, $1) }
        return MintWitness(pointer: ptr)
    }
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// Represents an asset name in Cardano.
public class AssetName {
    internal let pointer: RPtr
    
    public init(name: Data) throws {
        self.pointer = try name.withUnsafeBytes { ptr in
            try CSL.callRPtr { csl_bridge_asset_name_new(ptr.bindMemory(to: UInt8.self).baseAddress!, uintptr_t(name.count), $0, $1) }
        }
    }
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    public func toBytes() throws -> Data {
        return try CSL.getData { csl_bridge_asset_name_to_bytes(pointer, $0, $1) }
    }
    
deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}
