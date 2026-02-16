//
//  MetadataTests.swift
//  Cardano
//

import XCTest
@testable import Cardano

final class MetadataTests: XCTestCase {
    /// Verifies building and retrieving general transaction metadata.
    /// Transaction metadata (label 0-65535) allows developers to attach arbitrary 
    /// information to Cardano transactions. This test ensures that text-based metadata 
    /// can be inserted and retrieved correctly, essential for basic on-chain messaging.
    func testGeneralMetadata() throws {
        let metadata = try Metadata()
        let label = try BigNum(string: "1")
        let value = try Metadatum.newText("Hello Cardano")
        
        try metadata.insert(label: label, value: value)
        XCTAssertEqual(try metadata.count(), 1)
        
        let retrieved = try metadata.get(label: label)
        XCTAssertEqual(try retrieved?.asText(), "Hello Cardano")
    }
    
    /// Tests the nesting of Metadata maps within a Metadatum.
    /// Many Cardano standards (like CIP-25 NFT metadata or CIP-20 message metadata) 
    /// use complex nested map structures. This test validates the ability to build 
    /// multi-level metadata trees for these use cases.
    func testMetadataMap() throws {
        let map = try MetadataMap()
        try map.insert(key: "name", value: try Metadatum.newText("KXP SDK"))
        try map.insert(key: "version", value: try Metadatum.newText("1.0.0"))
        
        XCTAssertEqual(try map.count(), 2)
        XCTAssertEqual(try map.get(key: "name")?.asText(), "KXP SDK")
        
        let metadata = try Metadata()
        try metadata.insert(label: try BigNum(string: "674"), value: try Metadatum.newMap(map))
        XCTAssertEqual(try metadata.count(), 1)
    }
    
    /// Verifies the creation of AuxiliaryData from Metadata.
    /// In a transaction, metadata is wrapped in AuxiliaryData. This test ensures 
    /// the full serialization path (Metadata -> AuxiliaryData -> CBOR Hex) 
    /// works correctly for inclusion in transaction builders.
    func testAuxiliaryData() throws {
        let metadata = try Metadata()
        try metadata.insert(label: try BigNum(string: "1"), value: try Metadatum.newText("KXP"))
        
        let auxData = try AuxiliaryData()
        try auxData.setMetadata(metadata)
        
        XCTAssertFalse(try auxData.toHex().isEmpty)
    }
}
