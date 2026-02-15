//
//  AssetTests.swift
//  Cardano
//

import XCTest
@testable import Cardano

final class AssetTests: XCTestCase {
    func testAssetsInsert() throws {
        let assets = try Assets()
        try assets.add(assetName: "Test", amount: 3)
        try assets.add(assetName: "Test", amount: 10) // Overwrite or add depending on CSL logic (usually add in Value, overwrite in Assets map)
        try assets.add(assetName: "Test2", amount: 1)
        
        XCTAssertEqual(try assets.len(), 2)
    }
    
    func testMultiAssetCreation() throws {
        let assets = try Assets()
        try assets.add(assetName: "Token1", amount: 500)
        
        let multiAsset = try MultiAsset()
        try multiAsset.insert(policyId: "1f7a58a1aa1e6b047a42109ade331ce26c9c2cce027d043ff264fb1f", assets: assets)
    }
}
