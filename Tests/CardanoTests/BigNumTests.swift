//
//  BigNumTests.swift
//  Cardano
//

import XCTest
@testable import Cardano

final class BigNumTests: XCTestCase {
    /// Verifies standard arithmetic operations for BigNum.
    /// In Cardano, currency values (Lovelace) and script execution units can exceed 
    /// the capacity of standard 64-bit integers. BigNum provides the necessary precision 
    /// for these computations while preventing overflow through checked arithmetic.
    func testBigNumArithmetic() throws {
        let bn1 = try BigNum(string: "12345678901234")
        let bn2 = try BigNum(string: "1000000000000")
        
        // Addition
        let sum = try bn1.checkedAdd(bn2)
        XCTAssertEqual(try sum.toString(), "13345678901234")
        
        // Subtraction
        let diff = try bn1.checkedSub(bn2)
        XCTAssertEqual(try diff.toString(), "11345678901234")
        
        // Multiplication
        let prod = try bn2.checkedMul(try BigNum(string: "2"))
        XCTAssertEqual(try prod.toString(), "2000000000000")
        
        // Division
        let div = try prod.divFloor(bn2)
        XCTAssertEqual(try div.toString(), "2")
    }
    
    /// Tests Hex conversion and zero-value checks for BigNum.
    /// Serialization to Hex is required for CBOR encoding of transaction bodies, 
    /// while zero checks are essential for validating transaction balances and asset amounts.
    func testBigNumConversions() throws {
        let bn = try BigNum(string: "123456789")
        let hex = try bn.toHex()
        XCTAssertFalse(hex.isEmpty)
        
        XCTAssertTrue(try BigNum.zero().isZero())
        XCTAssertFalse(try BigNum.one().isZero())
    }
    
    /// Verifies comparison logic between BigNum instances.
    /// Precise comparison is critical for ensuring that transaction inputs are sufficient 
    /// to cover outputs and fees, and for enforcing minimum ADA requirements in UTXOs.
    func testBigNumComparison() throws {
        let bn1 = try BigNum(string: "100")
        let bn2 = try BigNum(string: "200")
        
        XCTAssertTrue(try bn1.lessThan(bn2))
        XCTAssertFalse(try bn2.lessThan(bn1))
        
        XCTAssertEqual(try bn1.compare(to: bn2), -1)
        XCTAssertEqual(try bn2.compare(to: bn1), 1)
        XCTAssertEqual(try bn1.compare(to: bn1), 0)
    }
}
