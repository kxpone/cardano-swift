import XCTest
import Cardano

extension AssetTests {
    func testAssetsExtra() throws {
        let assets = try Assets()
        XCTAssertEqual(try assets.len(), 0)
        
        let multiasset = try MultiAsset()
        XCTAssertEqual(try multiasset.len(), 0)
    }
}
