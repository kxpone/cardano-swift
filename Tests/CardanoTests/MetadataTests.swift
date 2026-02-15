//
//  MetadataTests.swift
//  Cardano
//

import XCTest
@testable import Cardano

final class MetadataTests: XCTestCase {
    func testGeneralMetadata() throws {
        let metadata = try Metadata()
        let label = try BigNum(string: "1")
        let value = try Metadatum.newText("Hello Cardano")
        
        try metadata.insert(label: label, value: value)
        XCTAssertEqual(try metadata.count(), 1)
        
        let retrieved = try metadata.get(label: label)
        XCTAssertEqual(try retrieved?.asText(), "Hello Cardano")
    }
    
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
    
    func testAuxiliaryData() throws {
        let metadata = try Metadata()
        try metadata.insert(label: try BigNum(string: "1"), value: try Metadatum.newText("KXP"))
        
        let auxData = try AuxiliaryData()
        try auxData.setMetadata(metadata)
        
        XCTAssertFalse(try auxData.toHex().isEmpty)
    }
}
