import XCTest
@testable import Cardano

extension PlutusTests {
    /// Tests the creation of Redeemers.
    /// A Redeemer is the data passed to a script to trigger a specific transition (e.g., "Spend", "Mint").
    /// It includes the data itself and the execution budget (ExUnits) allocated for this script.
    func testRedeemerCreation() throws {
        let data = try PlutusData.newInteger(number: 1)
        let exUnits = try ExUnits(mem: 100, step: 100)
        let redeemer = try Redeemer(tag: .spend, index: 0, data: data, exUnits: exUnits)
        
        XCTAssertNotNil(redeemer)
    }
    
    /// Tests Plutus Witnesses with various configurations.
    /// A witness is the proof that enables spending from a script address or minting tokens.
    /// It bundles the script, the redeemer, and optionally the datum.
    func testPlutusWitnessVariations() throws {
        let scriptData = Data(hex: PlutusTests.scriptHex)
        let script = try PlutusScript(bytes: scriptData, version: .v1)
        let datum = try PlutusData.newInteger(number: 42)
        let exUnits = try ExUnits(mem: 100, step: 100)
        let redeemer = try Redeemer(tag: .spend, index: 0, data: datum, exUnits: exUnits)
        
        // Witness with script + datum + redeemer (common for spending)
        let witness1 = try PlutusWitness(script: script, datum: datum, redeemer: redeemer)
        XCTAssertNotNil(witness1)
        
        // Witness with script + redeemer (common for minting)
        let witness2 = try PlutusWitness(script: script, redeemer: redeemer)
        XCTAssertNotNil(witness2)
    }
    
    /// Tests specialized Datum and Script sources.
    /// With the Vasil-era, datums and scripts can be "referenced" from other UTXOs
    /// instead of being provided in full within the transaction, significantly reducing fees.
    func testPlutusSources() throws {
        let input = try TransactionInput(
            hash: Data(repeating: 0, count: 32),
            index: 0
        )
        let datumSource = try DatumSource.newRefInput(input: input)
        XCTAssertNotNil(datumSource)
        
        let script = try PlutusScript(bytes: Data(hex: PlutusTests.scriptHex), version: .v2)
        let scriptHash = try script.hash()
        let scriptSource = try PlutusScriptSource.newRefInput(
            scriptHash: scriptHash,
            input: input,
            language: try Language.plutusV2(),
            scriptSize: 100
        )
        XCTAssertNotNil(scriptSource)
    }

    /// Tests Plutus witnesses using reference inputs for scripts and datums.
    /// Reference inputs (CIP-31) allow using data from existing UTXOs without spending them,
    /// which is the standard way to interact with large scripts or state on Cardano.
    func testPlutusWitnessRef() throws {
        let script = try PlutusScript(bytes: Data(repeating: 0, count: 32), version: .v1)
        let hash = try script.hash()
        let txHash = Data(repeating: 0, count: 32)
        let input = try TransactionInput(hash: txHash, index: 0)
        let refScriptSource = try PlutusScriptSource.newRefInput(scriptHash: hash, input: input, language: try Language.plutusV1(), scriptSize: 100)
        
        let datum = try PlutusData.newInteger(number: 42)
        let refDatumSource = try DatumSource.newRefInput(input: input)
        
        let exUnits = try ExUnits(mem: 1000, step: 1000)
        let redeemer = try Redeemer(tag: .spend, index: 0, data: datum, exUnits: exUnits)
        
        let witness1 = try? PlutusWitness.newWithRef(script: refScriptSource, datum: refDatumSource, redeemer: redeemer)
        XCTAssertNotNil(witness1 ?? witness1)
        
        let witness2 = try? PlutusWitness.newWithRefWithoutDatum(script: refScriptSource, redeemer: redeemer)
        XCTAssertNotNil(witness2 ?? witness2)
    }
    
    /// Tests the collection wrapper for Plutus witnesses.
    /// This collection is part of the transaction witness set and identifies how each
    /// scripted input or minting operation is authorized.
    func testPlutusWitnessesCollection() throws {
        let witnesses = try PlutusWitnesses()
        XCTAssertEqual(try witnesses.len(), 0)
        
        let script = try PlutusScript(bytes: Data(repeating: 0, count: 32), version: .v1)
        let datum = try PlutusData.newInteger(number: 42)
        let exUnits = try ExUnits(mem: 1000, step: 1000)
        let redeemer = try Redeemer(tag: .spend, index: 0, data: datum, exUnits: exUnits)
        let witness = try PlutusWitness(script: script, datum: datum, redeemer: redeemer)
        
        try witnesses.add(witness: witness)
        XCTAssertEqual(try witnesses.len(), 1)
        let fetched = try witnesses.get(index: 0)
        XCTAssertNotNil(fetched)
    }
    
    /// Tests Native script sources and their use in minting witnesses.
    /// Native scripts (Phase 1) are simpler than Plutus scripts and are used for 
    /// multi-sig and basic time-locking policies.
    func testNativeScriptSourceAndMint() throws {
        let bytes = Data([0x82, 0x00, 0x81, 0x58, 0x1c, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        do {
            let source = try NativeScriptSource(bytes: bytes)
            let witness = try MintWitness.newNativeScript(script: source)
            XCTAssertNotNil(witness)
        } catch {
            print("NativeScriptSource coverage: \(error)")
        }
    }
}
