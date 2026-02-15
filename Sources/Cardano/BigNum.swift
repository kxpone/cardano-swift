//
//  BigNum.swift
//  Cardano
//
//  Created by hellc.
//  Copyright © 2020-2026 KXP. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import CCardano

/// A wrapper for the Cardano serialization library's BigNum type (unsigned 64-bit integer).
public class BigNum {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
    
    public init(string: String) throws {
        self.pointer = try CSL.callRPtr { csl_bridge_big_num_from_str(string, $0, $1) }
    }
    
    public static func zero() throws -> BigNum {
        return try BigNum(pointer: CSL.callRPtr { csl_bridge_big_num_zero($0, $1) })
    }
    
    public static func one() throws -> BigNum {
        return try BigNum(pointer: CSL.callRPtr { csl_bridge_big_num_one($0, $1) })
    }
    
    public static func max() throws -> BigNum {
        return try BigNum(pointer: CSL.callRPtr { csl_bridge_big_num_max_value($0, $1) })
    }
    
    public func toString() throws -> String {
        return try CSL.getString { csl_bridge_big_num_to_str(pointer, $0, $1) }
    }
    
    public func toHex() throws -> String {
        return try CSL.getString { csl_bridge_big_num_to_hex(pointer, $0, $1) }
    }
    
    public func checkedAdd(_ other: BigNum) throws -> BigNum {
        return try BigNum(pointer: CSL.callRPtr { csl_bridge_big_num_checked_add(self.pointer, other.pointer, $0, $1) })
    }
    
    public func checkedSub(_ other: BigNum) throws -> BigNum {
        return try BigNum(pointer: CSL.callRPtr { csl_bridge_big_num_checked_sub(self.pointer, other.pointer, $0, $1) })
    }
    
    public func checkedMul(_ other: BigNum) throws -> BigNum {
        return try BigNum(pointer: CSL.callRPtr { csl_bridge_big_num_checked_mul(self.pointer, other.pointer, $0, $1) })
    }
    
    public func divFloor(_ other: BigNum) throws -> BigNum {
        return try BigNum(pointer: CSL.callRPtr { csl_bridge_big_num_div_floor(self.pointer, other.pointer, $0, $1) })
    }
    
    public func compare(to other: BigNum) throws -> Int64 {
        return try CSL.call { csl_bridge_big_num_compare(self.pointer, other.pointer, $0, $1) }
    }
    
    public func lessThan(_ other: BigNum) throws -> Bool {
        return try CSL.call { csl_bridge_big_num_less_than(self.pointer, other.pointer, $0, $1) }
    }
    
    public func isZero() throws -> Bool {
        return try CSL.call { csl_bridge_big_num_is_zero(self.pointer, $0, $1) }
    }
}
