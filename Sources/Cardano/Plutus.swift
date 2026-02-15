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

    public func hash() throws -> ScriptHash {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_script_hash(pointer, $0, $1) }
        return ScriptHash(pointer: ptr)
    }

    public func toBytes() throws -> Data {
        return try CSL.getData { csl_bridge_plutus_script_to_bytes(pointer, $0, $1) }
    }

    public func languageVersion() throws -> Language {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_script_language_version(pointer, $0, $1) }
        return Language(pointer: ptr)
    }

deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// Collection of Plutus scripts.
public class PlutusScripts {
    internal let pointer: RPtr

    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_plutus_scripts_new($0, $1) }
    }

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

    public static func fromBytes(bytes: Data) throws -> PlutusData {
        let ptr = try bytes.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> RPtr in
            let bytesPtr = ptr.bindMemory(to: UInt8.self).baseAddress!
            return try CSL.callRPtr { csl_bridge_plutus_data_from_bytes(bytesPtr, uintptr_t(bytes.count), $0, $1) }
        }
        return PlutusData(pointer: ptr)
    }
    
    public static func fromJSON(json: String) throws -> PlutusData {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_from_json(json, 1, $0, $1) } // 1 for DetailedComplexJson
        return PlutusData(pointer: ptr)
    }

    public static func newInteger(number: Int64) throws -> PlutusData {
        let bigInt = try BigInt(string: String(number))
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_new_integer(bigInt.pointer, $0, $1) }
        return PlutusData(pointer: ptr)
    }

    public func toBytes() throws -> Data {
        return try CSL.getData { csl_bridge_plutus_data_to_bytes(pointer, $0, $1) }
    }
    
    public func kind() throws -> PlutusDataKind {
        let k: Int32 = try CSL.call { csl_bridge_plutus_data_kind(pointer, $0, $1) }
        return PlutusDataKind(rawValue: k) ?? .integer
    }
    
    public func asInteger() throws -> BigInt? {
        guard try kind() == .integer else { return nil }
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_as_integer(pointer, $0, $1) }
        return BigInt(pointer: ptr)
    }
    
    public func asBytes() throws -> Data? {
        guard try kind() == .bytes else { return nil }
        return try CSL.getData { csl_bridge_plutus_data_as_bytes(pointer, $0, $1) }
    }
    
    public func asList() throws -> PlutusList? {
        guard try kind() == .list else { return nil }
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_as_list(pointer, $0, $1) }
        return PlutusList(pointer: ptr)
    }
    
    public func asMap() throws -> PlutusMap? {
        guard try kind() == .map else { return nil }
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_as_map(pointer, $0, $1) }
        return PlutusMap(pointer: ptr)
    }
    
    public func asConstrPlutusData() throws -> ConstrPlutusData? {
        guard try kind() == .constrPlutusData else { return nil }
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_as_constr_plutus_data(pointer, $0, $1) }
        return ConstrPlutusData(pointer: ptr)
    }

    public static func newBytes(bytes: Data) throws -> PlutusData {
        let ptr = try bytes.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> RPtr in
            let bytesPtr = ptr.bindMemory(to: UInt8.self).baseAddress!
            return try CSL.callRPtr { csl_bridge_plutus_data_new_bytes(bytesPtr, uintptr_t(bytes.count), $0, $1) }
        }
        return PlutusData(pointer: ptr)
    }

    public static func newList(list: PlutusList) throws -> PlutusData {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_new_list(list.pointer, $0, $1) }
        return PlutusData(pointer: ptr)
    }

    public static func newMap(map: PlutusMap) throws -> PlutusData {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_new_map(map.pointer, $0, $1) }
        return PlutusData(pointer: ptr)
    }

    public static func newConstrPlutusData(constr: ConstrPlutusData) throws -> PlutusData {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_data_new_constr_plutus_data(constr.pointer, $0, $1) }
        return PlutusData(pointer: ptr)
    }

deinit {
var p = pointer
csl_bridge_rptr_free(&p)
}
}

/// Represents a constructor and its fields in PlutusData.
public class ConstrPlutusData {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    public init(alternative: UInt64, data: PlutusList) throws {
        let altBN = try CSL.callRPtr { csl_bridge_big_num_from_str(String(alternative), $0, $1) }
        defer { 
            var p = altBN
            csl_bridge_rptr_free(&p) 
        }
        self.pointer = try CSL.callRPtr { csl_bridge_constr_plutus_data_new(altBN, data.pointer, $0, $1) }
    }
    
