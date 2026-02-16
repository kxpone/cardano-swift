import XCTest
@testable import Cardano

extension PlutusTests {
    /// Tests Plutus support starting from the Alonzo-era (V1).
    /// Plutus V1 introduced on-chain smart contracts. This test verifies script hashing
    /// and basic language version reporting.
    func testPlutusScriptV1() throws {
        let scriptData = Data(hex: PlutusTests.scriptHex)
        let v1 = try PlutusScript(bytes: scriptData, version: .v1)
        
        XCTAssertEqual(v1.version, .v1)
        XCTAssertEqual(try v1.languageVersion().kind(), 0) // V1
        XCTAssertNotNil(try v1.hash())
    }
    
    /// Tests Plutus V2 support introduced in the Vasil-era.
    /// V2 scripts are more efficient and support reference inputs and inline datums.
    func testPlutusScriptV2() throws {
        let scriptData = Data(hex: "4e4d010000332222200512001200601511")
        let v2 = try PlutusScript(bytes: scriptData, version: .v2)
        XCTAssertEqual(v2.version, .v2)
    }
    
    /// Tests Plutus V3 support introduced in the Chang-era (Conway).
    /// V3 introduces new primitives for governance and advanced cryptography (BLS curves).
    func testPlutusScriptV3() throws {
        let scriptData = Data(hex: "4e4d010000332222200512001200601511")
        let v3 = try PlutusScript(bytes: scriptData, version: .v3)
        XCTAssertEqual(v3.version, .v3)
    }
    
    /// Verifies script hashing, both individual and batch.
    /// In Cardano, script addresses are derived from the hash of the script's CBOR bytes.
    /// Correct hashing is crucial for sending funds to secondary validator addresses.
    func testPlutusScriptHashing() async throws {
        let scriptData = Data(hex: PlutusTests.scriptHex)
        let script = try PlutusScript(bytes: scriptData, version: .v1)
        
        let h1 = try script.hash()
        let hashes = try await PlutusScript.hash(scripts: [script])
        
        XCTAssertEqual(hashes.count, 1)
        XCTAssertEqual(try hashes[0].toHex(), try h1.toHex())
    }

    /// Tests the collection wrapper for Plutus scripts.
    /// Collections are used to bundle multiple scripts together, such as when submitting
    /// a transaction that involves multiple validators or minting policies.
    func testPlutusScriptsCollection() throws {
        let scripts = try PlutusScripts()
        let scriptHex = "4d01000033222220051200120011"
        let script = try PlutusScript(bytes: Data(hex: scriptHex), version: .v1)
        try scripts.add(script: script)
    }
    
    /// Tests Execution Unit Prices (ExUnitPrices).
    /// Every Plutus script execution costs "ExUnits" (Memory and CPU Steps). 
    /// These are priced in ADA and must be correctly calculated to prevent transaction rejection
    /// by the network node's Mempool.
    func testUnitIntervalAndExUnitPrices() throws {
        let memPrice = try UnitInterval(numerator: 577, denominator: 10000)
        let stepPrice = try UnitInterval(numerator: 721, denominator: 10000000)
        
        let exUnitPrices = try ExUnitPrices(memPrice: memPrice, stepPrice: stepPrice)
        XCTAssertNotNil(exUnitPrices)
    }
}
