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
///
/// ### Example
/// ```swift
/// let tenAda = try BigNum(string: "10000000")
/// let sum = try tenAda.checkedAdd(BigNum(string: "5000000"))
/// ```
public class BigNum {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
    
    /// Initializes a BigNum from a decimal string representation.
    /// - Parameter string: A decimal string (e.g., "1000000").
    /// - Throws: CardanoError if the string is not a valid unsigned integer.
    public init(string: String) throws {
        self.pointer = try CSL.callRPtr { csl_bridge_big_num_from_str(string, $0, $1) }
    }
    
    /// Creates a BigNum with value zero.
    /// - Returns: A BigNum with value 0.
    public static func zero() throws -> BigNum {
        return try BigNum(pointer: CSL.callRPtr { csl_bridge_big_num_zero($0, $1) })
    }
    
    /// Creates a BigNum with value one.
    /// - Returns: A BigNum with value 1.
    public static func one() throws -> BigNum {
        return try BigNum(pointer: CSL.callRPtr { csl_bridge_big_num_one($0, $1) })
    }
    
    /// Creates a BigNum with the maximum possible value.
    /// - Returns: A BigNum with the maximum supported value.
    public static func max() throws -> BigNum {
        return try BigNum(pointer: CSL.callRPtr { csl_bridge_big_num_max_value($0, $1) })
    }
    
    /// Converts the BigNum to a decimal string representation.
    /// - Returns: A decimal string representation of this number.
    /// - Throws: CardanoError if conversion fails.
    public func toString() throws -> String {
        return try CSL.getString { csl_bridge_big_num_to_str(pointer, $0, $1) }
    }
    
    /// Converts the BigNum to a hexadecimal string representation.
    /// - Returns: A hexadecimal string representation of this number.
    /// - Throws: CardanoError if conversion fails.
    public func toHex() throws -> String {
        return try CSL.getString { csl_bridge_big_num_to_hex(pointer, $0, $1) }
    }
    
    /// Adds another BigNum to this one, checking for overflow.
    /// - Parameter other: The BigNum to add.
    /// - Returns: A new BigNum with the sum.
    /// - Throws: CardanoError if the result overflows.
    public func checkedAdd(_ other: BigNum) throws -> BigNum {
        return try BigNum(pointer: CSL.callRPtr { csl_bridge_big_num_checked_add(self.pointer, other.pointer, $0, $1) })
    }
    
    /// Subtracts another BigNum from this one, checking for underflow.
    /// - Parameter other: The BigNum to subtract.
    /// - Returns: A new BigNum with the difference.
    /// - Throws: CardanoError if the result underflows.
    public func checkedSub(_ other: BigNum) throws -> BigNum {
        return try BigNum(pointer: CSL.callRPtr { csl_bridge_big_num_checked_sub(self.pointer, other.pointer, $0, $1) })
    }
    
    /// Multiplies this BigNum by another, checking for overflow.
    /// - Parameter other: The BigNum to multiply by.
    /// - Returns: A new BigNum with the product.
    /// - Throws: CardanoError if the result overflows.
    public func checkedMul(_ other: BigNum) throws -> BigNum {
        return try BigNum(pointer: CSL.callRPtr { csl_bridge_big_num_checked_mul(self.pointer, other.pointer, $0, $1) })
    }
    
    /// Divides this BigNum by another, rounding down (floor division).
    /// - Parameter other: The BigNum divisor.
    /// - Returns: A new BigNum with the quotient.
    /// - Throws: CardanoError if dividing by zero.
    public func divFloor(_ other: BigNum) throws -> BigNum {
        return try BigNum(pointer: CSL.callRPtr { csl_bridge_big_num_div_floor(self.pointer, other.pointer, $0, $1) })
    }
    