    public func alternative() throws -> UInt64 {
        let bn = try CSL.callRPtr { csl_bridge_constr_plutus_data_alternative(pointer, $0, $1) }
        let str = try CSL.getString { csl_bridge_big_num_to_str(bn, $0, $1) }
        var p = bn
        csl_bridge_rptr_free(&p)
        return UInt64(str) ?? 0
    }
    
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

    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_plutus_list_new($0, $1) }
    }

    public func add(data: PlutusData) throws {
        try CSL.voidCall { csl_bridge_plutus_list_add(pointer, data.pointer, $0) }
    }
    
    public func len() throws -> UInt64 {
        let length: Int64 = try CSL.call { csl_bridge_plutus_list_len(pointer, $0, $1) }
        return UInt64(length)
    }
    
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

    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_plutus_map_new($0, $1) }
    }

    public func insert(key: PlutusData, value: PlutusMapValues) throws {
        var res = try CSL.callRPtr { csl_bridge_plutus_map_insert(pointer, key.pointer, value.pointer, $0, $1) }
        csl_bridge_rptr_free(&res)
    }
    
    public func get(key: PlutusData) throws -> PlutusMapValues? {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_map_get(pointer, key.pointer, $0, $1) }
        guard ptr._0 != nil else { return nil }
        return PlutusMapValues(pointer: ptr)
    }
    
    public func len() throws -> UInt64 {
        let length: Int64 = try CSL.call { csl_bridge_plutus_map_len(pointer, $0, $1) }
        return UInt64(length)
    }
    
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
    
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_plutus_map_values_new($0, $1) }
    }
    
    public func add(data: PlutusData) throws {
        try CSL.voidCall { csl_bridge_plutus_map_values_add(pointer, data.pointer, $0) }
    }
    
    public func len() throws -> UInt64 {
        let length: Int64 = try CSL.call { csl_bridge_plutus_map_values_len(pointer, $0, $1) }
        return UInt64(length)
    }
    
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
    
    public static func plutusV1() throws -> Language {
        let ptr = try CSL.callRPtr { csl_bridge_language_new_plutus_v1($0, $1) }
        return Language(pointer: ptr)
    }
    
    public static func plutusV2() throws -> Language {
        let ptr = try CSL.callRPtr { csl_bridge_language_new_plutus_v2($0, $1) }
        return Language(pointer: ptr)
    }
    
    public static func plutusV3() throws -> Language {
        let ptr = try CSL.callRPtr { csl_bridge_language_new_plutus_v3($0, $1) }
        return Language(pointer: ptr)
    }
    
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
    
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_cost_model_new($0, $1) }
    }
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
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
    
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_costmdls_new($0, $1) }
    }
    
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

    public enum Tag: UInt32 {
        case spend = 0
        case mint = 1
        case certificate = 2
        case reward = 3
        case voting = 4
        case proposing = 5
    }

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

    public init(script: PlutusScript, datum: PlutusData, redeemer: Redeemer) throws {
        self.pointer = try CSL.callRPtr { csl_bridge_plutus_witness_new(script.pointer, datum.pointer, redeemer.pointer, $0, $1) }
    }

    public init(script: PlutusScript, redeemer: Redeemer) throws {
        self.pointer = try CSL.callRPtr { csl_bridge_plutus_witness_new_without_datum(script.pointer, redeemer.pointer, $0, $1) }
    }
    
    public static func newWithRef(script: PlutusScriptSource, datum: DatumSource, redeemer: Redeemer) throws -> PlutusWitness {
        let ptr = try CSL.callRPtr { csl_bridge_plutus_witness_new_with_ref(script.pointer, datum.pointer, redeemer.pointer, $0, $1) }
        return PlutusWitness(pointer: ptr)
    }
    
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

    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_redeemers_new($0, $1) }
    }

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

    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_plutus_witnesses_new($0, $1) }
    }

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
    
    public init(datum: PlutusData) throws {
        self.pointer = try CSL.callRPtr { csl_bridge_datum_source_new(datum.pointer, $0, $1) }
    }
    
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
    
    public init(script: PlutusScript) throws {
        self.pointer = try CSL.callRPtr { csl_bridge_plutus_script_source_new(script.pointer, $0, $1) }
    }
    
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
