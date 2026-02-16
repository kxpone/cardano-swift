import XCTest
import Cardano

extension AssetTests {
    /// Verifies initialization and basic state management for Asset collections.
    /// Asset collections start empty and are populated as tokens are added. This
    /// test ensures the underlying native wrapper initializes these collections correctly.
    func testAssetsExtra() throws {
        let assets = try Assets()
        XCTAssertEqual(try assets.len(), 0)
        
        let multiasset = try MultiAsset()
        XCTAssertEqual(try multiasset.len(), 0)
    }
}