    /// Compares this BigNum with another.
    /// - Parameter to: The BigNum to compare with.
    /// - Returns: -1 if less than, 0 if equal, 1 if greater than.
    /// - Throws: CardanoError if comparison fails.
    public func compare(to other: BigNum) throws -> Int64 {
        return try CSL.call { csl_bridge_big_num_compare(self.pointer, other.pointer, $0, $1) }
    }
    
    /// Checks if this BigNum is less than another.
    /// - Parameter other: The BigNum to compare with.
    /// - Returns: true if less than, false otherwise.
    /// - Throws: CardanoError if comparison fails.
    public func lessThan(_ other: BigNum) throws -> Bool {
        return try CSL.call { csl_bridge_big_num_less_than(self.pointer, other.pointer, $0, $1) }
    }
    
    /// Checks if this BigNum equals zero.
    /// - Returns: true if zero, false otherwise.
    /// - Throws: CardanoError if check fails.
    public func isZero() throws -> Bool {
        return try CSL.call { csl_bridge_big_num_is_zero(self.pointer, $0, $1) }
    }
    
    // MARK: - Priority 3: Async Batch Operations
    
    /// Asynchronously sums multiple BigNum values in parallel for better performance
    /// - Parameter numbers: Array of BigNum values to sum
    /// - Returns: The sum of all numbers
    public static func sum(numbers: [BigNum]) async throws -> BigNum {
        guard !numbers.isEmpty else {
            return try BigNum.zero()
        }
        guard numbers.count > 1 else {
            return numbers[0]
        }
        
        return try await withThrowingTaskGroup(
            of: BigNum.self,
            returning: BigNum.self
        ) { group in
            // Split into smaller chunks for parallel processing
            let chunkSize = Swift.max(2, numbers.count / 4)
            var chunks: [[BigNum]] = []
            for i in stride(from: 0, to: numbers.count, by: chunkSize) {
                let end = min(i + chunkSize, numbers.count)
                chunks.append(Array(numbers[i..<end]))
            }
            
            // Process each chunk in parallel
            for chunk in chunks {
                group.addTask {
                    return try chunk.reduce(try BigNum.zero()) { acc, num in
                        return try acc.checkedAdd(num)
                    }
                }
            }
            
            // Combine results
            var results = [BigNum]()
            for try await result in group {
                results.append(result)
            }
            
            return try results.reduce(try BigNum.zero()) { acc, num in
                return try acc.checkedAdd(num)
            }
        }
    }
    
    /// Asynchronously compares multiple BigNum values to a reference value
    /// - Parameter values: Array of BigNum values to compare
    /// - Parameter to: Reference value to compare against
    /// - Returns: Array of comparison results (-1, 0, 1)
    public static func compare(values: [BigNum], to reference: BigNum) async throws -> [Int64] {
        return try await withThrowingTaskGroup(
            of: (Int, Int64).self,
            returning: [Int64].self
        ) { group in
            for (index, value) in values.enumerated() {
                group.addTask {
                    let cmp = try value.compare(to: reference)
                    return (index, cmp)
                }
            }
            
            var results = Array(repeating: Int64(0), count: values.count)
            for try await (index, comparison) in group {
                results[index] = comparison
            }
            return results
        }
    }
}

/// A wrapper for the Cardano serialization library's BigInt type (arbitrary precision signed integer).
public class BigInt {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
    
    /// Initializes a BigInt from a decimal string representation.
    /// - Parameter string: A decimal string (e.g., "-1000000" or "2000000").
    /// - Throws: CardanoError if the string is not a valid integer.
    public init(string: String) throws {
        self.pointer = try CSL.callRPtr { csl_bridge_big_int_from_str(string, $0, $1) }
    }
    
    /// Converts the BigInt to a decimal string representation.
    /// - Returns: A decimal string representation of this number.
    /// - Throws: CardanoError if conversion fails.
    public func toString() throws -> String {
        return try CSL.getString { csl_bridge_big_int_to_str(pointer, $0, $1) }
    }
}
