//
//  AssetTests.swift
//  Cardano
//

import XCTest
@testable import Cardano

final class AssetTests: XCTestCase {
    /// Tests inserting assets into a single policy collection.
    /// In Cardano, assets are grouped by Policy ID. This test verifies that we can
    /// add multiple asset names and amounts to a specific policy's asset set.
    func testAssetsInsert() throws {
        let assets = try Assets()
        try assets.add(assetName: "Test", amount: 3)
        try assets.add(assetName: "Test", amount: 10) // Overwrite or add depending on CSL logic (usually add in Value, overwrite in Assets map)
        try assets.add(assetName: "Test2", amount: 1)
        
        XCTAssertEqual(try assets.len(), 2)
    }
    
    /// Tests the creation of a MultiAsset map.
    /// A MultiAsset object maps Policy IDs to their respective Asset collections.
    /// This is the standard way Cardano represents bundles of different native tokens.
    func testMultiAssetCreation() throws {
        let assets = try Assets()
        try assets.add(assetName: "Token1", amount: 500)
        
        let multiAsset = try MultiAsset()
        try multiAsset.insert(policyId: "1f7a58a1aa1e6b047a42109ade331ce26c9c2cce027d043ff264fb1f", assets: assets)
    }
    
    /// Tests merging MultiAsset into a Value.
    /// A Value represents the total bundle of ADA (coin) and native assets in a UTXO.
    func testValueWithMultiAsset() throws {
        let ma = try MultiAsset()
        let val = Value(coin: 100, multiAsset: ma)
        let ptr = try val.toPointer()
        XCTAssertNotNil(ptr)
    }

    /// Tests additional AssetName operations.
    /// AssetNames are represented as raw bytes on-chain but are often treated as UTF-8 strings.
    func testAssetNameExtra() throws {
        let name = try AssetName(name: "test".data(using: .utf8)!)
        let bytes = try name.toBytes()
        XCTAssertFalse(bytes.isEmpty)
    }
}
